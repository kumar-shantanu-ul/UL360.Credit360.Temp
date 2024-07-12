-- Please update version.sql too -- this keeps clean builds in sync
define version=981
@update_header

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD (
    REQUIRES_REVIEW          NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_QNR_TYP_REQ_REV_0OR1 CHECK (REQUIRES_REVIEW IN (0,1))
);


-- Add std alert type
BEGIN
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5013,
		'Self-Assessment Questionnaire',
		'A self-assessment questionnaire is sent to a supplier.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Self-Assessment Questionnaire',
				send_trigger = 'A self-assessment questionnaire is sent to a supplier.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5013;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'QUESTIONNAIRE_DESCRIPTION', 'Questionnaire description', 'The questionnaire description', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
END;
/

-- Add message definition
DECLARE
	v_dfn_id					chain.message_definition.message_definition_id%TYPE;
BEGIN
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 306 /*QNR_SUBMITTED_NO_REVIEW*/, 1 /*PURCHASER_MSG*/)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'Questionnaire {reQuestionnaire} submitted by {reCompany}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 1 /*COMPANY_USER_ADDRESS*/, 1 /*ACKNOWLEDGE*/, 'Acknowledged by {completedByUserFullName} {relCompletedDtm}', NULL, 'background-icon questionnaire-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reQuestionnaire', LOWER('reQuestionnaire'), '{reQuestionnaireName}', '{reQuestionnaireViewUrl}', 'background-icon faded-questionnaire-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-supplier-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'companySid', LOWER('companySid'), '{reCompanySid}', NULL, NULL);
END;
/

@..\chain\chain_pkg
@..\chain\company_user_pkg
@..\chain\questionnaire_pkg
@..\chain\chain_link_pkg
@..\chain\invitation_pkg
@..\chain\questionnaire_pkg

@..\chain\company_user_body
@..\chain\questionnaire_body
@..\chain\message_body
@..\chain\chain_link_body
@..\chain\invitation_body
@..\chain\questionnaire_body

@update_tail
