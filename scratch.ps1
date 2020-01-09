
$links = ls \\hpnas\Disk0\Church\Sermons\fblinks | select name
$linkdates = $links | %{ [Datetime]($_.Name -split '\.')[0]}

$l = foreach ($emp3 in $(ls \\hpnas\Disk0\Church\Sermons\*.mp3)) { 
   try {$mp3date = [DateTime]($emp3.name -split '\.')[0] ; $postsMatched = @($linkDates | ?{ $_ -lt $mp3Date -and $_ -gt ($mp3Date - (New-timespan -days 7))})  ;
     if ($postsMatched.count -gt 0) { New-object -typename psobject -prop @{mp3=$emp3.name; lnk= $postsMatched[-1].ToString('yyyy-MM-dd') + '.lnk'}}
   } catch {}
 }

$fblinks = $l | %{ $o= new-object -typename psobject; add-member -inputobject $o -membertype NoteProperty -name 'file' -value $_.mp3; 
	gc (join-path '\\hpnas\Disk0\Church\Sermons\fblinks' $_.lnk)| %{ 
		if ($_ -like 'url=*') {
			add-member -inputobject $o -membertype noteProperty -Name 'url' -value (($_ -split '=')[1..9] -join '=')  
		} 
		if ($_ -like 'img=*') { 
			add-member -inputobject $o -membertype noteProperty -Name 'img' -value (($_ -split '=')[1..9] -join '=')} 
		} 
	$o
}

# example
# $fblinks | where file -eq '2019-07-07.mp3'