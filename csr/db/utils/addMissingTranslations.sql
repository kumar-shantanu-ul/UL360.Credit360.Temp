BEGIN
	INSERT INTO csr.ind_description (app_sid, ind_sid, lang, description)
		SELECT app_sid, ind_sid, lang, description
		  FROM (SELECT id.app_sid, id.ind_sid, ts.lang, id.description
				  FROM csr.ind_description id, aspen2.translation_set ts
				 WHERE id.lang = 'en'
				   AND ts.application_sid = id.app_sid)
		 WHERE (app_sid, ind_sid, lang) NOT IN (SELECT app_sid, ind_sid, lang
												  FROM csr.ind_description);

	INSERT INTO csr.region_description (app_sid, region_sid, lang, description)
		SELECT app_sid, region_sid, lang, description
		  FROM (SELECT rd.app_sid, rd.region_sid, ts.lang, rd.description
				  FROM csr.region_description rd, aspen2.translation_set ts
				 WHERE rd.lang = 'en'
				   AND ts.application_sid = rd.app_sid)
		 WHERE (app_sid, region_sid, lang) NOT IN (SELECT app_sid, region_sid, lang
										             FROM csr.region_description);
END;
/
