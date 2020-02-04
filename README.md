# Powershells
Various misc powershell scripts

Add-Diff.ps1 [https://github.com/zaphodikus/Powershells/blob/master/add-diff.ps1] is a standalone Windows "sendto" menu handler. It installs itself as a send-to special folder the first time you run it. This lets you use Windows Explorer to select 2 files to diff. Just click file1 (left file to diff), then send-to windiff, you will see the customary black box briefly appear. Then do the send-to on the 2nd file (right) and windiff will open. It keeps doing this by remembering the left file each time.
You have to place windiff.exe (just google for the grisoft hosted download) in the same folder as the posh script. It breaks if you run this script a folder without windiff.exe first. In which case you must delete the .CMD wrapper file it installs. 

My Mp3 uploader [https://github.com/zaphodikus/Powershells/blob/master/Rebuild-FTPlistingG.ps1] uploads a file, then builds a listing, beuilds a web page, then uploades that page.  It's a bit custom and uses the ftp commandline tool under the hood. Should work on any windows 7 onwards where the network tools (ftp) is optionally installed.

[https://github.com/zaphodikus/Powershells/blob/master/update_image.ps1] is a clone of the MP3 uploader, the difference it that it pushes a jpeg or image file without all the other hopping about.

[https://github.com/zaphodikus/Powershells/blob/master/update_rss.ps1] is also a clone of the MP3 uploader, the difference it that it pushes an rss file (for the podcast) without all the other hopping about.

Basically at some point all this code around the RSS feed, mp3 files and uploading to website needs porting into python. So far the only piece in python is [https://github.com/zaphodikus/Powershells/blob/master/get_facebook_links.py]

Most of these scripts use an external/extra set of text files to hold passwords, or handy parameter defaults, which I've not included since they contain secrets/metadata.
