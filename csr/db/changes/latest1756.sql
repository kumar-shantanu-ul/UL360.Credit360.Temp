-- Please update version.sql too -- this keeps clean builds in sync
define version=1756
@update_header

/* Default share questionnaire with on behalf company (if exists) when a supplier accepts invitation */
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD DEFAULT_SHARE_QNR_WITH_ON_BHLF NUMBER(1, 0) NULL;
UPDATE CHAIN.CUSTOMER_OPTIONS SET DEFAULT_SHARE_QNR_WITH_ON_BHLF = 1;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY DEFAULT_SHARE_QNR_WITH_ON_BHLF NUMBER(1, 0) DEFAULT 1 NOT NULL;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD ALLOW_ADD_EXISTING_CONTACTS NUMBER(1, 0) NULL;
UPDATE CHAIN.CUSTOMER_OPTIONS SET ALLOW_ADD_EXISTING_CONTACTS = 1;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY ALLOW_ADD_EXISTING_CONTACTS NUMBER(1, 0) DEFAULT 1 NOT NULL;

BEGIN
	/*capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_ON_BEHALF_OF, chain.temp_chain_pkg.QNR_INV_ON_BEHLF_TO_EXIST_COMP, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);*/
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Send questionnaire invitations on behalf of to existing company', 3, 1, 1);

END;
/

DECLARE 
	v_dfn_id	chain.message_definition_lookup.message_definition_id%type;
BEGIN
	-- Show text instead of links for de-activation
	--501 RELATIONSHIP_DELETED FOR PURCHASER
	SELECT message_definition_id
	  INTO v_dfn_id
	  FROM chain.message_definition_lookup
	 WHERE primary_lookup_id = 501/*RELATIONSHIP_DELETED*/
	   AND secondary_lookup_id = 1; /*PURCHASER_MSG*/
	 
	UPDATE chain.default_message_param
	   SET HREF = NULL
	 WHERE message_definition_id = v_dfn_id;
	 
	--501 RELATIONSHIP_DELETED FOR SUPPLIER
	SELECT message_definition_id
	  INTO v_dfn_id
	  FROM chain.message_definition_lookup
	 WHERE primary_lookup_id = 501/*RELATIONSHIP_DELETED*/
	   AND secondary_lookup_id = 2; /*PURCHASER_MSG*/
	   
	UPDATE chain.default_message_param
	   SET HREF = NULL
	 WHERE message_definition_id = v_dfn_id;

END;
/

@../chain/chain_pkg
@../chain/chain_link_pkg
@../chain/helper_pkg
@../chain/company_type_pkg
@../chain/type_capability_pkg

@../chain/chain_link_body
@../chain/helper_body
@../chain/company_body
@../chain/company_type_body
@../chain/invitation_body
@../chain/type_capability_body
	
@update_tail