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
           AND NAME = 'Sustainable Sourcing';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO QUESTIONNAIRE_GROUP 
                (GROUP_ID, APP_SID, NAME)
            VALUES
                (questionnaire_group_id_seq.nextval, v_app_sid, 'Sustainable Sourcing')
            RETURNING GROUP_ID INTO v_group_id;
    END;
	
	BEGIN
		INSERT INTO QUESTIONNAIRE_GROUP_MEMBERSHIP (QUESTIONNAIRE_ID, GROUP_ID, POS) 
			SELECT questionnaire_id, v_group_id, 2 
			  FROM QUESTIONNAIRE 
			 WHERE questionnaire_id = 2; -- the natural products questionnaire is always ID 2	
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;


	
	COMMIT;
END;
/
exit
