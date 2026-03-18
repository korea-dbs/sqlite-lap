SELECT
  *
FROM
  images
WHERE
  (
	    (
		      (
			        is_pending = 1
				        -- REGEXP 대신 LIKE 사용. .pending- 패턴을 필터링합니다.
        AND lower(_data) NOT LIKE '%.pending-%'
	        AND owner_package_name IN ('com.zhiliaoapp.musically')
		      )
		      OR (
			        is_pending = 0
				        AND NOT _modifier = 4
					      )
					    )
					    AND (is_trashed = 0)
					    AND (volume_name IN ('external_primary'))
					    AND (mime_type NOT LIKE '%gif%')
					  )
					ORDER BY
					  date_modified DESC
					LIMIT
					  300 OFFSET 0;
