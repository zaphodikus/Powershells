$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$sendto = [environment]::getfolderpath("sendto")
if (-not (test-path (join-path $sendto 'add_diff.cmd'))) {
	# install the app shortcut now
@"
powershell "${scriptPath}\add-diff.ps1" %1
"@ | out-file (join-path $sendto 'add_diff.cmd')
	write-host "Installed a 'SendTo' link in ${sendto}"
	Read-host "Press any key to continue..."
}

$difftxt = join-path $scriptPath 'diff.txt'
if (test-path $difftxt) {
	write-host "Adding right file to diff ${$Args[0]}"
	write-host 	"$scriptPath\WinDiff.Exe" "$left" "$right"
	Start-sleep -s 2
	$left = get-content $difftxt
	Remove-item $difftxt
	$right = $Args[0]
	& "$scriptPath\WinDiff.Exe" "$left" "$right"
} else {
	$Args[0] | out-file $difftxt
	write-host "Adding left file to diff ${$Args[0]}"
	Start-sleep -s 2
}
