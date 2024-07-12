PROMPT doing questionnaires

DECLARE
    v_group_id  questionnaire_group.group_id%TYPE;
    v_app_sid   security_pkg.T_SID_ID;
BEGIN    
    -- which questionnaire group?
    SELECT app_sid
      INTO v_app_Sid
      FROM csr.customer
     WHERE host = '&&1';
	 
	 -- customer options
    BEGIN
        INSERT INTO customer_options (app_sid, user_work_filter, search_product_url) VALUES (v_app_Sid, 1, '/bootssupplier/site/admin/searchProduct.acds');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN 
			NULL;
    END;
    
    -- try and insert - there's no constraint on name/app_sid, so we do this instead
    BEGIN
        SELECT GROUP_ID
          INTO v_group_Id
          FROM QUESTIONNAIRE_GROUP
         WHERE APP_SID = v_app_sid
           AND NAME = 'Green Tick';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO QUESTIONNAIRE_GROUP 
                (GROUP_ID, APP_SID, NAME, workflow_type_id)
            VALUES
                (questionnaire_group_id_seq.nextval, v_app_sid, 'Green Tick', 2)
            RETURNING GROUP_ID INTO v_group_id;
    END;

	FOR r IN 
	(
		SELECT questionnaire_id FROM questionnaire WHERE questionnaire_id IN (8,9,10,11,12,13)
	)
	LOOP
	    BEGIN
			INSERT INTO QUESTIONNAIRE_GROUP_MEMBERSHIP (QUESTIONNAIRE_ID, GROUP_ID, POS) VALUES (r.questionnaire_id, v_group_id, r.questionnaire_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

    COMMIT;
END;
/

commit;

PROMPT Doing tags

--@doPCTagsForHost

exit

