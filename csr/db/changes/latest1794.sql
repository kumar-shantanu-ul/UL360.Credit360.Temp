-- Please update version.sql too -- this keeps clean builds in sync
define version=1794
@update_header

BEGIN
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description)
		VALUES (12, 'Rejected questionnaire request', NULL);
END;
/

/* add column to message */
ALTER TABLE CHAIN.MESSAGE ADD RE_INVITATION_ID NUMBER(10, 0) NULL;

ALTER TABLE CHAIN.MESSAGE ADD CONSTRAINT FK_MESSAGE_INVITATION_ID
    FOREIGN KEY (APP_SID, RE_INVITATION_ID)
    REFERENCES CHAIN.INVITATION(APP_SID, INVITATION_ID)
;

/* add column to tt */
ALTER TABLE CHAIN.TT_MESSAGE_SEARCH ADD RE_INVITATION_ID NUMBER(10, 0) NULL;

/* add column into message views */
CREATE OR REPLACE VIEW CHAIN.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.re_invitation_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index
;

CREATE OR REPLACE VIEW CHAIN.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_invitation_id, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.completed_dtm,
			m.completed_by_user_sid, r.recipient_id, r.to_company_sid, r.to_user_sid, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl,
		(
			SELECT message_id, MAX(refresh_index) max_refresh_index
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY message_id
		) mlr
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND mlr.message_id = mrl.message_id
	   AND mlr.max_refresh_index = mrl.refresh_index;
	   

/* Chain messages */
DECLARE
	v_dfn_id					chain.message_definition.message_definition_id%TYPE;
BEGIN
	/* Set company href=null on relationship_activated_between for supplier */
	UPDATE chain.default_message_param
	   SET href = null
	 WHERE param_name = 'reCompany'
	   AND message_definition_id = (
			SELECT message_definition_id
			  FROM chain.message_definition_lookup
			 WHERE primary_lookup_id = 500 --RELATIONSHIP_ACTIVATED
			   AND secondary_lookup_id = 2 -- SUPPLIER_MSG
	);

	/* 200 INVITATION_SENT => SUPPLIER_MSG  */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 200 /*INVITATION_SENT*/, 2 /* SUPPLIER_MSG */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reUser} of {reCompany}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', NULL, 'background-icon faded-supplier-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reInvitation', LOWER('reInvitation'), '{reInvitationId}', NULL, NULL);
		
		
	/* 201 INVITATION_ACCEPTED => SUPPLIER_MSG  */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 201 /*INVITATION_SENT*/, 2 /* SUPPLIER_MSG */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reCompany} accepted by {reUser}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', NULL, 'background-icon faded-supplier-icon');
	
	
	/* 202 INVITATION_REJECTED => SUPPLIER_MSG  */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 202 /*INVITATION_REJECTED*/, 2 /* SUPPLIER_MSG */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reCompany} rejected by {reUser}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon delete-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', NULL, 'background-icon faded-supplier-icon');
	
	
	/* 203 INVITATION_EXPIRED => SUPPLIER_MSG  */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 203 /*INVITATION_EXPIRED*/, 2 /* SUPPLIER_MSG */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reCompany} expired.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', NULL, 'background-icon faded-supplier-icon');

END;
/
   
	   
@../chain/message_pkg
@../chain/chain_link_pkg
@../chain/helper_pkg
@../chain/company_type_pkg

@../chain/message_body
@../chain/chain_link_body
@../chain/helper_body
@../chain/company_type_body
@../chain/company_body
@../chain/invitation_body

@update_tail