-- Please update version.sql too -- this keeps clean builds in sync
define version=1076
@update_header

grant select,insert,update,delete on csr.deleg_ind_form_expr to csrimp;
grant select,insert,update,delete on csr.form_expr to csrimp;

DROP TYPE CSR.T_FLOW_STATE_TRANS_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS					NUMBER(10),
		ID					NUMBER(10),	
		FROM_STATE_ID		NUMBER(10),
		TO_STATE_ID			NUMBER(10),
		ASK_FOR_COMMENT		VARCHAR2(16),
		VERB				VARCHAR2(255),
		LOOKUP_KEY			VARCHAR2(255),
		HELPER_SP			VARCHAR2(255),
		ROLE_SIDS			VARCHAR2(2000),
		ATTRIBUTES_XML		XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/

@..\flow_pkg
@..\flow_body

@..\donations\donation_pkg

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('View user audit log', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('View Delegation link from Sheet', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Auto show sheet value popup', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
@update_tail
