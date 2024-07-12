-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

CREATE OR REPLACE PROCEDURE csr.Temp_UpdateSITParams (
	in_std_alert_type_id			IN NUMBER,
	in_field_name                  	IN VARCHAR2,
	in_repeats						IN NUMBER, 
	in_description                 	IN VARCHAR2,
	in_help_text                   	IN VARCHAR2,
	in_display_pos					IN NUMBER
)
AS
	v_curr_repeat					NUMBER;
BEGIN

	BEGIN
		SELECT repeats 
		  INTO v_curr_repeat 
		  FROM csr.STD_ALERT_TYPE_PARAM 
		 WHERE std_alert_type_id = in_std_alert_type_id
		   AND UPPER(field_name) = UPPER(in_field_name);
		   
		IF v_curr_repeat <> in_repeats THEN
			RAISE_APPLICATION_ERROR(-20001, 'cannot change repeat type');
		END IF;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos) 
			VALUES (in_std_alert_type_id, NVL(in_repeats, 0), UPPER(in_field_name), in_description, NVL(in_help_text, '#help_text_'||in_std_alert_type_id), in_display_pos);
		--DBMS_OUTPUT.PUT_LINE(in_std_alert_type_id||'/'||in_field_name||' - Inserting new param'); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.std_alert_type_param 
			SET 	repeats = NVL(in_repeats, repeats),
					description = in_description,
					help_text = NVL(in_help_text, help_text),
					display_pos = in_display_pos
			WHERE std_alert_type_id = in_std_alert_type_id
			  AND UPPER(field_name) = UPPER(in_field_name);
		--DBMS_OUTPUT.PUT_LINE(in_std_alert_type_id||'/'||in_field_name||' - Updating param'); 
	END;
END;
/

BEGIN
	UPDATE csr.std_alert_type_param
	   SET description = 'Issue ID'
	 WHERE LOWER(description) = 'the issue id string'
	   AND std_alert_type_id IN (17,32,33,34,35,36,18,47,60,61); 
END;
/

-- 17 - 'Mail sent when a comment is made on an issue'
BEGIN
	csr.Temp_UpdateSITParams(17, 'ASSIGNED_TO',0,'Assigned to',null,0);
	csr.Temp_UpdateSITParams(17, 'ASSIGNED_TO_USER_SID',0,'Assigned to user SID',null,1);
	csr.Temp_UpdateSITParams(17, 'COMMENT',0,'Comment',null,2);
	csr.Temp_UpdateSITParams(17, 'DUE_DTM',0,'Issue due date',null,13);
	csr.Temp_UpdateSITParams(17, 'FROM_EMAIL',0,'From e-mail',null,6);
	csr.Temp_UpdateSITParams(17, 'FROM_FRIENDLY_NAME',0,'From friendly name',null,7);
	csr.Temp_UpdateSITParams(17, 'FROM_NAME',0,'From name',null,9);
	csr.Temp_UpdateSITParams(17, 'FROM_USER_NAME',0,'From user name',null,10);
	csr.Temp_UpdateSITParams(17, 'CRITICAL',0,'Issue critical',null,12);
	csr.Temp_UpdateSITParams(17, 'ISSUE_DETAIL',0,'Issue details',null,13);
	csr.Temp_UpdateSITParams(17, 'ISSUE_ID',0,'Issue ID',null,14);
	csr.Temp_UpdateSITParams(17, 'ISSUE_LABEL',0,'Issue label',null,15);
	csr.Temp_UpdateSITParams(17, 'ISSUE_LINK',0,'Issue link',null,16);
	csr.Temp_UpdateSITParams(17, 'ISSUE_REF',0,'Issue ref',null,17);
	csr.Temp_UpdateSITParams(17, 'ISSUE_STATUS',0,'Issue status',null,18);
	csr.Temp_UpdateSITParams(17, 'ISSUE_TYPE_DESCRIPTION',0,'Issue type',null,19);
	csr.Temp_UpdateSITParams(17, 'ISSUE_URL',0,'Issue URL',null,20);
	csr.Temp_UpdateSITParams(17, 'RAISED_DTM',0,'Issue raised date',null,21);	
	csr.Temp_UpdateSITParams(17, 'PARENT_OBJECT_URL',0,'Parent object URL',null,22);
	csr.Temp_UpdateSITParams(17, 'PRIORITY_DESCRIPTION',0,'Priority',null,23);
	csr.Temp_UpdateSITParams(17, 'PRIORITY_DUE_DATE_OFFSET',0,'Priority offset in days',null,24);
	csr.Temp_UpdateSITParams(17, 'REGION_DESCRIPTION',0,'Region description',null,26);
	csr.Temp_UpdateSITParams(17, 'SHEET_LABEL',0,'Sheet label',null,28);
	csr.Temp_UpdateSITParams(17, 'SHEET_URL',0,'Sheet URL',null,29);
	csr.Temp_UpdateSITParams(17, 'HOST',0,'Site web address',null,30);
	csr.Temp_UpdateSITParams(17, 'TO_EMAIL',0,'To e-mail',null,31);
	csr.Temp_UpdateSITParams(17, 'TO_FRIENDLY_NAME',0,'To friendly name',null,32);
	csr.Temp_UpdateSITParams(17, 'TO_NAME',0,'To full name',null,33);
	csr.Temp_UpdateSITParams(17, 'TO_USER_NAME',0,'To user name',null,34);
	
