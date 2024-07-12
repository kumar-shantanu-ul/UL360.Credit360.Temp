-- Please update version.sql too -- this keeps clean builds in sync
define version=1707
@update_header

@@latest1707_packages
BEGIN
	security.user_pkg.logonadmin;
	--
	chain.temp_capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_COMMON, chain.temp_chain_pkg.CREATE_COMPANY_WITHOUT_INVIT, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	chain.temp_capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_COMMON, chain.temp_chain_pkg.CREATE_USER_WITHOUT_INVITE, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.temp_capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_COMMON, chain.temp_chain_pkg.CREATE_USER_WITH_INVITE, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);
	
	chain.temp_capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_COMMON, chain.temp_chain_pkg.SEND_QUEST_INV_TO_NEW_COMPANY, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);
	chain.temp_capability_pkg.RegisterCapability(chain.temp_chain_pkg.CT_COMMON, chain.temp_chain_pkg.SEND_QUEST_INV_TO_EXIST_COMPAN, chain.temp_chain_pkg.BOOLEAN_PERMISSION, chain.temp_chain_pkg.IS_SUPPLIER_CAPABILITY);

END;
/

		
/* Add company type_groups*/	
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (
	USE_COMPANY_TYPE_USER_GROUPS     NUMBER(1, 0)--      DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_CO_UCTUG_BOOLEAN CHECK (USE_COMPANY_TYPE_USER_GROUPS IN (0, 1))
);

UPDATE CHAIN.CUSTOMER_OPTIONS SET USE_COMPANY_TYPE_USER_GROUPS = 0;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY USE_COMPANY_TYPE_USER_GROUPS DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.COMPANY_TYPE ADD (
	 USER_GROUP_SID      NUMBER(10, 0)
);

-- this will need to be manually added to \csr\db\chain\cross_schema_constraints.sql
grant references on security.group_table to CHAIN;

ALTER TABLE CHAIN.COMPANY_TYPE ADD CONSTRAINT FK_SEC_GT_CT_USER_GROUP 
	 FOREIGN KEY (USER_GROUP_SID)
	 REFERENCES SECURITY.GROUP_TABLE(SID_ID);


DROP PACKAGE chain.temp_chain_pkg;
DROP PACKAGE chain.temp_capability_pkg;

@../chain/chain_pkg
@../chain/company_type_pkg

@../chain/company_type_body
@../chain/company_body
@../chain/type_capability_body

@update_tail
