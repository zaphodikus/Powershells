<# 
.SYNOPSIS
	Queries FTP site and Builds a sermons-listing html file.
	Uploads this file and optionally uploads a new sermon recording mp3 file.
.DESCRIPTION
	Uses a temporary response file for all ftp exec calls.
	For tips on self signing this script if you need to edit it in any way
	http://www.hanselman.com/blog/SigningPowerShellScripts.aspx
	
	This script does a bit more than just upload the mp3 file to the church website, 
	and create full index list. It builds and uplaods 2 lists/indexes, index.html 
	is the last 6 files, while archive.html lists all files in the folder.
.PARAMETER password
	The $ftpSite is the username
.PARAMETER ftpServer
	Your hosting provider/your own ftp server name
.PARAMETER ftpSite
	Your website (may be the same the the ftp host)
.PARAMETER siteFolder
	Folder within the site that all the files must get coppied to and listed from
	Files are uplaoded into
	$ftpSite/$siteFolder/$uploadSermonFile
	index.html file 
.PARAMETER uploadSermonFile
	local filename, assumed to always be in the current working directory
.NOTES
    If your ftp host uses a username that is not your sitename, then you will 
    have to add a new parameter, called username, and replace code where $ftpsite is 
    used to login, to that new variable. For me, the user and ftpsite were the same.
#>
Param([parameter(mandatory=$true)][string]$password, 
	  $ftpServer ="ftp.yourwebhost.com",
	  $ftpSite = "yourdomainname.com",       # used as a username usually (and to generate hyperlinks)
	  $siteFolder = "ftpfoldername/Sermons", # this is the FTP root
	  [string]$uploadSermonFile = ""
	  )
$erroractionpreference ='stop'

	function ExecCommands($commands)
	{
		# create ftp responses input file
		remove-item .\response.txt -ea 0
		$commands | out-file .\response.txt -encoding ASCII -force
		$lastexitcode = 0
		Write-Host "Logging into FTP server, use -verbose to see FTP conversation"
		gc .\response.txt | write-verbose
		$results = & ftp.exe -s:response.txt 
		$results | write-verbose # add -verbose on commandline to get verbose trace
		if ($lastexitcode -ne 0) { throw "Error occured: $results" }
		$results | ?{$_ -like '530 Authentication failed, sorry'}| %{throw $_}
		$results
	}

# upload a new sermon now if one was specified
if (-not([string]::IsNullOrEmpty($uploadSermonFile)))
{
	$optionalUpload = (resolve-path $uploadSermonFile) |split-path -leaf
	#upload a file
	$uploadFile = @"
open $ftpServer
$ftpSite
$password
lcd $pwd
cd $siteFolder
binary
put $optionalUpload
bye
"@
	$results = ExecCommands $uploadFile
}
#ftp commands , just list all the files in the sermons folder
$responseFile = @"
open $ftpServer
$ftpSite
$password
lcd $pwd
cd $siteFolder
ls
bye
"@

$results = ExecCommands $responseFile
$fileList = $results | ?{$_ -like '*mp3'} | sort-object -descending
Write-host "Found $($fileList.count) mp3 files OK."
Write-Verbose "Recent remote .mp3 files:"
$recentListing = $fileList | select -first 6
$recentListing| write-verbose
Write-Verbose "Recent Local .mp3 files:"
ls *.mp3 | Sort-Object -Property name -descending| select -First 6 | write-verbose

	function Get-Dayname($filename, [bool]$year=$false) {
		if ($year) {$fmt="yyyy MMM dd"} else {$fmt = "M"} # use short date formatter for the last 6 sermons, long date for the archive
		try {
			([datetime][string]([regex]::matches($filename, "(.*)(.mp3)")).groups[1]).ToString($fmt)
		} catch { 
			$filename
		}
	}

# example URL to build = http://www.cottenhambaptist.org.uk/Sermons/2015-03-08.mp3
# last 6 sermons only
$folder = ($siteFolder -split '/')[1]
$text = ($recentListing | %{"<a href=`"http://www.$ftpSite/$folder/$_`">$(Get-Dayname $_ )</a>"}) -join "<BR>"
remove-item .\index.html -ea 0
"<html><body>$text</body></html>" | out-file .\index.html -encoding ASCII -force

# list of all sermons
$text = ($fileList | %{"<a href=`"http://www.$ftpSite/$folder/$_`">$(Get-Dayname $_ $true)</a>"}) -join "<BR>"
remove-item .\archive.html -ea 0
"<html><body>$text</body></html>" | out-file .\archive.html -encoding ASCII -force

# ftp commands to upload 2 files
$responseFile = @"
open $ftpServer
$ftpSite
$password
lcd $pwd
cd $siteFolder
binary
put index.html
put archive.html
bye
"@
$responseFile | out-file .\response.txt -encoding ASCII -force
$lastexitcode = 0
Write-Host "Logging into FTP server, use -verbose to see FTP conversation"
gc .\response.txt | write-verbose
$results = & ftp.exe -s:response.txt 
$results | write-verbose # add -verbose on commandline to get verbose trace
if ($lastexitcode -ne 0) { throw "Error occured: $results" }
write-host "Index Files uploaded OK"

# This is my signature block, I'm leaving it here just for show, 
# see doc comments above on how to self-sign a script.

# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1ZJwgp3TXa8EpZdWoh3kh29R
# 4g+gggI9MIICOTCCAaagAwIBAgIQEx5BjtX2NJJGkGwevOMYKzAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNTA2MTQxODI3MjBaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAypoc+1edcyi4
# owKLiVcm+N2zYKWPgW67ko1iQCvfyQAW5HE45BQd+GREg/kLKhKC/dhnjIHeR6+h
# /iBR0BialXOitbuHJymuyNp+RR2VU/wyhDZ8wiwIrk48zmU3aUMi6txnx0D9wkem
# ycWmVwx0ofwJgIkOPYKBobBBrtbGYnsCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQgZB3zB8GuoQbOyjLYioP+aEuMCwxKjAoBgNVBAMT
# IVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQFnl7ZWguL71GjWYz
# o8UUjjAJBgUrDgMCHQUAA4GBAHvg66h/y4j/ZqNX6eDSbqqmaweFYntOi4O63FDV
# JQ64f9TnhClpvWfvs7+igQfXxrVCKjlTl791C+eeOXBoPayBLV1B/OAwrOVYMYP9
# 5ajlehl3fHwgG7FuBAioEI05sOIvnp7Pq9d96nlV9+w4EhUSIK7mUnneSSn8KAzJ
# AyTAMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEBMeQY7V9jSSRpBsHrzjGCswCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FGHa//v3yhkhr7wBUlBWa/4zliU4MA0GCSqGSIb3DQEBAQUABIGAGLDuMFh1Q3xX
# n+QN/Gtw5fzOtEGdZzj5QxvHl4hNxJvBj7FMKGpc2zUzPE9YyKc42HJQMpvc6E53
# uqHm/S7vUzJO3kkfIK8KCjo45gn2DYLZtbNnu2b75VGTRS9H1RzDYaczalSKbWBK
# lc+o4V65V1jk9+Hj0LFm3jE9xhUi+QI=
# SIG # End signature block
