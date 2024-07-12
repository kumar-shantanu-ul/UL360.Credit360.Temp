define version=768
@update_header

	ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (REGISTRATION_TERMS_URL VARCHAR2(4000 BYTE));
	ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (REGISTRATION_TERMS_VERSION NUMBER(10,5));
	

	ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (
	  CONSTRAINT REG_TERMS_CHECK
	 CHECK ((registration_terms_url IS NULL AND registration_terms_version IS NULL) OR (registration_terms_url IS NOT NULL AND registration_terms_version IS NOT NULL)));

	ALTER TABLE CHAIN.INVITATION ADD (ACCEPTED_REG_TERMS_VERS NUMBER(10,5));
	ALTER TABLE CHAIN.INVITATION ADD (ACCEPTED_DTM TIMESTAMP(6));

	 
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (9, 'User rejected terms and conditions', NULL);

@..\chain\chain_pkg
@..\chain\invitation_pkg
@..\chain\invitation_body
@..\chain\helper_pkg
@..\chain\helper_body
@..\chain\uninvited_pkg
@..\chain\uninvited_body

	
@update_tail