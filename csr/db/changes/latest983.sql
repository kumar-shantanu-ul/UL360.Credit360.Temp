-- Please update version.sql too -- this keeps clean builds in sync
define version=983
@update_header

CREATE TABLE CSR.CALC_TAG_DEPENDENCY(
    APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_IND_SID			NUMBER(10, 0)	NOT NULL,
    TAG_ID					NUMBER(10, 0)	NOT NULL,
    CONSTRAINT PK_CALC_TAG_DEP PRIMARY KEY (APP_SID, CALC_IND_SID)
)
;

ALTER TABLE CSR.CALC_TAG_DEPENDENCY ADD CONSTRAINT FK_CALC_TAG_DEP_CALC
    FOREIGN KEY (APP_SID, CALC_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.CALC_TAG_DEPENDENCY ADD CONSTRAINT FK_CALC_TAG_DEP_TAG
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CALC_TAG_DEPENDENCY',
		policy_name     => 'CALC_TAG_DEPENDENCY_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../tag_pkg
@../tag_body
@../calc_pkg
@../calc_body

@update_tail