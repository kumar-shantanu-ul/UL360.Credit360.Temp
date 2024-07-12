PROMPT >> Defining Capabilities

BEGIN
	INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (1, 'Company Details' , 0, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (2, 'Business relationships' , 1, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (3, 'Users' , 2, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (4, 'Survey invitation' , 3, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (5, 'Onboarding and relationships' , 4, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (6, 'Advanced' , 5, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (7, 'Other' , 6, 1);
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.capability_type (capability_type_id, description, container) VALUES (chain.chain_pkg.CT_COMMON, 'Common checks that are not specifically for a company or a supplier', NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.capability_type (capability_type_id, description, container) VALUES (chain.chain_pkg.CT_COMPANY, 'Company specific capabilities', chain.chain_pkg.COMPANY);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.capability_type (capability_type_id, description, container) VALUES (chain.chain_pkg.CT_SUPPLIERS, 'Supplier specific capabilities', chain.chain_pkg.SUPPLIERS);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.capability_type (capability_type_id, description, container) VALUES (chain.chain_pkg.CT_ON_BEHALF_OF, 'Checks for performing actions on behalf of another company', NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- logon as builtin admin, no app
	security.user_pkg.logonadmin;

	-- Register and apply our capabilities
	-- COMPANY
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ROOT, chain.chain_pkg.COMPANY, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.COMPANY, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.COMPANY, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.COMPANY, chain.chain_pkg.PENDING_GROUP, security.security_pkg.PERMISSION_READ);

	-- SUPPLIERS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ROOT, chain.chain_pkg.SUPPLIERS, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.SUPPLIERS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.SUPPLIERS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);

	-- QUESTIONNAIRE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.QUESTIONNAIRE, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.QUESTIONNAIRE, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.QUESTIONNAIRE, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUESTIONNAIRE, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUESTIONNAIRE, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	
	-- MANAGE QUESTIONNAIRE SECURITY
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY, chain.chain_pkg.BOOLEAN_PERMISSION);
		
	-- SEND_QUESTIONNAIRE_INVITE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE, chain.chain_pkg.ADMIN_GROUP);
	
	-- SEND_COMPANY_INVITE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_COMPANY_INVITE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	-- SEND_INVITE_ON_BEHALF_OF
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_INVITE_ON_BEHALF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	-- SUBMIT_QUESTIONNAIRE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.SUBMIT_QUESTIONNAIRE, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SUBMIT_QUESTIONNAIRE, chain.chain_pkg.ADMIN_GROUP);
	
	-- QUERY_QUESTIONNAIRE_ANSWERS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUERY_QUESTIONNAIRE_ANSWERS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	-- RESET_PASSWORD
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.RESET_PASSWORD, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.RESET_PASSWORD, chain.chain_pkg.ADMIN_GROUP);

	-- CREATE_USER
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.CREATE_USER, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER, chain.chain_pkg.ADMIN_GROUP);
	
	--COMPANY_USER
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.COMPANY_USER, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_USER, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_USER, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_USER, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	
	--Add existing user to companies
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.ADD_USER_TO_COMPANY, chain.chain_pkg.BOOLEAN_PERMISSION);
	
	-- PROMOTE_USER
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.PROMOTE_USER, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PROMOTE_USER, chain.chain_pkg.ADMIN_GROUP);
	
	-- REMOVE_USER_FROM_COMPANY
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.REMOVE_USER_FROM_COMPANY, chain.chain_pkg.BOOLEAN_PERMISSION);

	--Manage user
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.MANAGE_USER, chain.chain_pkg.BOOLEAN_PERMISSION);

	-- APPROVE_QUESTIONNAIRE	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.APPROVE_QUESTIONNAIRE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.APPROVE_QUESTIONNAIRE, chain.chain_pkg.ADMIN_GROUP);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.APPROVE_QUESTIONNAIRE, chain.chain_pkg.USER_GROUP);

	-- EVENTS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.EVENTS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EVENTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EVENTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EVENTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EVENTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_WRITE);

	-- ACTIONS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.ACTIONS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ACTIONS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ACTIONS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ACTIONS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ACTIONS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_WRITE);	
	
	-- TASKS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.TASKS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.TASKS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.TASKS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.TASKS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.TASKS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_WRITE);	

	-- METRICS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.METRICS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.METRICS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.METRICS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.METRICS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.METRICS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_WRITE);	
	
	-- PRODUCTS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.PRODUCTS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);	
	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS_AS_SUPPLIER, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.CREATE_PRODUCTS, chain.chain_pkg.BOOLEAN_PERMISSION);

	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIERS, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_PRODUCT_SUPPLIER, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.MANAGE_PRODUCT_CERT_REQS, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.PRODUCT_CERTIFICATIONS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIER_CERTS, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.PRODUCT_METRIC_VAL, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRD_SUPP_METRIC_VAL, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);

	-- COMPONENTS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.COMPONENTS, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPONENTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPONENTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPONENTS, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPONENTS, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);

	-- PRODUCT CODE TYPES
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.PRODUCT_CODE_TYPES, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CODE_TYPES, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CODE_TYPES, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CODE_TYPES, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CODE_TYPES, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	
	-- UPLOADED FILE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ);
	
	-- CHANGE_SUPPLIER_FOLLOWER
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER, chain.chain_pkg.ADMIN_GROUP);
	
	-- EDIT_OWN_FOLLOWER_STATUS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS, chain.chain_pkg.USER_GROUP);

	-- The following capabilities have no default grants
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.SPECIFY_USER_NAME, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.SETUP_STUB_REGISTRATION, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.CREATE_QUESTIONNAIRE_TYPE, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.IS_TOP_COMPANY, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_NEWSFLASH, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.RECEIVE_USER_TARGETED_NEWS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	
	--NEW CAPABILITIES
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_WITHOUT_INVIT, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITHOUT_INVITE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITH_INVITE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_NEW_COMPANY, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_EXIST_COMPAN, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--RELATIONSHIPS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.VIEW_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.ADD_REMOVE_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--ON BEHALF
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.QNR_INVITE_ON_BEHALF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.QNR_INV_ON_BEHLF_TO_EXIST_COMP, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--REQUEST QUESTIONNAIRE FROM COMPANY
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--SUPPLIER_WITH_NO_RELATIONSHIP
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIER_NO_RELATIONSHIP, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_RELATIONSHIP, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--EDIT USERS EMAIL ADDRESS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS, chain.chain_pkg.BOOLEAN_PERMISSION); 

	--EDIT OWN EMAIL ADDRESS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_OWN_EMAIL_ADDRESS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);	
	
	--REQUEST AUDIT
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_AUDIT_REQUESTS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--CREATE SUPPLIER AUDIT
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_SUPPLIER_AUDITS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--CREATE SUPPLIER AUDIT ON BEHALF
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.CREATE_SUPPL_AUDIT_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--CREATE SUBSIDIARY ON BEHALF OF
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.CREATE_SUBSIDIARY_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--CREATE SUBSIDIARY ON BEHALF OF
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--VIEW SUPPLIER AUDITS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_SUPPLIER_AUDITS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	--VIEW EXTRA DETAILS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_EXTRA_DETAILS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	-- MANAGE ACTIVITIES
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_ACTIVITIES, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	-- COMPANY SCORES
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.COMPANY_SCORES, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG, chain.chain_pkg.BOOLEAN_PERMISSION);
	
	-- COMPANY_TAGS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.COMPANY_TAGS, chain.chain_pkg.SPECIFIC_PERMISSION);
	
	-- MANAGE WORKFLOWS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.MANAGE_WORKFLOWS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	-- AUDIT_QUESTIONNAIRE_RESPONSES
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.AUDIT_QUESTIONNAIRE_RESPONSES, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);	

	-- BUSINESS RELATIONSHIPS
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_BUSINESS_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.UPDATE_BUSINESS_REL_PERIODS, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_TO_BUS_REL_REVERSED, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_BUS_REL_REVERSED, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPDATE_BUS_REL_PERDS_REVERSED, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	--Filters
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_COMPANY_AUDITS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_CMS_COMPANIES, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);	
	
	--Reject questionnaire
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REJECT_QUESTIONNAIRE, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	-- Activate / Deactivate companies
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.DEACTIVATE_COMPANY, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);

	-- View country risk levels
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_COUNTRY_RISK_LEVELS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY);

	--View certifications
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.VIEW_CERTIFICATIONS, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.ALT_COMPANY_NAMES, chain.chain_pkg.SPECIFIC_PERMISSION);

	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.SET_PRIMARY_PRCHSR, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
