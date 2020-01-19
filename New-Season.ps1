# a new season/podcast script
# sources : https://gallery.technet.microsoft.com/scriptcenter/Capturing-and-using-Meta-4f81b7da
#           https://www.petri.com/creating-custom-xml-net-powershell
#           https://gist.github.com/arebee/a7a77044c77443effaeddbe3730af4ad
[Cmdletbinding()]
Param($season_year = "2020")
$Erroractionpreference = 'Stop'

$url_base = (gc '_url_Sermons.txt') # 'http://www.cottenhambaptist.org.uk/Sermons/'
$url_home = (gc '_url_homepage.txt') # 'http://www.cottenhambaptist.org.uk'
$local_sermons_path = '\\hpnas\Disk0\Church\Sermons'
$path = "season$($season_year).rss"	# also will be used to specify coverart.jpg as  coverart<season_year>.jpg
# RSS feed channel description
$description = @"
<![CDATA[Get comfortable and listen to Kate Lees our minister at a tiny community church. <br/>
We record most Sundays, but sometimes the equipment beats us, or we are just having more community spirit than we should. Kate and our leadership team do change it up a lot. This podcast will be broken into seasons or years as a separate feed to make it easier to manage. The first season are all local stand-in preachers, but in (fill year here) Kate left her big church in London to serve us, along with her husband Simon and 2 boys.<br/>
Other seasons: <a href="http://www.cottenhambaptist.org.uk/Sermons/season2019.rss">2020 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2019.rss">2019 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2018.rss">2018 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2017.rss">2017 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2016.rss">2016 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2015.rss">2015 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2014.rss">2014 Sermons</a><br/>
<a href="http://www.cottenhambaptist.org.uk/Sermons/season2013.rss">2013 Sermons</a><br/>
]]>
"@

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
		Write-Debug "[$p] $elementname = $value "
		$ns = $root.GetNamespaceOfPrefix($p)
	} 
	$thisNode = $doc.CreateNode("element", $elementName, $ns)
	if ($value -ne "") {
		$thisNode.InnerText = $value
	}
	$null = $parent.AppendChild($thisNode)
	return $thisNode
}

