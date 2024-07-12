-- Please update version.sql too -- this keeps clean builds in sync
define version=945
@update_header

ALTER TABLE CSR.IND_VALIDATION_RULE ADD (
	TYPE                VARCHAR2(1)       DEFAULT 'E' NOT NULL,
	CONSTRAINT CHK_IND_VALID_RULE_TYPE CHECK (TYPE IN ('E','X','W'))
);

ALTER TABLE CSR.IND_VALIDATION_RULE MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'IND_VALIDATION_RULE',
		policy_name     => 'IND_VALIDATION_RULE_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

-- junk
DROP TABLE CSR.IND_ASSERTION;


@..\indicator_pkg
@..\indicator_body
@..\delegation_body

@update_tail