PROMPT This script will copy all translations from SiteA.credit360.com to SiteB.credit360.com
PROMPT Enter the host name FROM (SiteA), then host name TO (SiteB)
DECLARE
	in_site_from		VARCHAR2(255) := '&&1';
	in_site_to			VARCHAR2(255) := '&&2';
	v_from_app_sid		NUMBER(10) := 0;
	v_to_app_sid		NUMBER(10) := 0;
BEGIN
	BEGIN
		SELECT app_sid INTO v_to_app_sid FROM csr.customer WHERE host=in_site_to;
		SELECT app_sid INTO v_from_app_sid FROM csr.customer WHERE host=in_site_from;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			raise_application_error(-20001,'unknown host - ' || in_site_from || ' / ' || in_site_to);
	END;

	security.security_pkg.debugmsg('aspen2.translation_application');
	FOR r IN (SELECT base_lang, static_translation_path FROM aspen2.translation_application WHERE application_sid = v_from_app_sid)
	LOOP
		BEGIN
			INSERT INTO aspen2.translation_application (application_sid, base_lang, static_translation_path)
				 VALUES (v_to_app_sid, r.base_lang, r.static_translation_path);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
		END;
	END LOOP;

	security.security_pkg.debugmsg('aspen2.translation_set');
	FOR r IN (SELECT lang,revision,hidden FROM aspen2.translation_set WHERE application_sid = v_from_app_sid)
	LOOP
		BEGIN
			INSERT INTO aspen2.translation_set (application_sid, lang, revision, hidden)
				 VALUES (v_to_app_sid, r.lang, r.revision, r.hidden);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
		END;
	END LOOP;

	security.security_pkg.debugmsg('aspen2.translation_set_include');
	FOR r IN (SELECT lang,pos,to_application_sid,to_lang FROM aspen2.translation_set_include WHERE application_sid = v_from_app_sid)
	LOOP
		BEGIN
			INSERT INTO aspen2.translation_set_include (application_sid, lang, pos, to_application_sid, to_lang)
				 VALUES (v_to_app_sid, r.lang, r.pos, v_to_app_sid, r.to_lang);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
		END;
	END LOOP;

	FOR r IN (SELECT
				tn.original, td.lang, td.translated, tn.original_hash
			   FROM aspen2.translation tn
			   JOIN aspen2.translated td ON tn.original_hash = td.original_hash
				AND TN.APPLICATION_SID = TD.APPLICATION_SID
			  WHERE TD.APPLICATION_SID = v_from_app_sid)
	LOOP
		BEGIN
			INSERT INTO aspen2.translation
				(application_sid, original_hash, original)
			VALUES
				(v_to_app_sid, r.original_hash, r.original);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE aspen2.translation
				   SET original = r.original
				 WHERE original_hash = r.original_hash
				   AND application_sid = v_to_app_sid;
		END;

		BEGIN
			INSERT INTO aspen2.translated
				(application_sid, lang, original_hash, translated_id, translated)
			VALUES
				(v_to_app_sid, r.lang, r.original_hash, aspen2.translated_id_seq.NEXTVAL, r.translated);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE aspen2.translated
				   SET translated = r.translated
				 WHERE original_hash = r.original_hash
				   AND application_sid = v_to_app_sid
				   AND lang = r.lang;
		END;

		-- poke it to refresh the lot
		UPDATE aspen2.translation_set
		   SET revision = revision + 1
		 WHERE (application_sid, lang) IN (
		 		SELECT application_sid, lang
		 		  FROM aspen2.translation_set_include
		 		 WHERE to_application_sid = security_pkg.getapp);

		COMMIT; -- should prevent any blockers... commit after each upsert.
	END LOOP;

	security.security_pkg.debugmsg('csr.region_description');
	FOR r IN (SELECT fromr.region_sid frs,tor.region_sid trs FROM csr.v$region fromr JOIN csr.v$region tor ON fromr.description = tor.description WHERE fromr.region_sid = v_from_app_sid)
		LOOP
			FOR s IN (SELECT lang,description FROM csr.region_description WHERE region_sid = r.frs)
			LOOP
				BEGIN
					INSERT INTO csr.region_description
						(app_sid,region_sid,lang,description)
					VALUES
						(v_to_app_sid,r.trs,s.lang,s.description);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE csr.region_description
						   SET description = s.description
						 WHERE lang = s.lang
						   AND region_sid = r.trs
						   AND app_sid = v_to_app_sid;
				END;
			END LOOP;
		COMMIT; -- should prevent any blockers... commit after each upsert.
	END LOOP;

	security.security_pkg.debugmsg('csr.ind_description');
	FOR r IN (SELECT fromr.ind_sid frs,tor.ind_sid trs FROM csr.v$ind fromr JOIN csr.v$ind tor ON fromr.description = tor.description WHERE fromr.ind_sid = v_from_app_sid)
		LOOP
			FOR s IN (SELECT lang,description FROM csr.ind_description WHERE ind_sid = r.frs)
			LOOP
				BEGIN
					INSERT INTO csr.ind_description
						(app_sid,ind_sid,lang,description)
					VALUES
						(v_to_app_sid,r.trs,s.lang,s.description);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE csr.ind_description
						   SET description = s.description
						 WHERE lang = s.lang
						   AND ind_sid = r.trs
						   AND app_sid = v_to_app_sid;
				END;
			END LOOP;
		COMMIT; -- should prevent any blockers... commit after each upsert.
	END LOOP;
END;
/
