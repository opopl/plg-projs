
SELECT um.url FROM url2md5 um
   INNER JOIN _info_imgs_tags AS inf
   ON um.url = inf.url
   WHERE inf.tag IN ("ui.import")
   AND um.sec = "{$parent_section}"
   ORDER BY um.mtime
   {
     $OUT .= "LIMIT $limit" . "\n" if $limit;
     $OUT .= "OFFSET $offset" . "\n" if $offset;
   }
