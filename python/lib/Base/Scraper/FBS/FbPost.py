
from Base.Core import CoreClass

class FbPost(CoreClass):
  # mobile url, TEXT
  url_m = ''

  # url, TEXT
  url = ''

  # story text, TEXT
  story = ''

  # comments list, ARRAY
  clist = []

  # total number of comments, including sub-comments 
  #     not-equal to len(clist)
  ccount = 0

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

  def _clist(self, ref={}):
    '''
      Purpose
        Retrieve list of comments

      Usage
        input: single web element
          clist = self._clist({ 'el'  : el })

        input: list of Web elements
          clist = self._clist({ 'els' : els })

      Return
        ARRAY
    '''
    elin = ref.get('el') or self.app.driver

    cmt_elems = ref.get('els')
    if not cmt_elems:
      cmt_elems = app._els_comments({ 'el' : elin })

    clist = []

    if not cmt_elems:
      return clist

    for comment in cmt_elems:
      cmt = {}

      reply = app._el_reply({ 'el' : comment })
      if reply:
        print('Reply click')
        reply.click()
        time.sleep(1)

        replies_inline = None
        try:
          replies_inline = comment.find_elements_by_xpath('.//div[ @data-sigil="comment inline-reply" ]')
        except:
          pass

        if replies_inline and len(replies_inline):
          print('Found more replies')
          clist_sub = self._clist({ 'els' : replies_inline })

          if len(clist_sub):
            print(f'cmt <- {len(clist_sub)} replies')
            cmt['clist'] = clist_sub

###cmt_process
      el_auth = comment.find_element_by_xpath('.//div[@class="_2b05"]')
      if el_auth:
        cmt['auth_bare'] = el_auth.text

        el_auth_link = el_auth.find_element_by_xpath('.//a')
        if el_auth_link:
          href = el_auth_link.get_attribute('href')
          if href:
            u = util.url_parse(href,{ 'rm_query' : 1 })
            q = u['query']
            qp = util.url_parse_query(q)

            auth_url_path = u['path']
            if u['path'] == '/profile.php':
              if 'id' in qp:
                id = qp.get('id')
                auth_url_path = u['path'] + '?id=' + id

            cmt['auth_url_path'] = auth_url_path
            cmt['auth_url']      = util.url_join('https://www.facebook.com', auth_url_path)

      el_txt = comment.find_element_by_xpath('.//*[@data-sigil="comment-body"]')
      if el_txt:
        cmt['txt'] = el_txt.text
        cmt['src'] = el_txt.get_attribute('innerHTML')

      if len(cmt):
        clist.append(cmt)
        self.ccount += 1

    return clist

  def _clist2tex(self,ref={}):
    clist = ref.get('clist') or self.clist

    tex = []
    if clist and len(clist):
      tex.append('\\begin{itemize}')

      for cmt in clist:
        tex_cmt = self._cmt2tex({ 'cmt' : cmt })
        tex.extend(tex_cmt)

      tex.append('\\end{itemize}')

    return tex

  def _cmt2tex(self,ref={}):
    cmt = ref.get('cmt')

    tex = []

    auth_bare = cmt.get('auth_bare')
    auth_url  = cmt.get('auth_url')
    clist_sub = cmt.get('clist',[])

    txt       = cmt.get('txt')

    if auth_bare:
      tex.append('\\iusr{' + auth_bare + '}')
      if auth_url:
        tex.append('\\url{' + auth_url + '}')

      tex.extend(['',txt,''])

      if len(clist_sub):
        tex.extend( self._clist2tex({ 'clist' : clist_sub }) )

    return tex

  def save_story(self,ref={}):
    elin = ref.get('el') or self.app.driver

    story = None
    try:
      story = elin.find_element_by_css_selector('.story_body_container')
    except:
      print('ERROR: could not find story!')
      raise
      pass

    if not story:
      return self

    story_txt = story.text
    story_src = story.get_attribute('innerHTML')

    self.set({
        'story'      : {
          'txt' : story_txt,
          'src' : story_src,
        }
    })
    
    return self

  def get_url(self,ref={}):
    url = ref.get('url',self.url_m)

    app.driver.get(url)

    # 18.01.2021
    #self.driver.get('https://mobile.facebook.com/yevzhik/posts/3566865556681862')

    #self.driver.get('https://mobile.facebook.com/nitsoi.larysa/posts/938801726686200')
    #self.driver.get('https://mobilefacebook.com/olesia.medvedieva/posts/1637472103110572')
    return self

  def save_comments(self,ref={}):

    clist = self._clist()

    self.set({
      'clist'   : clist,
      'ccount'  : self.ccount,
    })

    print(f'Total Comment Count: {self.ccount}')

    return self
