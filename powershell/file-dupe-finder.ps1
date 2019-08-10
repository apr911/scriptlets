#requires -version 2
<#
.SYNOPSIS
  Simple File Dupe Finder
.DESCRIPTION
  <Brief description of script>
.INPUTS
  None
.OUTPUTS
  HashTable Variable Containing Duplicate File Information.
  Variables named Hashes0, Hashes1...Hashes9
  Note: Hashes0 contains the original/first found instance of the file hash.
  Deleting all files found in the output variables will delete the original as well.  
.NOTES
 Title:        Simple File Dupe Finder
 Version:      1.0

 File:         file-dupe-finder.ps1
 Author:       Tony Romero
 Email:        tony.romero@apr911.net
 Date Created: 20190809

 Purpose: Simple directory/file deduper, stored as hashes in dictionary
 Usage: Execute script in powershell window set to directory to search/dedupe.
 

 Addtional Required Source Files: None
 Additional Reference Files: None
 
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
$OrigHashes=@{}
$Hashes0=@{}
$Hashes1=@{}
$Hashes2=@{}
$Hashes3=@{}
$Hashes4=@{}
$Hashes5=@{}
$Hashes6=@{}
$Hashes7=@{}
$Hashes8=@{}
$Hashes9=@{}
$CurCount=0
$Progress=0

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function DupeCheck {
    param( $Hash, $File )
    if ($OrigHashes.containsKey("$Hash")) {
        if (! $Hashes0.containsKey("$Hash") ) {
            $OrigFile=$OrigHashes["$Hash"]
            $Hashes0.add("$Hash","$OrigFile")
            Write-Host -foregroundcolor Yellow "$OrigFile - Original Stored in HashTable0"
        }
        for ($i=1; $i -le 9; $i++) {
            $HashTable=Get-Variable -Name "Hashes$i" -valueonly
            if ($HashTable.ContainsKey("$Hash")) {
                continue
            } else {
                $HashTable.add("$Hash","$File")
                Write-Host -foregroundcolor Yellow "$File - Dupe Stored in HashTable $i"
                return
            }
        }
        write-host -foregroundcolor Red "$File - Dupe Not Stored"
    } else {
        $OrigHashes.add("$Hash","$File")
        #write-host -foregroundcolor Green "$File - New File Hash Discovered"
    }
}

function DupeCount {
    param( $FileCount )
    $DupeCount=0
    for ($i=1; $i -le 9; $i++) {
        $HashTable=Get-Variable -Name "Hashes$i" -valueonly
        $DupeCount+=$HashTable.Count
    }
    $PercentDuped=[math]::Round(($DupeCount / $FileCount * 100 ),2)
    Write-Host -ForegroundColor Green "$DupeCount of $FileCount or $PercentDuped % of the files hashed are duplicates."
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

$TtlCount=(dir -file -recurse -force | measure).count

dir -file -force -recurse | %{
    $File=$_.FullName
    $CurCount++
    $Progress=[math]::Round(($CurCount / $TtlCount * 100 ),2)
    if ($CurCount%100 -eq 0 ) {
        DupeCount -FileCount $CurCount
    }
    Write-Progress -Activity "Hashing File" -Status "$Progress % Complete" -CurrentOperation "File $CurCount of $TtlCount - $File" -PercentComplete $Progress;
    $Hash=(get-filehash($File)).hash
    DupeCheck -Hash $Hash -File $File
}