Function New-Channel
{
param($doc, $root) 

	$rssChannel = $doc.CreateNode("element", 'channel', $null)
	$null = createRssElement $doc -elementName 'title' -value "Cottenham Baptist Church $($season_year) Sermons" -parent $rssChannel
	$channelfile = "channel_description$($season_year).txt"
	if (test-path $channelfile) {$description = gc $channelfile ; Write-host "$channelfile loaded OK"}
	$null = createRssElement $doc -elementName 'description' -value $description -parent $rssChannel
	$null = createRssElement $doc -elementName 'link' -value $url_home -parent $rssChannel
	$null = createRssElement $doc -elementName 'language' -value 'en-UK' -parent $rssChannel
	$null = createRssElement $doc -elementName 'copyright' -value '&#169; Cottenham Baptist Church' -parent $rssChannel
	$null = createRssElement $doc -elementName 'lastBuildDate' -value $([datetime]::Now.ToString('s')) -parent $rssChannel
	$null = createRssElement $doc -elementName 'pubDate' -value $([datetime]::Now.ToString("ddd, dd MMM yyyy HH:MM:ss G\MT")) -parent $rssChannel
	# image
	$null = createRssElement $doc -elementName 'itunes:image' -value "" -parent $rssChannel
	$image = $rssChannel['itunes:image']
	$image.SetAttribute("href", "$($url_home)/images/coverart$($season_year).jpg")
	$null = createRssElement $doc -elementName 'itunes:author' -value "Cottenham Baptist Church" -parent $rssChannel
	$null = createRssElement $doc -elementName 'itunes:explicit' -value 'false' -parent $rssChannel
	# owner node
	$null = createRssElement $doc -elementName 'itunes:owner' -value "" -parent $rssChannel
	$owner = $rssChannel['itunes:owner']
	$null = createRssElement $doc -elementName 'itunes:name' -value "Cottenham Baptist Church" -parent $owner
	$null = createRssElement $doc -elementName 'itunes:email' -value "zaphodikus@hotmail.com" -parent $owner
	
	# category subnode
	$null = createRssElement $doc -elementName 'itunes:category' -value "" -parent $rssChannel
	$cat = $rssChannel['itunes:category']
	$cat.SetAttribute("text", "Religion & Spirituality") 
	# add subcategory christianity
	$null = createRssElement $doc -elementName 'itunes:category' -value "" -parent $cat
	$sub = $cat['itunes:category']
	$sub.SetAttribute("text", "Christianity") 
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

Function Get-FacebookPosts($savedlinks_path) # '\\hpnas\Disk0\Church\Sermons\fblinks'
{
	Write-host "Indexing facebook links in $($savedlinks_path) ..."
	$links = ls $savedlinks_path | select name
	$linkdates = $links | %{ [Datetime]($_.Name -split '\.')[0]}
	Write-host ("  checking total {0} posts for matches" -f $linkdates.count)
	# find all facebook posts within last 7 days of this mp3 file
	$read_links = foreach ($emp3 in $(ls "$($local_sermons_path)\*.mp3")) { 
	   try {$mp3date = [DateTime]($emp3.name -split '\.')[0] ; $postsMatched = @($linkDates | ?{ $_ -le $mp3Date -and $_ -gt ($mp3Date - (New-timespan -days 7))})  ;
		  # if any found, grab the last on in the week and use it's link
		  if ($postsMatched.count -gt 0) { New-object -typename psobject -prop @{mp3=$emp3.name; lnk= $postsMatched[-1].ToString('yyyy-MM-dd') + '.fb'}};
		  write-host -nonewline "."
	   } catch {}
	}

	# build a dictionary keyed on the mp3 files
	$fblinks = $read_links | %{ $o= new-object -typename psobject; add-member -inputobject $o -membertype NoteProperty -name 'file' -value $_.mp3; 
		write-host -nonewline "f";
		gc (join-path $savedlinks_path $_.lnk)| %{ # todo: load this from the metadata file instead
			if ($_ -like 'url=*') {
				add-member -inputobject $o -membertype noteProperty -Name 'url' -value (($_ -split '=')[1..9] -join '=')  
			} 
			if ($_ -like 'img=*') { 
				add-member -inputobject $o -membertype noteProperty -Name 'img' -value (($_ -split '=')[1..9] -join '=')} 
			} 
		$o
	}
	Write-host ("Found {0} related Facebook posts" -f $fblinks.count)
	$fblinks
}

function Add-EpisodeItem {
[CmdletBinding()]
param([Alias("document")]$doc, 
	[Alias("channel")]$rssChannel, 
	$item, 
	$facebookPost) 

	Write-host -nonewline "m"
	$thisItem = createRssElement $doc -elementName 'item' -value '' -parent $rssChannel
	$date = ($item.Name -split '\.')[0]
	Write-verbose "add episode: $($date)"
	$date = $date.TrimEnd([char[]](58..254)-match'\w') # strip all trailing non-numerics
	$date = $date.TrimEnd('-')
	$date = $date.replace('_', '-')
	$date = $date[0..9] -join ''
	try {
		$date = [Datetime]( $date )
	} catch {
		Write-Warning "Error determining date for podcast item: $date"	
	}
	$title = $item.Name
	try {
		$title = $date.ToString("ddd MMMM d") + " preaching: $($item.'Contributing artists')"
		$null = createRssElement $doc -elementName 'itunes:author' -value $item.'Contributing artists' -parent $thisItem
	} catch {
		Write-Warning "Error creating podcast entry date for item"
	}
	$null = createRssElement $doc -elementName 'title' -value $title -parent $thisItem
	# optional item url
	$item_url = $url_home
	if ($facebookPost) {$item_url = $facebookPost.url}
	$null = createRssElement $doc -elementName 'link' -value $item_url -parent $thisItem
	$description = $title + "\n"
	if ($facebookPost -and $facebookPost.PSobject.Properties.Name -contains "text") { description += $facebookPost.text}
	$null = createRssElement $doc -elementName 'description' -value $description -parent $thisItem
	$null = createRssElement $doc -elementName 'guid' -value $item.Name -parent $thisItem
	$enclosure = createRssElement $doc -elementName 'enclosure' -value '' -parent $thisItem
	$null = createRssElement $doc -elementName 'category' -value "Podcasts" -parent $thisItem

	$null = createRssElement $doc -elementName 'pubDate' -value $date.ToString("ddd, dd MMM yyyy HH:MM:ss G\MT") -parent $thisItem
	$null = createRssElement $doc -elementName 'itunes:explicit' -value 'false' -parent $thisItem
	$null = createRssElement $doc -elementName 'itunes:duration' -value $item.Length -parent $thisItem

	# The URL is by default the file path.
	# You may want something like:
	# $null = $enclosure.SetAttribute('url',"http://example.com/pathToMp3s/$($item.Name)")
	$null = $enclosure.SetAttribute('url',"$($url_base)$($item.Name)")
	$len = (get-item (join-path $local_sermons_path $item.Name)).length
	$null = $enclosure.SetAttribute('length',"$( $len )")
	$null = $enclosure.SetAttribute('type','audio/mpeg')
	try {
		if ($facebookPost) {
			$null = createRssElement $doc -elementName 'itunes:image' -value $facebookPost.img -parent $thisItem
			write-host -nonewline '@'
		}
	} catch {
		Write-Warning "Error creating podcast entry image for item"
	}
}

#########################################################
# this step takes about 5 minutes, if the file does not exist - 
# Note: to re-index all files, just delete the file, otherwise it will just update with new mp3's
. .\Get-MP3MetaData.ps1
if (-not (test-path '_MP3MetaData.xml')) {
	Write-Host "Gathering mp3 local file Metadata"
	$mp3Files = Get-MP3MetaData $local_sermons_path
	$mp3Files | Export-cliXml -depth 3 -Path '_MP3MetaData.xml'
} else {
	$mp3Files = Import-cliXml -Path '_MP3MetaData.xml'
}
Write-Host "Metadata loaded."
$mp3s_to_index = @(ls $local_sermons_path | ?{$_.name -like '*.mp3' -and -not ( $_.name -in $mp3Files.name)})
$mp3Files += $mp3s_to_index | %{
	Write-host "Adding new MP3 tags from $($_.name)" 
	Get-MP3FileMetaData (Get-ShellApplication $local_sermons_path) $_
}
if ($mp3s_to_index.count) {
	$mp3Files | Export-cliXml -depth 3 -Path '_MP3MetaData.xml'
	Write-Host "Tags saved OK"
}

################################################################
# RSS feed document
[xml]$Doc = New-Object System.Xml.XmlDocument
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$Doc.AppendChild($dec) | out-null

$root = New-Root($doc)
	
$rssChannel = New-Channel $doc $root
# Import Facebook page link text files
# see get_facebook_links.py for details
$fblinks = Get-FacebookPosts -localmp3 $local_sermons_path -savedlinks_path (join-path $local_sermons_path 'fblinks')

# add mp3 item files
$files = @($mp3files | ?{$_.name -like "$($season_year)*"})
foreach ($item in $files) {
	Add-EpisodeItem  -document $doc -channel $rssChannel -item $item -facebookPost ($fblinks | where file -eq $item.name)
}

write-host ("Added {0} episodes" -f $files.count)
$root.AppendChild($rssChannel) | Out-Null
$doc.AppendChild($root) | Out-Null
Write-Host "Saving the XML document to $Path" -ForegroundColor Green
$doc.save((join-path $pwd $Path ))
