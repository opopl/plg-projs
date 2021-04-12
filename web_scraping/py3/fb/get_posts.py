
from facebook_scraper import get_posts

for post in get_posts('promovugroup', pages=10):
  if post:
    txt = post['text']
    if txt:
      print(txt[:200])