END;
/

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Chain edit site global file groups', 0);
END;
/

BEGIN
	-- Copied by hand from EMU.
	UPDATE chain.capability SET description = 'Ability to edit details in the "Company" tab on the Supply Chain Company Details page.' WHERE capability_name = 'Company';
	UPDATE chain.capability SET description = 'View and make change to details in the Company Details page.' WHERE capability_name = 'Suppliers';
	UPDATE chain.capability SET description = 'Give users a user name to log in with that is separate from their email address.' WHERE capability_name = 'Specify user name';
	UPDATE chain.capability SET description = 'View and edit any questionnaire associated with the company.' WHERE capability_name = 'Questionnaire';
	UPDATE chain.capability SET description = 'Submit a questionnaire associated with the user''s company.' WHERE capability_name = 'Submit questionnaire';
	UPDATE chain.capability SET description = 'Add actions (issues) to individual questions on a supplier survey. The Survey Answer issue type must also be enabled.' WHERE capability_name = 'Query questionnaire answers';
	UPDATE chain.capability SET description = 'Managing read, write, approve, submit permissions on a survey for a particular user.' WHERE capability_name = 'Manage questionnaire security';
	UPDATE chain.capability SET description = 'Create a survey that can be sent to suppliers.' WHERE capability_name = 'Create questionnaire type';
	UPDATE chain.capability SET description = 'Register a user without sending them an invitation.' WHERE capability_name = 'Setup stub registration';
	UPDATE chain.capability SET description = 'Reset a user''s password.' WHERE capability_name = 'Reset password';
	UPDATE chain.capability SET description = 'Create a user from the Company users page.' WHERE capability_name = 'Create user';
	UPDATE chain.capability SET description = 'Ability to add users to the company.' WHERE capability_name = 'Add user to company';
	UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Events';
	UPDATE chain.capability SET description = 'Ability to read and create new actions on supply chain specific pages that don''t result from data collection (e.g. audits and surveys).' WHERE capability_name = 'Actions';
	UPDATE chain.capability SET description = 'Whether users can view or edit tasks the company has to do. Tasks have replaced "actions" and "events".' WHERE capability_name = 'Tasks';
	UPDATE chain.capability SET description = 'Whether you can edit any company metrics.' WHERE capability_name = 'Metrics';
	UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Products';
	UPDATE chain.capability SET description = 'Relates to whether you can add products a supplier sells to a top company.' WHERE capability_name = 'Components';
	UPDATE chain.capability SET description = 'Allows users to promote a company user to a company administrator and (combined with "Remove user from company") remove administrators from the company on the Company users page. Also provides access to the "User''s roles" checkboxes on the page, allowing them to view/assign roles to the user.' WHERE capability_name = 'Promote user';
	UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Product code types';
	UPDATE chain.capability SET description = 'This controls who can view and edit company folders and documents in the Supply Chain document library.' WHERE capability_name = 'Uploaded file';
	UPDATE chain.capability SET description = 'Ability to edit another company user''s email address on the Company users page.' WHERE capability_name = 'Edit user email address';
	UPDATE chain.capability SET description = 'Ability to edit your own email address on the Supply Chain My details page and the Company users page.' WHERE capability_name = 'Edit own email address';
	UPDATE chain.capability SET description = 'View supplier audits on a "Supplier Audits" tab in the supplier profile page.' WHERE capability_name = 'View supplier audits';
	UPDATE chain.capability SET description = 'Ability to view/edit any extra details in yellow in the supplier details tab.' WHERE capability_name = 'View company extra details';
	UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Manage activities';
	UPDATE chain.capability SET description = 'Allows users to view and edit the "User account is active" and "Send email alerts" checkboxes when editing user details, controlling whether the user account is active and whether the user receives email alerts.' WHERE capability_name = 'Manage user';
	UPDATE chain.capability SET description = 'Read access allows the user to view alternative names for the company. These are displayed under "Additional information" on the Company details tab of the company''s profile page (in this case, the Manage companies page). Read/write access allows the user to view and edit alternative names for the company.' WHERE capability_name = 'Alternative company names';
	UPDATE chain.capability SET description = 'Specific to Carbon Trust Hotspotter tool.' WHERE capability_name = 'CT Hotspotter';
	UPDATE chain.capability SET description = 'The company is at the highest level of the hierarchy and can view all suppliers.' WHERE capability_name = 'Is top company';
	UPDATE chain.capability SET description = 'Enable the Supplier Registration Wizard for sending questionnaires to new companies (as part of an invitation) or existing companies.' WHERE capability_name = 'Send questionnaire invitation';
	UPDATE chain.capability SET description = 'Create a new company with an invitation but without a questionnaire.' WHERE capability_name = 'Send company invitation';
	UPDATE chain.capability SET description = 'Deprecated - replaced by tertiary relationships' WHERE capability_name = 'Send invitation on behalf of';
	UPDATE chain.capability SET description = 'Ability to send news items.' WHERE capability_name = 'Send newsflash';
	UPDATE chain.capability SET description = 'Ability to view news items.' WHERE capability_name = 'Receive user-targeted newsflash';
	UPDATE chain.capability SET description = 'Approve a questionnaire submitted by another company.' WHERE capability_name = 'Approve questionnaire';
	UPDATE chain.capability SET description = 'Allow users to cancel a survey that has been sent to a supplier. Once canceled, the supplier can no longer access the survey to edit or submit it.' WHERE capability_name = 'Reject questionnaire';
	UPDATE chain.capability SET description = 'Change the user who receives supplier messages (if you only want certain users as contacts for certain suppliers) and add or remove users from the Supplier followers plugin.' WHERE capability_name = 'Change supplier follower';
	UPDATE chain.capability SET description = 'Must be true for the workflow transition buttons to be displayed.' WHERE capability_name = 'Manage workflows';
	UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the supplier.' WHERE capability_name = 'Create company as subsidiary';
	UPDATE chain.capability SET description = 'Create a new company user without an invitation (i.e. from the Company users page or the Company invitation wizard). If false, the Company invitation wizard does not allow you to search for existing companies or add contacts.' WHERE capability_name = 'Create company without invitation.';
	UPDATE chain.capability SET description = 'Create a new company user with an invitation.' WHERE capability_name = 'Create company user with invitation';
	UPDATE chain.capability SET description = 'Remove a user from the company so that they are no longer a member of the company and no longer have the permissions associated with that company type. This does not delete a user from the system. In order to remove administrator users, the "Promote user" permission is also required.' WHERE capability_name = 'Remove user from company';
	UPDATE chain.capability SET description = 'Create a new company by sending an invitation with a questionnaire.' WHERE capability_name = 'Send questionnaire invitation to new company';
	UPDATE chain.capability SET description = 'Send a questionnaire to an existing company.' WHERE capability_name = 'Send questionnaire invitation to existing company';
	UPDATE chain.capability SET description = 'See secondary suppliers that you have no relationship with.' WHERE capability_name = 'Supplier with no established relationship';
	UPDATE chain.capability SET description = 'Create a company relationship with an existing company without sending a company or questionnaire invitation. The "Supplier with no established relationship" must also be set to "Read" on the company type relationship. Users with the permission can search for existing companies that they don''t have a relationship with from the Supplier list tab/plugin on the Manage Companies page. ' WHERE capability_name = 'Create relationship with supplier';
	UPDATE chain.capability SET description = 'View the relationship between the secondary and tertiary company on the "Relationships" plugin.' WHERE capability_name = 'View relationships between A and B';
	UPDATE chain.capability SET description = 'Add or remove a relationship between a secondary and a tertiary company from the "Relationships" plugin.' WHERE capability_name = 'Add remove relationships between A and B';
	UPDATE chain.capability SET description = 'Ability to ask an auditor to carry out an audit on a supplier without specifying/creating the audit (requires its own page). The Auditor company must also have the “Create supplier audit” permission on the Auditor > Auditee company type relationship.' WHERE capability_name = 'Request audits';
	UPDATE chain.capability SET description = 'Create a 2nd party audit (i.e. top company auditing a supplier).' WHERE capability_name = 'Create supplier audit';
	UPDATE chain.capability SET description = 'If true, users can filter by "Supplier of" and "Related by <business relationship type>" on the Supplier list plugin.' WHERE capability_name = 'Filter on company relationships';
	UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for audits on companies.' WHERE capability_name = 'Filter on company audits';
	UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for the fields of CMS tables on the company record. The CMS table must include company columns pointing to actual company SIDs. A flag on the CMS table is also required (this is enabled automatically but may be switched off).' WHERE capability_name = 'Filter on cms companies';
	UPDATE chain.capability SET description = 'Ability to create business relationships. Business relationship types must also be configured.' WHERE capability_name = 'Create business relationships';
	UPDATE chain.capability SET description = 'Ability to add the company to business relationships.' WHERE capability_name = 'Add company to business relationships';
	UPDATE chain.capability SET description = 'View the company''s business relationships. Requires the Business relationships plugin/tab.' WHERE capability_name = 'View company business relationships';
	UPDATE chain.capability SET description = 'Ability to update the time periods on a business relationship.' WHERE capability_name = 'Update company business relationship periods';
	UPDATE chain.capability SET description = 'Make a company active or inactive. When a company is made inactive, users of that company cannot log in and new surveys, audits, delegation forms, logging forms and activities cannot be created. Existing data can be viewed.' WHERE capability_name = 'Deactivate company';
	UPDATE chain.capability SET description = 'Allows the secondary company in the company relationship to create a business relationship with the primary company.' WHERE capability_name = 'Add company to business relationships (supplier => purchaser)';
	UPDATE chain.capability SET description = 'Allows the secondary company to view business relationships with the primary company. Requires the business relationships plugin/tab.' WHERE capability_name = 'View company business relationships (supplier => purchaser)';
	UPDATE chain.capability SET description = 'Allows the secondary company to update the time periods on a business relationship between them and the primary company.' WHERE capability_name = 'Update company business relationship periods (supplier => purchaser)';
	UPDATE chain.capability SET description = 'Send a questionnaire to a supplier (new or existing) on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of';
	UPDATE chain.capability SET description = 'Send a questionnaire to an existing supplier on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of to existing company';
	UPDATE chain.capability SET description = 'Create an audit on the tertiary company on behalf of the secondary company. For example, if the indirect relationship were "Top Company (Third party auditor => Supplier), this permission would allow the top company to create an audit between the third party auditor and supplier.' WHERE capability_name = 'Create supplier audit on behalf of';
	UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the tertiary company.' WHERE capability_name = 'Create subsidiary on behalf of';
	UPDATE chain.capability SET description = 'View subsidiaries/sub-companies of the secondary company.' WHERE capability_name = 'View subsidiaries on behalf of';
	UPDATE chain.capability SET description = 'Allows a holding company to ask any company in the system to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an existing company in the database';
	UPDATE chain.capability SET description = 'Allows a holding company to ask a company that it has a direct company relationship with to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an established relationship';
	UPDATE chain.capability SET description = 'Read access allows the user to view company scores. Scores are displayed in the score header on the company''s profile page, and in columns on the supplier list. Read/write access allows the user to view and edit company scores, if the score type is configured to allow the score to be set manually.' WHERE capability_name = 'Company scores';
	UPDATE chain.capability SET description = 'View changes to the company score. Requires the Score header for company management page header plugin.' WHERE capability_name = 'View company score log';
	UPDATE chain.capability SET description = 'Compare submissions of the same survey by a single company.' WHERE capability_name = 'Audit questionnaire responses';
	UPDATE chain.capability SET description = 'Used if there is a separate tab used to show any tags associated with a company (not relevant if tags are shown on the same tab as the company details).' WHERE capability_name = 'Company tags';
	UPDATE chain.capability SET description = 'Enables the user to follow or stop following companies through the Supplier follower plugin.' WHERE capability_name = 'Edit own follower status';
	UPDATE chain.capability SET description = 'View certifications for companies on the supplier list page. This permission allows users to see the following information about the most recent audit of the type(s) specified in the certification: audit type, valid from, valid to, and audit result.' WHERE capability_name = 'View certifications';
	UPDATE chain.capability SET description = 'Set the purchaser company in a relationship as the primary purchaser for that supplier.' WHERE capability_name = 'Set primary purchaser in a relationship between A and B';
