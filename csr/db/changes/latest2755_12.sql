-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD ENABLE_STATUS_LOG NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE_TYPE SET ENABLE_STATUS_LOG = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE MODIFY ENABLE_STATUS_LOG DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD CONSTRAINT CHK_ENABLE_STATUS_LOG_0_1 CHECK (ENABLE_STATUS_LOG IN (0, 1));

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD ENABLE_TRANSITION_ALERT NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE_TYPE SET ENABLE_TRANSITION_ALERT = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE MODIFY ENABLE_TRANSITION_ALERT DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD CONSTRAINT CHK_ENABLE_TRANSITION_ALRT_0_1 CHECK (ENABLE_TRANSITION_ALERT IN (0, 1));

ALTER TABLE CHAIN.QUESTIONNAIRE ADD REJECTED NUMBER(1);
UPDATE CHAIN.QUESTIONNAIRE SET REJECTED = 0;
ALTER TABLE CHAIN.QUESTIONNAIRE MODIFY REJECTED DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.QUESTIONNAIRE ADD CONSTRAINT CHK_REJECTED_0_1 CHECK (REJECTED IN (0, 1));

ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE_TYPE ADD ENABLE_STATUS_LOG NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE_TYPE ADD ENABLE_TRANSITION_ALERT NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_QUESTIONNAIRE ADD REJECTED NUMBER(1);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
--C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, c.description component_description, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, NVL(q.description, qt.name) description, qt.db_class, qt.group_name, qt.position, qt.security_scheme_id, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm,
		   qt.enable_status_log, qt.enable_transition_alert, q.rejected
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs, component c
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND q.component_id = c.component_id(+)
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;

CREATE OR REPLACE VIEW chain.v$qnr_action_capability
AS
	SELECT questionnaire_action_id, description,
		CASE WHEN questionnaire_action_id = 1 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 2 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 3 THEN 'Submit questionnaire'
			 WHEN questionnaire_action_id = 4 THEN 'Approve questionnaire' 
			 WHEN questionnaire_action_id = 5 THEN 'Manage questionnaire security' 
			 WHEN questionnaire_action_id = 6 THEN 'Reject questionnaire' 
		END capability_name,
		CASE WHEN questionnaire_action_id = 1 THEN 1 --security_pkg.PERMISSION_READ -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 2 --security_pkg.PERMISSION_WRITE -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
		END permission_set,
		CASE WHEN questionnaire_action_id = 1 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 6 THEN 1 -- BOOLEAN
		END permission_type
		  FROM chain.questionnaire_action;
	
	
-- *** Data changes ***
-- RLS

-- Data
--Temp sproc
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
END;
/

BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  		/* CT_COMMON*/
		in_capability	=> 'Reject questionnaire' /* chain.chain_pkg.REJECT_QUESTIONNAIRE */, 
		in_perm_type	=> 1, 			/* BOOLEAN_PERMISSION */
		in_is_supplier 	=> 1
	);
	
END;
/

--TODO: using create actions

DROP PROCEDURE chain.Temp_RegisterCapability;

BEGIN
	UPDATE chain.questionnaire
	   SET rejected = 1
	 WHERE questionnaire_id IN (
		SELECT DISTINCT questionnaire_id
		  FROM chain.questionnaire_share qs
		  JOIN chain.qnr_share_log_entry qsle ON qs.questionnaire_share_id = qsle.questionnaire_share_id
		 WHERE qsle.share_status_id = 15 --rejected	 
	 );
END;
/

-- returned questionnaire notification
BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5027,
	'Returned questionnaire notification',
	'A questionnaire is returned.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE csr.std_alert_type SET
			description = 'Returned questionnaire notification',
			send_trigger = 'A questionnaire is returned.',
			sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		WHERE std_alert_type_id = 5027;
END;
/

--add reject questionnaire as action

BEGIN
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (6, 'Cancel questionnaire');
	
	/* only procurer can reject/cancel questionnaire */
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 6); -- PROCURER, CANCEL
	
	--add a new scheme
	INSERT INTO CHAIN.QUESTIONNAIRE_SECURITY_SCHEME (SECURITY_SCHEME_ID, DESCRIPTION) VALUES (4, 'PROCURER: USER VIEW, USER EDIT, USER SUBMIT, USER APPROVE, USER GRANT, USER REJECT; SUPPLIER: USER VIEW, USER EDIT, USER SUBMIT');
	
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 1); /* PROCURER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 2); /* PROCURER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 3); /* PROCURER: USER SUBMIT */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 4); /* PROCURER: USER APPROVE*/
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 5); /* PROCURER: USER GRANT*/
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 1, 6); /* PROCURER: USER REJECT*/

	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 1); /* SUPPLIER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 2); /* SUPPLIER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (4, 2, 2, 3); /* SUPPLIER: USER SUBMIT */
END;
/


INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'SUBJECT', 'Subject', 'The subject', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire link', 'A hyperlink to the questionnaire', 12);	
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'USER_NOTES', 'Transition comments', 'Notes added by the user that returned the questionnaire', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5027, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 14);

-- ** New package grants **

-- *** Packages ***
@../chain/chain_pkg
@../chain/questionnaire_pkg
@../chain/questionnaire_security_pkg

@../schema_body
@../csrimp/imp_body
@../chain/questionnaire_body
@../chain/invitation_body
@../quick_survey_body
@../chain/questionnaire_security_body

@update_tail
