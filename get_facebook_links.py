# get all facebook fosts and save them as yyyy-mm-dd.lnk files
#
# https://www.facebook.com/Cottenham-Baptist-Church-162430413816133/
# https://pypi.org/project/facebook-scraper/
#
# pip install facebook-scraper
#       https://m.facebook.com/story.php?story_fbid=2698578470201302&id=162430413816133
#       https://m.facebook.com/story.php?story_fbid=635398997265933&id=162430413816133
#
from facebook_scraper import get_posts

name = input("Facebook email/username: ")
pwd = input("Facebook password: ")
linkbase = '\\\\hpnas\Disk0\\Church\\Sermons\\fblinks\\'
cred = (name, pwd)

for post in get_posts('Cottenham-Baptist-Church-162430413816133', pages=10, credentials=cred): # only grab the last 10 posts each time - to do a complete rebuild set this to ~200 pages
	try:
		print("Post date : " + post['time'].strftime("%Y-%m-%d"))
		#print("img : "  + post['image'])
		#print("id : "   + post['post_id'])
		#print("URL : "  + post['post_url'])
		filename = linkbase + post['time'].strftime("%Y-%m-%d") + ".lnk"
		print(filename)
		with open(filename,"w+") as f:
			f.write("{0}={1}\r\n" .format ('url', post['post_url']))
			f.write("{0}={1}\r\n" .format ('img', post['image']))   # if image is not a key, jsut move along
	except Exception as e:
		print("Error while getting link to post: " + post['text'][:50])
		print(e) # ignore