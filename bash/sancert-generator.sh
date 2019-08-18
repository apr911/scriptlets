###############################################################################
# Title:        SAN Certificate CSR/Key Generator
# Version:      1.0
#
# File:         sancert-generator.sh
# Author:       Tony Romero
# Email:        tony.romero@apr911.net
# Date Created: 20140721
#
# Purpose: Prompt User for SAN Cert inputs and display generated CSR/Key pair
# Usage: 
# sancert-generator.sh
# 
#
# Addtional Required Source Files: None
# Additional Reference Files: None
# 
###############################################################################

#!/bin/bash

#Declare Default Certificate Values
country="US" ;
state="Pennsylvania" ;
city="West Chester" ; 
org="APR911 Consulting" ;
division="IT" ;

function cleanup() {
    #Function to remove sancert.csr, sancert.key and sancert.conf files if they exist.
    #Function is used at start to ensure clean environment and at end to leave no trace.

    rm -f sancert.csr
    rm -f sancert.key
    rm -f sancert.conf

}

function configGen() {
    #Function to gather user input and generate openSSL configuration file for SAN Certificate.

    echo "You are creating a SAN Cert CSR and Key." ;

    #Get Number of DNS Names required
    #Verify value is a number and greater than or equal to 2 and not empty, 0 or q. 
    #Break if all conditions met. Quit if value is empty, 0 or q.
    while true ; do 
        echo -n "How many Total Names are required? (Enter 0 to quit) [0]: " ; 
        read ans ;
        if [[ $ans = "q" ]] || [[ -z $ans ]] ; then
            echo "No Names Required. Exiting." ;
            exit 0
        elif ! [[ $ans =~ ^[0-9]+$ ]] ; then
            echo "Please enter an integer number." ;
        elif [[ $ans -eq "0" ]] ; then
            echo "No Names Required. Exiting."
            exit 0
        elif [[ $ans -lt "2" ]] ; then
            echo "SAN Certs require 2 or more total names. Please try again." ;
        else
            break ;
        fi ;
    done

    #Generate Basic Config file
    echo -e "[req]\r\ndistinguished_name = req_distinguished_name\r\nreq_extensions = v3_req\r\n" >> sancert.conf ;
    echo -e "[ v3_req ]\r\nsubjectAltName = @alt_names\r\n" >> sancert.conf ; 
    echo -e "[req_distinguished_name]\r\ncountryName = Country Name (2 letter code)\r\ncountryName_default = $country\r\nstateOrProvinceName = State or Province Name (full name)\r\nstateOrProvinceName_default = $state\r\nlocalityName = Locality Name (eg, city)\r\nlocalityName_default = $city\r\norganizationName = Organization Name (eg, company)\r\norganizationName_default = $org\r\norganizationalUnitName  = Organizational Unit Name (eg, section)\r\norganizationalUnitName_default  = $division\r\nemailAddress = Email Address\r\nemailAddress_max = 40" >> sancert.conf ; 


    #Get Domain Names and Append to Config File
    for (( AltNum=0 ; AltNum<$ans ; AltNum++ )) ; do
        if [[ $AltNum -eq "0" ]] ; then 
            echo -n "Enter Primary FQDN: " ; read AltName ; 
            echo -e "commonName = Common Name (eg, FQDN)\r\ncommonName_default = $AltName\r\ncommonName_max = 64\r\n\r\n[alt_names]" >> sancert.conf ;
        else 
            echo -n "Enter Alternate Name $AltNum: " ; read AltName ;
            echo "DNS.$AltNum = $AltName" >> sancert.conf ;
        fi ;
    done ;

}

function certGen() {
    #Function to determine key length and generate key and CSR.

    echo -n "Use 4096 bit key (no uses 2048 bit key)? (y/n) [y]: " ; 
    read ans ;
    if [[ $ans = "y" ]] || [[ $ans = "Y" ]] || [[ -z $ans ]] ; then
        echo "Generating CSR and Key with 4096 bit key length" ;
        openssl genrsa -out sancert.key 4096 ;
        openssl req -new -out sancert.csr -key sancert.key -config sancert.conf ;
    else 
        echo "Generating CSR and Key with 2048 bit key length" ;
        openssl genrsa -out sancert.key 2048 ;
        openssl req -new -out sancert.csr -key sancert.key -config sancert.conf ;
    fi
}

#Start with Clean Environment
cleanup ;
#Generate default configurations
configGen ;
#Generate Key and CSR.
certGen ;

#Write Key and CSR to Screen. Show Certificate Domains.
cat sancert.key ;
echo -e "\r\n" ;
cat sancert.csr ;
echo -e "\r\n" ;
openssl req -text -noout -in sancert.csr | grep -A 1 Subject ;

#Leave no trace
cleanup ;
