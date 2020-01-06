# a new season/podcast script
# sources : https://gallery.technet.microsoft.com/scriptcenter/Capturing-and-using-Meta-4f81b7da
#           https://www.petri.com/creating-custom-xml-net-powershell
#           https://gist.github.com/arebee/a7a77044c77443effaeddbe3730af4ad
$Erroractionpreference = 'Stop'

Function Get-FileMetaData
{
Param([parameter(Mandatory=$false)][string]$Folder = '\\hpnas\Disk0\Church\Sermons', 
      [parameter(Mandatory=$false)]$extension = ('.mp3'))

	$a = 0 
    $objShell = New-Object -ComObject Shell.Application 
    $objFolder = $objShell.namespace($Folder) 

	$files = $objFolder.items() | ?{"." + ($_.name -split '\.')[1] -in $extension}
    foreach ($File in $files) # objFolder.items()) 
    {  
      $FileMetaData = New-Object PSOBJECT 
      for ($a ; $a  -le 266; $a++) 
      {  
         if($objFolder.getDetailsOf($File, $a)) 
         { 
            $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                   $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash 
            $hash.clear()  
         } #end if 
      } #end for  
      $a=0 
      $FileMetaData 
    } #end foreach $file 
}

#$mp3Files = Get-FileMetaData
$url_base = 'http://www.cottenhambaptist.org.uk/Sermons/'
$url_home = 'http://www.cottenhambaptist.org.uk'
$path = "feed.rss"

[xml]$Doc = New-Object System.Xml.XmlDocument
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$Doc.AppendChild($dec) | out-null

function createRssElement{
param(
  $doc,
  [string]$elementName,
  [string]$value,
  $parent
)

	$ns = $null
  if (($elementname -split ':').count -gt 1) {
	$p = ($elementname -split ':')[0]
	write-host "[$p] $elementname = $value "
	$ns = $root.GetNamespaceOfPrefix($p)
	} 
  $thisNode = $doc.CreateNode("element", $elementName, $ns)
  $thisNode.InnerText = $value
  $null = $parent.AppendChild($thisNode)
  return $thisNode
}

Function New-Channel
{
param($doc, $root) 

	$rssChannel = $doc.CreateNode("element", 'channel', $null)
	$null = createRssElement $doc -elementName 'title' -value 'Cottenham Baptist Church 2019 Sermons' -parent $rssChannel
	$null = createRssElement $doc -elementName 'description' -value @"
Get comfortable and listen to Kate Lees our minister at a tiny community church. We record most Sundays, but sometimes the equipment beats us, or we are just having more community spirit than we should. Kate and our leadership team do change it up a lot. This podcast will be broken into seasons or years as a separate feed to make it easier to manage. The first season are all local stand-in preachers, but in (fill year here) Kate left her big church in London to serve us, along with her husband Simon and 2 boys.
"@ -parent $rssChannel
	$null = createRssElement $doc -elementName 'link' -value $url_home -parent $rssChannel
	$null = createRssElement $doc -elementName 'language' -value 'en-UK' -parent $rssChannel
	$null = createRssElement $doc -elementName 'copyright' -value 'entity' -parent $rssChannel
	$null = createRssElement $doc -elementName 'lastBuildDate' -value $([datetime]::Now.ToString('s')) -parent $rssChannel
	$null = createRssElement $doc -elementName 'pubDate' -value $([datetime]::Now.ToString('s')) -parent $rssChannel
	$null = createRssElement $doc -elementName 'itunes:image' -value "$($url_home)/images/coverart.jpg" -parent $rssChannel
	$null = createRssElement $doc -elementName 'itunes:author' -value "Cottenham Baptist Church" -parent $rssChannel
	
	# category subnode
	$null = createRssElement $doc -elementName 'itunes:category' -value "" -parent $rssChannel
	$cat = $rssChannel['itunes:category']
	$cat.SetAttribute("text", "Religion & Spirituality") # christianity
	$rssChannel
} # new-channel