END;
/

BEGIN
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 1
	WHERE capability_name IN ('Company', 'Suppliers', 'Alternative company names', 'Company scores', 'Company tags', 'View company extra details', 'View company score log');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 2
	WHERE capability_name IN ('Add company to business relationships', 'Update company business relationship periods', 'View company business relationships', 'Filter on company relationships', 'Create business relationships', 'View company business relationships (supplier => purchaser)', 'Update company business relationship periods (supplier => purchaser)', 'Add company to business relationships (supplier => purchaser)');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 3
	WHERE capability_name IN ('Edit own email address', 'Add user to company', 'Company user', 'Create user', 'Edit user email address', 'Manage user', 'Promote user', 'Remove user from company', 'Reset password', 'Specify user name');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 4
	WHERE capability_name IN ('Send questionnaire invitations on behalf of', 'Create questionnaire type', 'Manage questionnaire security', 'Questionnaire', 'Submit questionnaire', 'Approve questionnaire', 'Create company user with invitation', 'Reject questionnaire', 'Request questionnaire from an established relationship', 'Request questionnaire from an existing company in the database', 'Send questionnaire invitation', 'Send questionnaire invitation to existing company', 'Send questionnaire invitation to new company', 'Audit questionnaire responses', 'Create questionnaire type', 'Manage questionnaire security', 'Query questionnaire answers', 'Questionnaire', 'Setup stub registration', 'Submit questionnaire', 'Send questionnaire invitations on behalf of to existing company');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 5
	WHERE capability_name IN ('Change supplier follower', 'Create company as subsidiary', 'Create company user without invitation', 'Create company without invitation', 'Create relationship with supplier', 'Edit own follower status', 'Supplier with no established relationship', 'Deactivate company');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 6
	WHERE capability_name IN ('Send newsflash', 'Send company invitation', 'Send invitation on behalf of', 'Add supplier to products', 'Components', 'Create products', 'CT Hotspotter', 'Events', 'Manage activities', 'Manage product certification requirements', 'Metrics', 'Product certifications', 'Product code types', 'Product metric values', 'Product supplier certifications', 'Product supplier metric values', 'Product suppliers', 'Products', 'Tasks', 'Add product suppliers of suppliers', 'Product supplier certifications of suppliers', 'Product supplier metric values of suppliers', 'Product suppliers of suppliers', 'Filter on company audits', 'Filter on cms companies', 'Products as supplier', 'Product supplier metric values as supplier', 'Receive user-targeted newsflash', 'Product metric values as supplier');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 7
	WHERE capability_name IN ('Is top company', 'Actions', 'Uploaded file', 'View certifications', 'View country risk levels', 'Manage workflows', 'Actions', 'Create supplier audit', 'Request audits', 'Uploaded file', 'View certifications', 'View supplier audits', 'Add remove relationships between A and B', 'Create subsidiary on behalf of', 'Create supplier audit on behalf of', 'Set primary purchaser in a relationship between A and B', 'View relationships between A and B', 'View subsidiaries on behalf of');
END;
/
