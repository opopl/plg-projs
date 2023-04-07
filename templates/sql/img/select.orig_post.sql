
SELECT DISTINCT imgs.url FROM imgs
  INNER JOIN _info_imgs_tags AS inf1
  ON imgs.url = inf1.url
  INNER JOIN _info_imgs_tags AS inf2
  ON imgs.url = inf2.url
  WHERE
    inf1.tag = "scrn"
    AND inf2.tag = "orig.post"
    AND imgs.sec = "{$parent_section}"
  ORDER BY imgs.mtime
