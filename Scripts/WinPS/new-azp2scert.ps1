
#cribbed and modified from https://github.com/eissko/PowershellTools/blob/master/createSelfSignedCertificate.ps1
<#PSScriptInfo
.VERSION .1
.AUTHOR Toby Scales
.COMPANYNAME Microsoft Corporation
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
 - None

.REQUIREDSCRIPTS
 - None

 .EXTERNALSCRIPTDEPENDENCIES
 - None

.RELEASENOTES

    Initial release.

#>
<#

.SYNOPSIS
    Do the boring certificate creation stuff for Azure Point-to-Site VPN Connections.
    Basically this: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site

.DESCRIPTION
    This script just creates:
    ## 1, self-signed Root CA certificate which is gonna be used as CA certificate for signing/issuing client certificates
    ## 2, the client certificate signed by Root CA 
    ## 3, output of Root CA certificate in BASE64 form which is form necessary for AZURE point-to-site vpn

.PARAMETER Company

Used to customize the name of the certificate.

.PARAMETER Project

Used to customize the name of the certificate.

.EXAMPLE
New-AzP2SCert.ps1 -Company "Contoso" -Project "SpecialOps"

#>

param (
    [string]$company = "Azure",
    [string]$project = "Connection"
)


function New-RootCA{
    param(
        [string]$SubjectNameRoot
    )
    #create selfsigned CA certificate which is gonna be used for issuing the clients certificates
    #Firstly stored in \My with public & private key
    $RootCA = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject $("CN="+$SubjectNameRoot) -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

    return $RootCA
}

Function Get-Cert {
    param(
        [string]$SubjectName
    )
    #if ROOT CA already exists, just get it
    #try to read it from your local cert store My
    
    $cert=get-childitem "Cert:\CurrentUser\My" | Where-Object {$_.Subject -eq "CN=$SubjectName"}
    return $cert
}

function Export-RootCA{
    param(
        [string]$rootCaFileName,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$RootCA,
        [string]$path="C:\cert\"

    )

    if(-not (Test-Path($path))){
        New-Item -Path $Path -ItemType Directory
    }
    set-location -path $Path
    
    #Export selfsigned ROOT CA and convert it using certutil to BASE64 format (required by azure)
    #export-certificate do not supports BASE64 output that's why certutil

    if(-not (test-path -Path  $(".\$RootCAFileName.cer"))){
        Export-Certificate -cert $RootCA -FilePath $(".\$RootCAFileName.cer") -type CERT
    }
    if (-not (test-path -Path  $(".\$RootCAFileName.base64.cer")) ){
        certutil -encode $(".\$RootCAFileName.cer") $(".\$RootCAFileName.base64.cer") | Out-Null
        }
     
    #output selfsigned CA certificate in a form BASE64 and remove unnecessary parts from it
    #and make it so ready for AZURE point-to-site configuration

    #Write-host "`n This is ROOT CA public key which needs to be copied to azure: `n" -ForegroundColor Green
    Set-Content -Path .\base64.txt -NoNewline -Value $($($($(get-content $(".\$RootCAFileName.base64.cer") -Raw) -replace "`r`n","") -replace "-----BEGIN CERTIFICATE-----","") -replace "-----END CERTIFICATE-----","")
return
}

function Import-RootCAtoRootStore { 
   param(
    [string]$path="c:\cert\",
    [string]$RootCAFileName
    )
    Set-Location -Path $($path)
    #import selfSigned CA certificate into windows ROOT store under CurrentUser scope in order to ensure system trust of issued client certificates
    Import-Certificate -FilePath $(".\$RootCAFileName.cer") -CertStoreLocation cert:\CurrentUser\Root
}
function New-ClientCert {
    param(
        [string]$SubjectNameClient,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$RootCA   
    )

    #create certificate signed by our new CA certificate created steps before
    New-SelfSignedCertificate -Type Custom -DnsName $SubjectNameClient -KeySpec Signature `
    -Subject $("CN="+$SubjectNameClient) -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Signer $RootCA -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
}

Set-StrictMode -Version 2.0

#variables
$SubjectNameRoot="AzureP2SVPN ROOT CA $Company $Project"
$SubjectNameClient="AzureP2SVPN $Company $Project"
$RootCAFileName="AzureP2SVPNRootCA"
$Path="c:\cert\"
$timestamp=get-date -Format yyyyMMddhhmmss


#if certificates with the same name already exists in that folder just rename them
if(test-path -Path $Path){
Get-ChildItem -Path  $(join-path -Path $Path -ChildPath "*") -Include *.cer -Exclude bkp_* | rename-item -NewName {"bkp_$timestamp"+"_"+$_.name }
}

#check if Root CA certificate with specified subject name is already present
$RootCA=Get-Cert -SubjectName $SubjectNameRoot | Select-Object -First 1

if (-not $RootCA){
    Write-Host "Root CA not present -> creating..."
    New-RootCA -SubjectNameRoot $SubjectNameRoot    
}

#check if Client certificate with specified subject name is already present
$ClientCert=Get-Cert -SubjectName $SubjectNameClient | Select-Object -First 1

if(-not $ClientCert){
    write-host "client Certificate not present -> creating" -ForegroundColor Green
    $RootCA=Get-Cert -SubjectName $SubjectNameRoot | Select-Object -First 1
    New-ClientCert -SubjectNameClient $SubjectNameClient -RootCA $RootCA
}

#in this step "Root CA" should exists
Export-RootCA -RootCaFileName $RootCAFileName -RootCA $RootCA -path $Path

#check if "Root CA" is also in windows store of Trusted Root CA
$RootCAinRootStore=Get-ChildItem -Path cert:\CurrentUser\Root | Where-Object{$_.Subject -eq "CN=$SubjectNameRoot"}
if(-not $RootCAinRootStore){
    
    if(-not (test-path -Path  $(".\$RootCAFileName.cer"))){
       Write-Error -Message "exported file of root CA not found. Something went wrong :)"
       Exit
    }

    #Import-RootCAtoRootStore -path $Path -RootCAFileName $RootCAFileName
}