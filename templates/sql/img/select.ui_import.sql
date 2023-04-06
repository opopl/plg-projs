
SELECT um.url FROM url2md5 um
   INNER JOIN _info_imgs_tags AS inf
   ON um.url = inf.url
   WHERE inf.tag IN ("ui.import")
   AND um.sec = "{$sec}"
   ORDER BY um.mtime
   LIMIT {$limit}
   OFFSET {$offset}
