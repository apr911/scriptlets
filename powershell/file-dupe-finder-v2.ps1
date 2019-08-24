#requires -version 2
<#
.SYNOPSIS
  Simple File Dupe Finder
.DESCRIPTION
  <Brief description of script>
.PARAMETER all
  all is a boolean/switch parameter for deldupes. 
  default value is false
  Setting to true will delete all duplicates stored in hashes1 through hashes9.
.PARAMETER loop
  loop is an int parameter for deldupes
  default value is equal to table
  Use to set final hashes hashtable to delete files from.
.PARAMETER table
  table is an int parameter for deldupes.
  default value is 1
  Use to set start hashtable to delete files from.
  Use with parameter loop to set start and stop hashtable loop through and delete files from.
  WARNING: It is possible to set this value to 0 or less than 1 which may result in data loss.
.PARAMETER storeoriginals
  storeoriginals is a boolean/switch parameter for hashfiles
  default value is false
  Use to store non-duplicate hashes in the orighash hashtable. 
  NOTE: Duplicate hashes will still be stored in hashes0 through hashes9.
  Useful for prevent cross-contamination for comparing multiple directory trees to a single source directory tree
.INPUTS
  None
.OUTPUTS
  HashTable Variable Containing Duplicate File Information.
  Variable named orighash
  Variables named Hashes0, Hashes1...Hashes9
  Note: Hashes0 contains the original/first found instance of the file hash.
  Deleting all files found in the output variables will delete the original as well.  
.NOTES
 Title:        Simple File Dupe Finder
 Version:      2.0

 File:         file-dupe-finder-v2.ps1
 Author:       Tony Romero
 Email:        tony.romero@apr911.net
 Date Created: 20190824

 Purpose: Simple directory/file deduper, stored as hashes in dictionary
 Usage: Source file. Execute functions as necessary in directory to be hashed.
 

 Addtional Required Source Files: None
 Additional Reference Files: None
 
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function dircount {
    #Returns file count for directory and all subdirectories
    return (dir -file -recurse -force).count
}

function chkcnt {
    #Displays count of files found in each hashtable including OrigHash

    #display total stored hashes of original files
    $count=$orighash.count
    write-houst "orighash $count"

    #loop through all duplicate hashtables
    for ($i=0; $i -le 9 ; $i++) {
        $hashtable=get-variable -name "hashes$i" -valueonly
        $count=$hashtable.count
        write-host "hashes$i $count"
    }
}

function cleardupes {
    #Clear hashtables containg duplicate files. Keep all original files.
    #Useful where a single source directory tree is used to compare multiple sister trees.
    $global:hashes0=@{}
    $global:hashes1=@{}
    $global:hashes2=@{}
    $global:hashes3=@{}
    $global:hashes4=@{}
    $global:hashes5=@{}
    $global:hashes6=@{}
    $global:hashes7=@{}
    $global:hashes8=@{}
    $global:hashes9=@{}
}

function clearall {
    #Clear hashtables containing duplicate files. Clear hashtable contining original files.
    #Cleans environment for execution in new folder.
    cleardupes
    $global:orighash=@{}
}

function deldupes {

    param (
        [switch] $all=$false,
        [int] $loop=1,
        [int] $table=1
    )

    if ( $all -eq $true ) {
        #Delete all true, setting loop to max 9.
        $loop=9
    }

    if ( $table -gt $loop ) {
        #Table number exceeds loop number. 
        #Seting loop number equal to table number to execute delete on table.
        $loop=$table 
    }

    if ( $table -eq 0 ) {
        #Table number is 0.
        #Setting loop to 0 to protect file copies.
        $loop=0
        write-warning "Caution: Deleting original file of duplicated hash. This can result in lost data."
    }

    #Loop through tables deleting duplicated files
    for ($i=$table; $i -le $loop ; $i++) {
        $hashtable=get-variable -name "hashes$i" -valueonly
        $hahtable.getenumerator | % {
            $file=$_.value
            del $file
        }
    }
}

function dupstat {

    #Set initial values
    $origs=$global:orighash.count
    $dupes=$global:hashes0.count
    $dupecount=0
    $duperate=0
    $ttlcount=0
    $ttlcount+=$origs
    $pctdupe=0

    #Check that there is more than 0 dupes before wasting cycles looping through hashtables and math.
    if ( $dupes -gt 0 ) {

        #Loop through hashes1 through hashes9 tables, add counts of each to dupecount
        for ($i=1 ; $i -le 9 ; $i++) { 
            $hashtable=get-variable -name "hashes$i" -valueonly
            $dupecount+=$hashtable.count
        }

        #Calculate total hashed files, rounded percentage duped and rate of duplicates per file.
        $ttlcount+=$dupecount
        $pctdupe=[math]::round(($dupecount/$ttlcount*100),2)
        $duperate=[math]::round(($dupecount/$dupes),1)

    }

    #Display message with duplicate statistics.
    write-host -foregroundcolor green "$dupecount duplicates of $dupes duplicated files. Dupe rate is $duperate per file duplicated. Dupe density is $pctdupe % of $ttlcount files."

}
        

function hashfiles {

    param (
        [switch] $storeoriginals=$false
    )

    #Set values for progress meter
    $curfile=0
    $totalfiles=dircount

    #Search directory for files only including hidden files. Recurse directory tree.
    dir -file -force -recurse | % {
        #For each file found
        #
        #Update Progress
        $curfile++
        $percent=[math]::round(($curfile/$totalfiles*100),2) #Calculate Percent Rounded to 2
        $file=$_.FullName
        write-progress -Activity "Hashing" -Status "$percent % complete." -CurrentOperation "Hashing file $curfile of $totalfiles - $file"
        
        #Get File Hash and determine if hash already exists in orighash table
        $hash=((get-filehash($file)).hash)

        if ($orighash.containskey($hash)) {
            #Hash exists in orighash table. Obtain original file name from orighash table.
            $origfile=$orighash["$hash"]

            #Check if original file hash and name have been entered into hashes0 table. Add if not.
            if ( ! $global:hashes0.containskey($hash) ) {
                $global:hashes0.add("$hash","$origfile")
            }

            #Display original file info.
            write-host -foregroundcolor magenta "`r`nStored file duplicate #0 - $origfile"

            #Loop through hashes1 to hashes9 to determine table to store duplicate file in.
            for ($i=1 ; $i -le 9 ; $i++) {
                $hashtable=get-variable -name "hashes$i" -valueonly

                #If hash exists in this iteration of hashesx table, write message and continue loop.
                #Else, add hash to hashesx table, write message and break loop
                if ($hashtable.containskey($hash)) {
                    $dupefile=$hashtable["$hash"]
                    write-host -foregroundcolor red "Stored file duplicate #$i - $dupefile"
                    continue
                } else {
                    $hashtable.add("$hash","$file")
                    write-host -foregroundcolor yellow "Stored file duplicate #$i - $file"
                    break
                }
            }
        } else {
            #Hash does not exist in orighash. This is a newly found hash. 
            #if storing hashes, add to orighash table, else print hash not stored message 
            if ($storeoriginals -eq $true) {
                $orighash.add("$hash","$file")
            } else {
                write-host "Hash not stored for file: $file"
            }
        }

        #If currentfile is divisible by 100 or is the last file, display dupstat.
        if (($curfile % 100 ) -eq 0 -or $curfile -eq $totalfiles) {
            dupstat
        }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Initialize variables
clearall
