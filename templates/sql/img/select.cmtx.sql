
SELECT DISTINCT imgs.url FROM imgs
  INNER JOIN _info_imgs_tags AS inf1
  ON imgs.url = inf1.url
  INNER JOIN _info_imgs_tags AS inf2
  ON imgs.url = inf2.url
  WHERE
    inf1.tag = "scrn"
    AND inf2.tag = "orig.cmt"
    AND imgs.sec = "{$sec}"
  ORDER BY imgs.mtime
