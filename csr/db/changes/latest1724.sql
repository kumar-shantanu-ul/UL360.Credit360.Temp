-- Please update version.sql too -- this keeps clean builds in sync
define version=1724
@update_header

BEGIN
	/*capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_ON_BEHALF_OF, chain.temp_chain_pkg.VIEW_RELATIONSHIPS, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);*/
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'View relationships between A and B', 3, 1, 1);


	/*capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_ON_BEHALF_OF, chain.temp_chain_pkg.ADD_REMOVE_RELATIONSHIPS, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);*/
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Add remove relationships between A and B', 3, 1, 1);

END;
/

--Schema changes for messages
ALTER TABLE CHAIN.MESSAGE ADD RE_SECONDARY_COMPANY_SID NUMBER(10, 0);

ALTER TABLE CHAIN.MESSAGE ADD CONSTRAINT FK_SECONDARY_COMP_SID 
	FOREIGN KEY (APP_SID, RE_SECONDARY_COMPANY_SID)
	REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

CREATE OR REPLACE VIEW CHAIN.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id,
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
			m.re_company_sid, m.re_secondary_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.completed_dtm,
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
	   AND mlr.max_refresh_index = mrl.refresh_index
;


ALTER TABLE CHAIN.TT_MESSAGE_SEARCH ADD RE_SECONDARY_COMPANY_SID	NUMBER(10);
	
DECLARE
	v_dfn_id					chain.message_definition.message_definition_id%TYPE;
BEGIN
	--############## ACTIVATION #####################
	
	--500 RELATIONSHIP_ACTIVATED FOR PURCHASER
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 500 /*RELATIONSHIP_ACTIVATED*/, 1/*PURCHASER_MSG*/)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'A relationship with {reCompany} has been established.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	
	
	--500 RELATIONSHIP_ACTIVATED FOR SUPPLIER
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 500 /*RELATIONSHIP_ACTIVATED*/, 2/*SUPPLIER_MSG*/)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'A relationship with {reCompany} has been established.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	
	
	--502 RELATIONSHIP_ACTIVATED_BETWEEN
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 502 /*RELATIONSHIP_ACTIVATED_BETWEEN*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'A relationship of {reCompany} with {reSecondaryCompany} has been established.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
	
	--############## DE-ACTIVATION #####################
	
	--501 RELATIONSHIP_DELETED FOR PURCHASER
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 501 /*RELATIONSHIP_DELETED*/, 1/*PURCHASER_MSG*/)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'The relationship with {reCompany} has been deleted.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	
	
	--501 RELATIONSHIP_DELETED FOR SUPPLIER
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 501 /*RELATIONSHIP_DELETED*/, 2/*SUPPLIER_MSG*/)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'The relationship with {reCompany} has been deleted.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	
	
	--503 RELATIONSHIP_DELETED_BETWEEN
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 503 /*RELATIONSHIP_DELETED_BETWEEN*/, 0 /* NONE_IMPLIED */)
	RETURNING message_definition_id INTO v_dfn_id;
	
	INSERT INTO chain.default_message_definition (message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
	VALUES (v_dfn_id, 'The relationship of {reCompany} with {reSecondaryCompany} has been deleted.', 1 /*NEUTRAL*/, 3 /*ALWAYS_REPEAT*/, 2 /*COMPANY_ADDRESS*/, 0 /*NO_COMPLETION*/, NULL, NULL, 'background-icon info-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reCompany', LOWER('reCompany'), '{reCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}', 'background-icon faded-company-icon');
	
	INSERT INTO chain.default_message_param(message_definition_id, param_name, lower_param_name, value, href, css_class)
	VALUES (v_dfn_id, 'reSecondaryCompany', LOWER('reSecondaryCompany'), '{reSecondaryCompanyName}', '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}', 'background-icon faded-company-icon');
	
END;
/
	
@..\chain\chain_pkg
@..\chain\message_pkg
@..\chain\company_pkg
@..\chain\type_capability_pkg

@..\chain\message_body
@..\chain\company_body
@..\chain\type_capability_body
@..\chain\invitation_body
@..\chain\setup_body

@update_tail