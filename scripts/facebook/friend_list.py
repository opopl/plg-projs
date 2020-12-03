#!/usr/bin/env python3

import facebook
import os

token = os.environ.get('FB_USER_ACCESS_TOKEN')

graph = facebook.GraphAPI(token)
profile = graph.get_object("me")
friends = graph.get_connections("me", "friends")

friend_list = [friend['name'] for friend in friends['data']]

print(friend_list)
