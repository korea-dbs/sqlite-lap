SELECT _id, bucket_id, media_type, bucket_display_name, _data, date_added, mime_type, duration, width, height, is_favorite 
FROM files 
WHERE ((owner_package_name IN ( 'com.snowcorp.epik' ) OR media_type=3 OR media_type=5 OR owner_package_name IN ( 'com.snowcorp.epik' ) AND media_type=0 AND mime_type LIKE 'video/%' OR media_type=1 OR owner_package_name IN ( 'com.snowcorp.epik' ) AND media_type=0 AND mime_type LIKE 'image/%') 
AND (((is_pending=0 AND NOT _modifier=4) OR (is_pending=1 AND lower(_data) NOT LIKE '%.pending-%' AND owner_package_name IN ( 'com.snowcorp.epik' )))) 
AND (is_trashed=0) AND (volume_name IN ( 'external_primary' ))) 
AND ((_size > 0 AND (media_type = '1'))) 
ORDER BY (CASE WHEN datetaken > 0 THEN datetaken ELSE date_added*1000 END) DESC;
