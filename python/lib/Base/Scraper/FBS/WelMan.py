
from Base.Core import CoreClass

class WelMan(CoreClass):
  driver = None

  wel = None

  def __init__(self,wel,ref={}):
    self.wel = wel

    for k, v in ref.items():
      setattr(self, k, v)

    if not self.driver:
      if self.wel:
        if type(self.wel).__name__ == 'WebDriver':
          self.driver = self.wel
        else:
          self.driver = self.wel.parent

  def src(self):
    wel_parent = self.find_one({ 
      'wel'    : self.wel,
      'xpath' : '..',
    })

    wel_src = wel_parent or self.wel

    src = wel_src.get_attribute('innerHTML')

    return src

  def find_comments(self):
    wels = self.find({ 
      'xpath' : './/div[ @data-sigil="comment" ]'
    })

    return wels

  def find_reply(self):
    wel = self.find_one({ 
      'xpath' : './/div[ @data-sigil="replies-see-more" ]'
    })

    return wel

  def find_one(self,ref={}):
    xpath = ref.get('xpath','')
    css   = ref.get('css','')

    welf = None

    if xpath:
      try:
        welf = self.wel.find_element_by_xpath(xpath)
      except:
        pass

    if css:
      try:
        welf = self.wel.find_element_by_css_selector(css)
      except:
        pass
          
    return welf

  def find(self,ref={}):
    xpath = ref.get('xpath','')
    css   = ref.get('css','')

    wels = []

    if xpath:
      try:
        wels = self.wel.find_elements_by_xpath(xpath)
      except:
        pass

    if css:
      try:
        wels = self.wel.find_elements_by_css_selector(css)
      except:
        pass
          
    return wels
