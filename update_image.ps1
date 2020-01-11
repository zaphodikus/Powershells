Param([parameter(mandatory=$false)][string]$password = (gc '_password.txt'), 
	  $ftpServer = (gc '_ftpserver.txt'),
	  $ftpSite = (gc "_ftpsite.txt"),
	  $siteFolder = (gc '_ftp_imagespath.txt'),
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
		# gc .\response.txt | write-verbose
		$results = & ftp.exe -s:response.txt 
		$results | write-verbose # add -verbose on commandline to get verbose trace
		if ($lastexitcode -ne 0) { throw "Error occured: $results" }
		$results | ?{$_ -like '530 Authentication failed, sorry'}| %{throw $_}
		$results | ?{$_ -like 'Connection closed by remote host'} | %{throw $_} # host did not like us for some reason 		
		$results
	}

# upload a new RSS now if one was specified
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
