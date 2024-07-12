-- Please update version.sql too -- this keeps clean builds in sync
define version=1009
@update_header

CREATE TABLE CSR.ROLE_GRANT(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ROLE_SID          NUMBER(10, 0)    NOT NULL,
    GRANT_ROLE_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_ROLE_GRANT PRIMARY KEY (APP_SID, ROLE_SID, GRANT_ROLE_SID)
)
;

ALTER TABLE CSR.ROLE_GRANT ADD CONSTRAINT FK_ROLE_GRANT_GRANT_ROLE 
    FOREIGN KEY (APP_SID, GRANT_ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE CSR.ROLE_GRANT ADD CONSTRAINT FK_ROLE_GRANT_ROLE 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

CREATE INDEX CSR.IX_ROLE_GRANT_GRANT_ROLE ON CSR.ROLE_GRANT (APP_SID, GRANT_ROLE_SID);
CREATE INDEX CSR.IX_ROLE_GRANT_ROLE ON CSR.ROLE_GRANT(APP_SID, ROLE_SID);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_ROLE_REGION
(
	ROLE_SID	NUMBER(10)	NOT NULL,
	REGION_SID	NUMBER(10)	NOT NULL
) ON COMMIT DELETE ROWS;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ROLE_GRANT',
		policy_name     => 'ROLE_GRANT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

grant select, insert, update, delete on security.group_members to csr;

@../role_pkg
@../role_body

@update_tail
