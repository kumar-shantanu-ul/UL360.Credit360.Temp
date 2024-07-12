-- Please update version too -- this keeps clean builds in sync
define version=1857
@update_header
 
ALTER TABLE CHAIN.TT_USER_DETAILS ADD EMAIL VARCHAR2(256);  

-- TABLE: CHAIN.CHAIN_USER_EMAIL_ADDRESS_LOG 
CREATE TABLE CHAIN.CHAIN_USER_EMAIL_ADDRESS_LOG(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    USER_SID             NUMBER(10, 0)    NOT NULL,
    EMAIL                VARCHAR2(256)    NOT NULL,
    LAST_MODIFIED_DTM    DATE             DEFAULT SYSDATE NOT NULL,
    MODIFIED_BY_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL
)
;

ALTER TABLE CHAIN.CHAIN_USER_EMAIL_ADDRESS_LOG ADD CONSTRAINT RefCHAIN_USER1174 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE CHAIN.CHAIN_USER_EMAIL_ADDRESS_LOG ADD CONSTRAINT RefCHAIN_USER1175 
    FOREIGN KEY (APP_SID, MODIFIED_BY_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;


-- RLS for CHAIN_USER_EMAIL_ADDRESS_LOG
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CHAIN',
		    object_name     => 'CHAIN_USER_EMAIL_ADDRESS_LOG',
		    policy_name     => 'CHAIN_USER_EM_ADDR_LOG_POLICY',
		    function_schema => 'CHAIN',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
END;
/

 

BEGIN
	security.user_pkg.logonadmin;
	
	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS, chain.chain_pkg.BOOLEAN_PERMISSION); */
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Edit user email address', 1, 1, 0);
	
	INSERT INTO chain.capability (capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Edit user email address', 2, 1, 1);
	
	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_OWN_EMAIL_ADDRESS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_NOT_SUPPLIER_CAPABILITY); */
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Edit own email address', 1, 1, 0);
	
END;
/


@../chain/chain_pkg
@../chain/company_user_pkg

@../chain/company_user_body

@update_tail