END;
/

-- 18 - 'Mail sent containing issue summaries'
BEGIN
	csr.Temp_UpdateSITParams(18, 'ASSIGNED_TO',1,'Assigned to',null,0);
	csr.Temp_UpdateSITParams(18, 'ASSIGNED_TO_USER_SID',1,'Assigned to user SID',null,1);
	csr.Temp_UpdateSITParams(18, 'DUE_DTM',1,'Issue due date',null,13);
	csr.Temp_UpdateSITParams(18, 'FROM_EMAIL',0,'From e-mail',null,6);
	csr.Temp_UpdateSITParams(18, 'FROM_FRIENDLY_NAME',0,'From friendly name',null,7);
	csr.Temp_UpdateSITParams(18, 'FROM_NAME',0,'From name',null,9);
	csr.Temp_UpdateSITParams(18, 'FROM_USER_NAME',0,'From user name',null,10);
	csr.Temp_UpdateSITParams(18, 'CRITICAL',1,'Issue critical',null,12);
	csr.Temp_UpdateSITParams(18, 'ISSUE_DETAIL',1,'Issue details',null,13);
	csr.Temp_UpdateSITParams(18, 'ISSUE_ID',1,'Issue ID',null,14);
	csr.Temp_UpdateSITParams(18, 'ISSUE_LABEL',1,'Issue label',null,15);
	csr.Temp_UpdateSITParams(18, 'ISSUE_LINK',1,'Issue link',null,16);
	csr.Temp_UpdateSITParams(18, 'ISSUE_REF',1,'Issue ref',null,17);
	csr.Temp_UpdateSITParams(18, 'ISSUE_STATUS',1,'Issue status',null,18);
	csr.Temp_UpdateSITParams(18, 'ISSUE_TYPE_DESCRIPTION',1,'Issue type',null,19);
	csr.Temp_UpdateSITParams(18, 'ISSUE_URL',1,'Issue URL',null,20);
	csr.Temp_UpdateSITParams(18, 'RAISED_DTM',1,'Issue raised date',null,21);	
	csr.Temp_UpdateSITParams(18, 'PARENT_OBJECT_URL',1,'Parent object URL',null,22);
	csr.Temp_UpdateSITParams(18, 'PRIORITY_DESCRIPTION',1,'Priority',null,23);
	csr.Temp_UpdateSITParams(18, 'PRIORITY_DUE_DATE_OFFSET',1,'Priority offset in days',null,24);
	csr.Temp_UpdateSITParams(18, 'REGION_DESCRIPTION',1,'Region description',null,26);
	csr.Temp_UpdateSITParams(18, 'RELATED_OBJECT_NAME',1,'Related Object Name (e.g Non-Compliance name)',null,27);
	csr.Temp_UpdateSITParams(18, 'SHEET_LABEL',1,'Sheet label',null,28);
	csr.Temp_UpdateSITParams(18, 'SHEET_URL',1,'Sheet URL',null,29);
	csr.Temp_UpdateSITParams(18, 'HOST',0,'Site web address',null,30);
	csr.Temp_UpdateSITParams(18, 'TO_EMAIL',0,'To e-mail',null,31);
	csr.Temp_UpdateSITParams(18, 'TO_FRIENDLY_NAME',0,'To friendly name',null,32);
	csr.Temp_UpdateSITParams(18, 'TO_NAME',0,'To full name',null,33);
	csr.Temp_UpdateSITParams(18, 'TO_USER_NAME',0,'To user name',null,34);
