-- Please update version.sql too -- this keeps clean builds in sync
define version=2047
@update_header

BEGIN		
	
	/* Add merge fields to Chain Supplier Survey */
	BEGIN
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5015, 0, 'SECONDARY_COMPANY', 'Secondary company', 'Placeholder for a secondary reference company', 12);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN	
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5015, 0, 'SURVEY_NAME', 'Survey name', 'Survey name', 13);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/ 

@update_tail