
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
      clist = self._clist({ 'el'  : el })
      clist = self._clist({ 'els' : els })
    '''
    elin = ref.get('el') or self.app.driver

    cmt_els = ref.get('els')
    if not cmt_els:
      cmt_els = self._el_comments({ 'el' : elin })

    clist = []

    if not cmt_els:
      return clist

    for comment in cmt_els:
      cmt = {}

      reply = self._el_reply({ 'el' : comment })
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
          clist_sub = self._post_clist({ 'els' : replies_inline })

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
        self.comment_count += 1

    return clist