END;
/

--60	Issues due to expire (reminder)
BEGIN
	csr.Temp_UpdateSITParams(60, 'ASSIGNED_TO',1,'Assigned to',null,0);
	csr.Temp_UpdateSITParams(60, 'ASSIGNED_TO_USER_SID',1,'Assigned to user SID',null,1);
	csr.Temp_UpdateSITParams(60, 'DUE_DTM',1,'Issue due date',null,13);
	csr.Temp_UpdateSITParams(60, 'FROM_EMAIL',0,'From e-mail',null,6);
	csr.Temp_UpdateSITParams(60, 'FROM_FRIENDLY_NAME',0,'From friendly name',null,7);
	csr.Temp_UpdateSITParams(60, 'FROM_NAME',0,'From name',null,9);
	csr.Temp_UpdateSITParams(60, 'FROM_USER_NAME',0,'From user name',null,10);
	csr.Temp_UpdateSITParams(60, 'CRITICAL',1,'Issue critical',null,12);
	csr.Temp_UpdateSITParams(60, 'ISSUE_DETAIL',1,'Issue details',null,13);
	csr.Temp_UpdateSITParams(60, 'ISSUE_ID',1,'Issue ID',null,14);
	csr.Temp_UpdateSITParams(60, 'ISSUE_LABEL',1,'Issue label',null,15);
	csr.Temp_UpdateSITParams(60, 'ISSUE_LINK',1,'Issue link',null,16);
	csr.Temp_UpdateSITParams(60, 'ISSUE_REF',1,'Issue ref',null,17);
	csr.Temp_UpdateSITParams(60, 'ISSUE_STATUS',1,'Issue status',null,18);
	csr.Temp_UpdateSITParams(60, 'ISSUE_TYPE_LABEL',1,'Issue type',null,19);
	csr.Temp_UpdateSITParams(60, 'ISSUE_URL',1,'Issue URL',null,20);
	csr.Temp_UpdateSITParams(60, 'RAISED_DTM',1,'Issue raised date',null,21);	
	csr.Temp_UpdateSITParams(60, 'PRIORITY_DESCRIPTION',1,'Priority',null,23);
	csr.Temp_UpdateSITParams(60, 'PRIORITY_DUE_DATE_OFFSET',1,'Priority offset in days',null,24);
	csr.Temp_UpdateSITParams(60, 'ISSUE_REGION',1,'Region name',null,27);
	csr.Temp_UpdateSITParams(60, 'HOST',0,'Site web address',null,30);
	csr.Temp_UpdateSITParams(60, 'TO_EMAIL',0,'To e-mail',null,31);
	csr.Temp_UpdateSITParams(60, 'TO_FRIENDLY_NAME',0,'To friendly name',null,32);
	csr.Temp_UpdateSITParams(60, 'TO_NAME',0,'To full name',null,33);
	csr.Temp_UpdateSITParams(60, 'TO_USER_NAME',0,'To user name',null,34);
END;
/

