SELECT
  *
FROM
  files
WHERE
  (
	    (
		      (
			        is_pending = 1
				        AND lower(_data) NOT LIKE '%.pending-%'
					      )
					      OR (
						        is_pending = 0
							        AND NOT _modifier = 4
								      )
								    )
								    AND (
									      (
										        owner_package_name IN ('com.instagram.android')
											        OR media_type = 3
												        OR media_type = 5
													        OR (
															          owner_package_name IN ('com.instagram.android')
																          AND media_type = 0
																	          AND mime_type LIKE 'video/%'
																		        )
																			        OR media_type = 1
																				      )
																				      AND (
																					        width > 0
																						        OR width IS NULL
																							      )
																							    )
																							  )
																							ORDER BY
																							  date_added DESC;
