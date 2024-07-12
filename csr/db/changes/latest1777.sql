-- Please update version.sql too -- this keeps clean builds in sync
define version=1777
@update_header

CREATE OR REPLACE VIEW CHAIN.v$company_admin AS
  SELECT cag.app_sid, cag.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed, vcu.account_enabled
    FROM v$company_admin_group cag, v$chain_user vcu, security.group_members gm
   WHERE cag.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cag.app_sid = vcu.app_sid
     AND cag.admin_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;

BEGIN
	/*capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);*/
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Request questionnaire from an existing company in the database', 0, 1, 1);

	/*capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);*/
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Request questionnaire from an established relationship', 0, 1, 1);

END;
/

BEGIN
	INSERT INTO chain.invitation_type VALUES(5, 'Request questionnaire from an existing company');

END;
/

ALTER TABLE chain.invitation ADD CONSTRAINT CHK_NO_QUEST_INVITATION CHECK (
	invitation_type_id <> 4 OR (
		invitation_type_id = 4 AND 
		from_company_sid IS NOT NULL AND 
		from_user_sid IS NOT NULL
	)
);

ALTER TABLE chain.invitation ADD CONSTRAINT CHK_REQ_QNR_EXISTING_COMPANY CHECK (
	invitation_type_id <> 5 OR (
		invitation_type_id = 5 AND 
		from_company_sid IS NOT NULL AND 
		from_user_sid IS NOT NULL
	)
);

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_ROW AS 
	OBJECT ( 
		COMPANY_SID					NUMBER(10),
		NAME						VARCHAR(1000),
		COUNTRY_NAME				VARCHAR(1000),
		ACTIVE_RELATIONSHIP			NUMBER(1),
		EDITABLE_RELATIONSHIP		NUMBER(1),--Based on capabilities
		COMPANY_TYPE_DESCRIPTION	VARCHAR(1000),
		RELATIONSHIP_ROLE			NUMBER(1) --1 SUPPLIER, 2 PURCHASER
	);
/

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_TABLE AS 
	TABLE OF CHAIN.T_COMPANY_RELATIONSHIP_ROW;
/


--add req_qnr_invitation_landing in customer options
ALTER TABLE chain.customer_options ADD REQ_QNNAIRE_INVITATION_LANDING VARCHAR2(1000) NULL;


BEGIN
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5018,
			'Request Questionnaire Invitation',
			'An existing company questionnaire request invitation has been created',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Request Questionnaire Invitation',
				send_trigger = 'An existing company questionnaire request invitation has been created',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5018;
	END;

	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'QNNAIRE_REQUEST_LINK', 'Link', 'A hyperlink to the questionnaire request invitation landing page', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);

END;
/

DECLARE
	v_dfn_id					chain.message_definition.message_definition_id%TYPE;
BEGIN
	
	/* Invitations between B and C messaging for A */
	/* 210 INVITATION_SENT_FROM_B_TO_C */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 210 /*INVITATION_SENT_FROM_B_TO_C*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent to {reUser} of {reCompany} by {triggerUser} of {reSecondaryCompany}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-supplier-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'triggerUser', LOWER('triggerUser'), '{triggerUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
	
	/* 211 INVITATION_ACCPTED_FROM_B_TO_C  */	
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 211 /*INVITATION_ACCPTED_FROM_B_TO_C*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reSecondaryCompany} accepted by {reUser} from {reCompany}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-supplier-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
	
	/* 212 INVITATION_RJECTED_FROM_B_TO_C */		
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 212 /*INVITATION_RJECTED_FROM_B_TO_C*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reSecondaryCompany} rejected by {reUser} from {reCompany}.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon delete-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-supplier-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
	
	/* 213 INVITATION_EXPIRED_FROM_B_TO_C */
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 213 /*INVITATION_EXPIRED_FROM_B_TO_C*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
		--definition
		INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES (v_dfn_id, 'Invitation sent by {reSecondaryCompany} to {reUser} of {reCompany} has expired.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon invitation-icon');
		
		--params
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reUser', LOWER('reUser'), '{reUserFullName}', NULL, 'background-icon faded-user-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-supplier-icon');
		
		INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
		VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
END;
/
	
@..\chain\chain_pkg
@..\chain\company_type_pkg
@..\chain\company_user_pkg
@..\chain\company_pkg
@..\chain\invitation_pkg
@..\chain\dev_pkg

@..\chain\helper_body
@..\chain\company_type_body
@..\chain\company_user_body
@..\chain\type_capability_body
@..\chain\company_body
@..\chain\invitation_body
@..\chain\dev_body

@update_tail