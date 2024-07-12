-- Please update version.sql too -- this keeps clean builds in sync
define version=704
@update_header

ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD (
	GUID       VARCHAR2(36)
);

BEGIN
	FOR r IN (
		SELECT survey_response_id FROM csr.quick_survey_response
	)
	LOOP
		UPDATE csr.quick_survey_response
		   SET guid = user_pkg.GenerateACT
		 WHERE survey_response_id = r.survey_response_id;
	END LOOP;
END;
/	

ALTER TABLE csr.QUICK_SURVEY_RESPONSE MODIFY GUID NOT NULL;

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