--61	Issues expired (overdue)
BEGIN
	csr.Temp_UpdateSITParams(61, 'ASSIGNED_TO',1,'Assigned to',null,0);
	csr.Temp_UpdateSITParams(61, 'ASSIGNED_TO_USER_SID',1,'Assigned to user SID',null,1);
	csr.Temp_UpdateSITParams(61, 'DUE_DTM',1,'Issue due date',null,13);
	csr.Temp_UpdateSITParams(61, 'FROM_EMAIL',0,'From e-mail',null,6);
	csr.Temp_UpdateSITParams(61, 'FROM_FRIENDLY_NAME',0,'From friendly name',null,7);
	csr.Temp_UpdateSITParams(61, 'FROM_NAME',0,'From name',null,9);
	csr.Temp_UpdateSITParams(61, 'FROM_USER_NAME',0,'From user name',null,10);
	csr.Temp_UpdateSITParams(61, 'CRITICAL',1,'Issue critical',null,12);
	csr.Temp_UpdateSITParams(61, 'ISSUE_DETAIL',1,'Issue details',null,13);
	csr.Temp_UpdateSITParams(61, 'ISSUE_ID',1,'Issue ID',null,14);
	csr.Temp_UpdateSITParams(61, 'ISSUE_LABEL',1,'Issue label',null,15);
	csr.Temp_UpdateSITParams(61, 'ISSUE_LINK',1,'Issue link',null,16);
	csr.Temp_UpdateSITParams(61, 'ISSUE_REF',1,'Issue ref',null,17);
	csr.Temp_UpdateSITParams(61, 'ISSUE_STATUS',1,'Issue status',null,18);
	csr.Temp_UpdateSITParams(61, 'ISSUE_TYPE_LABEL',1,'Issue type',null,19);
	csr.Temp_UpdateSITParams(61, 'ISSUE_URL',1,'Issue URL',null,20);
	csr.Temp_UpdateSITParams(61, 'RAISED_DTM',1,'Issue raised date',null,21);
	csr.Temp_UpdateSITParams(61, 'PRIORITY_DESCRIPTION',1,'Priority',null,23);
	csr.Temp_UpdateSITParams(61, 'PRIORITY_DUE_DATE_OFFSET',1,'Priority offset in days',null,24);
	csr.Temp_UpdateSITParams(61, 'ISSUE_REGION',1,'Region name',null,27);
	csr.Temp_UpdateSITParams(61, 'HOST',0,'Site web address',null,30);
	csr.Temp_UpdateSITParams(61, 'TO_EMAIL',0,'To e-mail',null,31);
	csr.Temp_UpdateSITParams(61, 'TO_FRIENDLY_NAME',0,'To friendly name',null,32);
	csr.Temp_UpdateSITParams(61, 'TO_NAME',0,'To full name',null,33);
	csr.Temp_UpdateSITParams(61, 'TO_USER_NAME',0,'To user name',null,34);
END;
/

BEGIN
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The issue details' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'ISSUE_DETAIL';
	   
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'Link to the issue' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'ISSUE_LINK';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The description of the issue priority' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'PRIORITY_DESCRIPTION';
	   
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The number of days that the priority is offset from the date the issue was submitted' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'PRIORITY_DUE_DATE_OFFSET';
		   
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The e-mail address of the user the alert is being sent from' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'FROM_EMAIL';
	   
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The friendly name of the user the alert is being sent from' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'FROM_FRIENDLY_NAME';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The user name of the user the alert is being sent from' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'FROM_USER_NAME';
	  
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'A link to the sheet that the issue relates to' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'SHEET_URL';
	  
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'A link to the full screen issue details page' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'ISSUE_URL';
	  
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'PARENT_OBJECT_URL';
	  
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The name of the sheet that the issue relates to' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'SHEET_LABEL';
	  
	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The name of the user the alert is being sent from' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'FROM_NAME';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The SID of the user that the issue is currently assigned to' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'ASSIGNED_TO_USER_SID';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The date the issue was raised' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'RAISED_DTM';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The status of the issue' 
	 WHERE help_text LIKE '#help_text%' 
	   AND field_name = 'ISSUE_STATUS';

	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The issue ID' 
	 WHERE std_alert_type_id IN (17, 18, 60, 61)
	   AND field_name = 'ISSUE_ID';	   

 	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The issue label' 
	 WHERE std_alert_type_id IN (17, 18, 60, 61)
	   AND field_name = 'ISSUE_LABEL';
	   
 	UPDATE CSR.STD_ALERT_TYPE_PARAM 
	   SET help_text = 'The region associated with the issue, if any.' 
	 WHERE std_alert_type_id IN (17, 18, 60, 61)
	   AND field_name = 'REGION_DESCRIPTION';
	   
END;
/

-- sync positions up
BEGIN
	FOR r IN (
	  SELECT field_name, std_alert_type_id, ROW_NUMBER() OVER(PARTITION BY std_alert_type_id ORDER BY description ASC) rn 
	    FROM (
		SELECT display_pos,field_name, std_alert_type_id, description
		  FROM csr.std_alert_type_param 
		 WHERE std_alert_type_id IN (17, 18, 60, 61)
	  )  
	)
	LOOP
	  UPDATE csr.std_alert_type_param 
	     SET display_pos = r.rn 
	   WHERE std_alert_type_id = r.std_alert_type_id 
	     AND field_name = r.field_name;
	END LOOP;
END;
/

DROP PROCEDURE csr.Temp_UpdateSITParams;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_pkg

@../alert_body
@../issue_body

@update_tail

