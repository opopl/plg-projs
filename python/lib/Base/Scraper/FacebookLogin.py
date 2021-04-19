
from selenium import webdriver

import time
import os
 
LOGIN_URL = 'https://www.facebook.com/login.php'
 
class FacebookLogin():
    email = None
    password = None

    # Firefox profile
    fp = None

    def __init__(self):
        if not self.email:
          self.email = os.environ.get('FB_LOGIN')

        if not self.password:
          self.password = os.environ.get('FB_PASS')

        fp = webdriver.FirefoxProfile()
        fp.set_preference("dom.webnotifications.enabled",False)
        fp.set_preference("geo.enabled",False)
    
        self.fp = fp
    
        driver = webdriver.Firefox(fp)
        self.driver = driver

        self.driver.get(LOGIN_URL)
        time.sleep(1) # Wait for some time to load
 
    def login(self):
        email_element = self.driver.find_element_by_id('email')
        email_element.send_keys(self.email) # Give keyboard input
 
        password_element = self.driver.find_element_by_id('pass')
        password_element.send_keys(self.password) # Give password as input too
 
        login_button = self.driver.find_element_by_id('loginbutton')
        login_button.click() # Send mouse click
 
        time.sleep(2) # Wait for 2 seconds for the page to show up
