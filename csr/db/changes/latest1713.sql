-- Please update version.sql too -- this keeps clean builds in sync
define version=1713
@update_header

ALTER TABLE CHAIN.COMPANY_TYPE ADD (
	USE_USER_ROLE       NUMBER(1, 0),
    USER_ROLE_SID       NUMBER(10, 0),
    CONSTRAINT CHK_CT_USE_USER_ROLE_BOOL CHECK (USE_USER_ROLE IN (0, 1))
);

ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP ADD (
    USE_USER_ROLES       NUMBER(1, 0),
    CONSTRAINT CHK_CTR_USE_USER_ROLES_BOOL CHECK (USE_USER_ROLES IN (0, 1))
);  


UPDATE CHAIN.COMPANY_TYPE SET USE_USER_ROLE = 0;
UPDATE CHAIN.COMPANY_TYPE_RELATIONSHIP SET USE_USER_ROLES = 0;

ALTER TABLE CHAIN.COMPANY_TYPE MODIFY USE_USER_ROLE DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.COMPANY_TYPE_RELATIONSHIP MODIFY USE_USER_ROLES DEFAULT 0 NOT NULL;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_COMPANY_USER
(
	COMPANY_SID					NUMBER(10) NOT NULL,
	USER_SID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_TT_COMPANY_USER PRIMARY KEY (COMPANY_SID, USER_SID)
)
ON COMMIT DELETE ROWS;

grant select, insert, update, delete on chain.TT_COMPANY_USER to csr;
grant select, references, update on chain.company_type to csr;
grant select, references on chain.company_type_relationship to csr;
grant select, references on chain.company_group to csr;
grant select, references on chain.company_group_type to csr;
grant select on chain.supplier_relationship to csr;

ALTER TABLE CHAIN.COMPANY_TYPE ADD CONSTRAINT FK_ROLE_CT_USER_ROLE 
    FOREIGN KEY (APP_SID, USER_ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

@..\supplier_pkg
@..\chain\company_type_pkg
@..\chain\chain_link_pkg
@..\supplier_body
@..\chain\company_type_body
@..\chain\company_body
@..\chain\chain_link_body

DECLARE
	v_csr_sid 						security.security_pkg.T_SID_ID;
	v_user_creator_daemon_sid 		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin;

	FOR r IN (
		SELECT UNIQUE app_sid, host FROM chain.v$chain_host
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		v_user_creator_daemon_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Users/UserCreatorDaemon');
		v_csr_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'csr');
		
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.Acl_pkg.GetDACLIDForSID(v_csr_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, csr.csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/


@update_tail