Function New-Root($doc) {
	$root = $doc.CreateNode("element","rss",$null)

	$rssatt = @{"version"="2.0"; "xmlns:itunes"="http://www.itunes.com/dtds/podcast-1.0.dtd" ;"xmlns:content"="http://purl.org/rss/1.0/modules/content/"}
	foreach ($k in $rssatt.keys) {
		$root.SetAttribute( $k, $rssatt[$k])
	}
	# add namespaces to manager
	$nsm = New-Object System.Xml.XmlNamespaceManager($doc.nametable)
	$nsm.addnamespace("itunes", $root.GetNamespaceOfPrefix("itunes"))
	$nsm.addnamespace("content", $root.GetNamespaceOfPrefix("content"))
	write-output $root
}

$root = New-Root($doc)
	
$rssChannel = New-Channel $doc $root
Write-host "Indexing facebook links..."
$links = ls \\hpnas\Disk0\Church\Sermons\fblinks | select name
$linkdates = $links | %{ [Datetime]($_.Name -split '\.')[0]}
# find all facebook posts within last 7 days of this mp3 file
$l = foreach ($emp3 in $(ls \\hpnas\Disk0\Church\Sermons\*.mp3)) { 
   try {$mp3date = [DateTime]($emp3.name -split '\.')[0] ; $postsMatched = @($linkDates | ?{ $_ -lt $mp3Date -and $_ -gt ($mp3Date - (New-timespan -days 7))})  ;
	  # if any found, grab the last on in the week and use it's link
      if ($postsMatched.count -gt 0) { New-object -typename psobject -prop @{mp3=$emp3.name; lnk= $postsMatched[-1].ToString('yyyy-MM-dd') + '.lnk'}}
   } catch {}
 }

# build a dictionary keyed on the mp3 files
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
Write-host "Found {0} links" -f $bflinks.count

# add mp3 item files
$files = $mp3files | ?{$_.name -like '2019*'}
foreach ($item in $files) {
	$thisItem = createRssElement $doc -elementName 'item' -value '' -parent $rssChannel
	$date = ($item.Name -split '\.')[0]
	try {
		$date = [Datetime]( $date )
	} catch {}
	$title = $item.Name
	try {
		$title = $date.ToString("ddd MMMM d") + " preaching: $($item.'Contributing artists')"
		$null = createRssElement $doc -elementName 'itunes:author' -value $item.'Contributing artists' -parent $thisItem
	} catch {}
	$null = createRssElement $doc -elementName 'title' -value $title -parent $thisItem
	# optional item url
	$item_url = $url_home
	if ($fblinks | where file -eq $item.name) {$item_url = ($fblinks | where file -eq $item.name).url}
	$null = createRssElement $doc -elementName 'link' -value $item_url -parent $thisItem
	
	$null = createRssElement $doc -elementName 'description' -value $title -parent $thisItem
	$null = createRssElement $doc -elementName 'guid' -value $item.FullName -parent $thisItem
	$enclosure = createRssElement $doc -elementName 'enclosure' -value '' -parent $thisItem
	$null = createRssElement $doc -elementName 'category' -value "Podcasts" -parent $thisItem
	$date = get-date
	try {
		$date = [Datetime](($item.Name -split '\.')[0] )
	} catch {}
	$null = createRssElement $doc -elementName 'pubDate' -value $date.ToString('u') -parent $thisItem
	$null = createRssElement $doc -elementName 'itunes:explicit' -value 'false' -parent $thisItem

	# The URL is by default the file path.
	# You may want something like:
	# $null = $enclosure.SetAttribute('url',"http://example.com/pathToMp3s/$($item.Name)")
	$null = $enclosure.SetAttribute('url',"$($url_base)$($item.Name)")
	$null = $enclosure.SetAttribute('length',"$($item.Length)")
	$null = $enclosure.SetAttribute('type','audio/mpeg')
}

$root.AppendChild($rssChannel) | Out-Null
$doc.AppendChild($root) | Out-Null
Write-Host "Saving the XML document to $Path" -ForegroundColor Green
$doc.save((join-path $pwd $Path ))