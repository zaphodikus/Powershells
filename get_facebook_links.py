# get all facebook fosts and save them as yyyy-mm-dd.lnk files
#
# https://www.facebook.com/Cottenham-Baptist-Church-162430413816133/
# https://pypi.org/project/facebook-scraper/
#
# pip install facebook-scraper
#       https://m.facebook.com/story.php?story_fbid=2698578470201302&id=162430413816133
#       https://m.facebook.com/story.php?story_fbid=635398997265933&id=162430413816133
#
from datetime import datetime
import requests
from lxml import html
from facebook_scraper import get_posts

linkbase = '\\\\hpnas\Disk0\\Church\\Sermons\\fblinks\\'
pagename = 'Cottenham-Baptist-Church-162430413816133'
count_pages = 0
count_links = 0
count_images = 0
count_recoveredtimes = 0
print("Log in to retrieve facebook links from {}".format(pagename))
name = input("Facebook email/username: ")
pwd = input("Facebook password: ")
cred = (name, pwd)

for post in get_posts(pagename, pages=350, credentials=cred): # only grab the last 10 posts each time - to do a complete rebuild set this to ~200 pages
	try:
		count_pages +=1
		time = None
		try:
			time = post['time']
			s = time.strftime("%Y-%m-%d")
		except Exception as t:
			print("Reconstruct a TIME for: {0}".format(post['post_url']))
			link_page = requests.get(post['post_url'])
			link_root = html.fromstring(link_page.text.encode('utf-8'))
			link_time = link_root.xpath('//abbr/text()')[0]
			time = datetime.strptime(link_time, "%d %B %Y at %H:%M")
			count_recoveredtimes+=1
		print("Post date : " + time.strftime("%Y-%m-%d"))

		filename = linkbase + time.strftime("%Y-%m-%d") + ".fb"
		print(filename)
		with open(filename, "w+", encoding="utf-8") as f:
			if post['post_url'] is not None:
				f.write("{0}={1}\n" .format ('url', post['post_url'].strip()))
				count_links +=1
			else:
				print("Missing a link : {0}...".format(post['text'][:50].strip()))
			if 'image' in post.keys():
				f.write("{0}={1}\n" .format ('img', post['image']))   # if image is not a key, just move along
				count_images +=1
			if 'text' in post.keys():
				f.write("{0}={1}\n" .format ('text', post['text'][:250].strip()))
			
	except Exception as e:
		print("Error {0} \nWhile saving link to post: {1}".format( str(e) , post['text'][:50]))
		print(post)
print ("pages {0} | links {1} | images {2}".format(count_pages, count_links, count_images))
print ("recovered timestamps {0}".format(count_recoveredtimes))