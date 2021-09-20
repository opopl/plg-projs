
import xml.etree.ElementTree as et
from lxml import etree
import lxml.html

from io import StringIO, BytesIO

from Base.Core import CoreClass
import Base.Util as util
from dict_recursive_update import recursive_update

class WebDoc(CoreClass):
  def __init__(self,args={}):
    recursive_update(self.__dict__, args)
    #for k, v in args.items():
      #setattr(self, k, v)
