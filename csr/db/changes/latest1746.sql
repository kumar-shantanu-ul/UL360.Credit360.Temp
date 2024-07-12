-- Please update version.sql too -- this keeps clean builds in sync
define version=1746
@update_header

BEGIN		
	
	 --add it in chain\basedata\csr_alerts.sql
	 --Chain supplier survey alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5015,
		'Chain supplier survey',
		'A supplier survey has been shared with supplier after the supplier submits the on-board questionnaire.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain supplier survey',
				send_trigger = 'A supplier survey has been shared with supplier.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5015;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'LINK', 'Link', 'A hyperlink to the supplier survey page', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'EXPIRATION', 'Expiration', 'The date the supplier survey expires', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'SITE_NAME', 'Site name', 'The site name', 5);
		
		
	-- Chain questionnaire reminder
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5016,
		'Questionnaire reminder',
		'A questionnaire is not shared (not submitted) and it is past the reminder date.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire reminder',
				send_trigger = 'A questionnaire is not shared (not submitted) and it is past the reminder date.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5016;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire edit link', 'A hyperlink to the questionnaire edit page', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'DUE_DATE', 'Expiration', 'The due date of the questionnaire', 7);
		
		
	-- Chain questionnaire overdue alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5017,
		'Questionnaire overdue',
		'A questionnaire is not shared (not submitted) and it is past the due date.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire overdue',
				send_trigger = 'A questionnaire is not shared (not submitted) and it is past the due date.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5017;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire edit link', 'A hyperlink to the questionnaire edit page', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'DUE_DATE', 'Expiration', 'The due date of the questionnaire', 7);
	
END;
/

GRANT SELECT ON csr.temp_alert_batch_run TO CHAIN;

--add reminder-offset to questionnaire type, default is null 
ALTER TABLE chain.questionnaire_type ADD REMINDER_OFFSET_DAYS NUMBER(10, 0);

--add enable reminder flag
ALTER TABLE chain.questionnaire_type ADD ENABLE_REMINDER_ALERT NUMBER(1, 0);
UPDATE chain.questionnaire_type SET ENABLE_REMINDER_ALERT = 0;
ALTER TABLE chain.questionnaire_type MODIFY ENABLE_REMINDER_ALERT DEFAULT 0 NOT NULL;

--add chech constraint
ALTER TABLE chain.questionnaire_type ADD CONSTRAINT CC_ENABLE_REMINDER_OFFSET
	CHECK (ENABLE_REMINDER_ALERT = 0 OR (ENABLE_REMINDER_ALERT = 1 AND REMINDER_OFFSET_DAYS IS NOT NULL));

--add enable overdue flag
ALTER TABLE chain.questionnaire_type ADD ENABLE_OVERDUE_ALERT NUMBER(1, 0);
UPDATE chain.questionnaire_type SET ENABLE_OVERDUE_ALERT = 0;
ALTER TABLE chain.questionnaire_type MODIFY ENABLE_OVERDUE_ALERT DEFAULT 0 NOT NULL;

--add reminder_sent_dtm, overdue_sent_dtm in questionnaire_share
ALTER TABLE chain.questionnaire_share ADD REMINDER_SENT_DTM DATE NULL;
ALTER TABLE chain.questionnaire_share ADD OVERDUE_SENT_DTM DATE NULL;

--add enable_qnnaire_reminder_alerts in customer options
ALTER TABLE chain.customer_options ADD ENABLE_QNNAIRE_REMINDER_ALERTS NUMBER(1, 0);
UPDATE chain.customer_options SET ENABLE_QNNAIRE_REMINDER_ALERTS = 0;
ALTER TABLE chain.customer_options MODIFY ENABLE_QNNAIRE_REMINDER_ALERTS DEFAULT 0 NOT NULL;

--Create table qnnaire_share_alert_log
CREATE TABLE CHAIN.QNNAIRE_SHARE_ALERT_LOG(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_SHARE_ID    NUMBER(10, 0)    NOT NULL,
	ALERT_SENT_DTM		 	  DATE NOT NULL,	
	STD_ALERT_TYPE_ID		  NUMBER(10, 0) NOT NULL,
	USER_SID			  	  NUMBER(10, 0) NOT NULL,
    CONSTRAINT PK_QNNAIRE_SHARE_ALERT_LOG PRIMARY KEY (APP_SID, QUESTIONNAIRE_SHARE_ID, ALERT_SENT_DTM, STD_ALERT_TYPE_ID, USER_SID )
)
;

ALTER TABLE CHAIN.QNNAIRE_SHARE_ALERT_LOG ADD CONSTRAINT RefQUESTIONNAIRE_SHARE1150
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_SHARE_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_SHARE(APP_SID, QUESTIONNAIRE_SHARE_ID)
;

ALTER TABLE CHAIN.QNNAIRE_SHARE_ALERT_LOG ADD CONSTRAINT FK_REF_USER_QSAL_USER  
    FOREIGN KEY (APP_SID, USER_SID)
     REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

/* add it to cross_schema_constraints */
ALTER TABLE CHAIN.QNNAIRE_SHARE_ALERT_LOG ADD CONSTRAINT FK_REF_STD_ALRT_TYP_QSAL_ALRT 
    FOREIGN KEY (STD_ALERT_TYPE_ID)
     REFERENCES CSR.STD_ALERT_TYPE(STD_ALERT_TYPE_ID)
;

--create view chain.v$questionnaire_share
CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qs.reminder_sent_dtm, qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss, v$company s
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = s.company_sid
	   AND q.company_sid = qs.qnr_owner_company_sid
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND q.questionnaire_id = qs.questionnaire_id
	   AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	   AND qsle.share_status_id = ss.share_status_id
	   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
;

 @../chain/questionnaire_pkg
 @../chain/questionnaire_body
 
@update_tail