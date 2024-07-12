-- Please update version.sql too -- this keeps clean builds in sync
define version=1621
@update_header

-- CSR updates
DECLARE
	v_count		number;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences 
	 WHERE sequence_name = 'NON_COMP_DEFAULT_ID_SEQ'
	   AND sequence_owner = 'CSR' ;

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.NON_COMP_DEFAULT_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences 
	 WHERE sequence_name = 'NON_COMP_DEFAULT_ISSUE_ID_SEQ'
	   AND sequence_owner = 'CSR' ;

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.NON_COMP_DEFAULT_ISSUE_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
	END IF;
END;
/

CREATE TABLE CSR.NON_COMP_DEFAULT (
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10, 0) NOT NULL,
	LABEL						VARCHAR(255) NOT NULL,
	DETAIL						CLOB,
	CONSTRAINT PK_NON_COMP_DEFAULT PRIMARY KEY (APP_SID, NON_COMP_DEFAULT_ID)
);

ALTER TABLE CSR.NON_COMP_DEFAULT ADD CONSTRAINT FK_NON_COMP_DEFAULT_CUSTOMER 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID);
	
CREATE INDEX CSR.IDX_NON_COMP_DEFAULT_CUSTOMER ON CSR.NON_COMP_DEFAULT(APP_SID);

CREATE TABLE CSR.NON_COMP_DEFAULT_ISSUE (
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	NON_COMP_DEFAULT_ISSUE_ID	NUMBER(10, 0) NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10, 0) NOT NULL,	
	LABEL						VARCHAR(2048) NOT NULL,
	DESCRIPTION					CLOB,
	CONSTRAINT PK_NON_COMP_DEFAULT_ISSUE PRIMARY KEY (APP_SID, NON_COMP_DEFAULT_ISSUE_ID)
);

ALTER TABLE CSR.NON_COMP_DEFAULT_ISSUE ADD CONSTRAINT FK_NC_DFLT_ISSUE_NC_DFLT
    FOREIGN KEY (APP_SID, NON_COMP_DEFAULT_ID)
    REFERENCES CSR.NON_COMP_DEFAULT(APP_SID, NON_COMP_DEFAULT_ID);
	
CREATE INDEX CSR.IDX_NC_DFLT_ISSUE_NC_DFLT ON CSR.NON_COMP_DEFAULT_ISSUE(APP_SID, NON_COMP_DEFAULT_ID);

CREATE TABLE CSR.AUDIT_TYPE_NON_COMP_DEFAULT (
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10, 0) NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_AUDIT_TYPE_NON_COMP_DEFAULT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, NON_COMP_DEFAULT_ID)
);

ALTER TABLE CSR.AUDIT_TYPE_NON_COMP_DEFAULT ADD CONSTRAINT FK_AUDIT_TYPE_NC_DFLT_NC_DFLT
    FOREIGN KEY (APP_SID, NON_COMP_DEFAULT_ID)
    REFERENCES CSR.NON_COMP_DEFAULT(APP_SID, NON_COMP_DEFAULT_ID);
	
CREATE INDEX CSR.IDX_AUDIT_TYPE_NC_DFLT_NC_DFLT ON CSR.AUDIT_TYPE_NON_COMP_DEFAULT(APP_SID, NON_COMP_DEFAULT_ID);

ALTER TABLE CSR.AUDIT_TYPE_NON_COMP_DEFAULT ADD CONSTRAINT FK_AUDIT_TYPE_NC_AUDIT_TYPE
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
    REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID);
	
CREATE INDEX CSR.IDX_AUDIT_TYPE_NC_AUDIT_TYPE ON CSR.AUDIT_TYPE_NON_COMP_DEFAULT(APP_SID, INTERNAL_AUDIT_TYPE_ID);

-- RLS
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CSR',
		    object_name     => 'NON_COMP_DEFAULT',
		    policy_name     => 'NON_COMP_DEFAULT_POLICY',
		    function_schema => 'CSR',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
	
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CSR',
		    object_name     => 'NON_COMP_DEFAULT_ISSUE',
		    policy_name     => 'NON_COMP_DEFAULT_ISSUE_POLICY',
		    function_schema => 'CSR',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
	
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CSR',
		    object_name     => 'AUDIT_TYPE_NON_COMP_DEFAULT',
		    policy_name     => 'AUDIT_TYPE_NON_COMP_DEF_POLICY',
		    function_schema => 'CSR',
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

ALTER TABLE CSR.NON_COMPLIANCE ADD FROM_NON_COMP_DEFAULT_ID NUMBER(10, 0);

ALTER TABLE CSR.NON_COMPLIANCE ADD CONSTRAINT FK_NON_COMP_DEFAULT
	FOREIGN KEY (APP_SID, FROM_NON_COMP_DEFAULT_ID)
	REFERENCES CSR.NON_COMP_DEFAULT (APP_SID, NON_COMP_DEFAULT_ID);
	
CREATE INDEX CSR.IDX_NON_COMP_DEFAULT ON CSR.NON_COMPLIANCE(APP_SID, FROM_NON_COMP_DEFAULT_ID);

-- CSRIMP
CREATE TABLE CSRIMP.NON_COMP_DEFAULT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	NON_COMP_DEFAULT_ID				NUMBER(10, 0) NOT NULL,
	LABEL							VARCHAR(255) NOT NULL,
	DETAIL							CLOB,
	CONSTRAINT PK_NON_COMP_DEFAULT PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMP_DEFAULT_ID),
	CONSTRAINT FK_NON_COMP_DEFAULT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.NON_COMP_DEFAULT_ISSUE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	NON_COMP_DEFAULT_ISSUE_ID	NUMBER(10, 0) NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10, 0) NOT NULL,	
	LABEL						VARCHAR(2048) NOT NULL,
	DESCRIPTION					CLOB,
	CONSTRAINT PK_NON_COMP_DEFAULT_ISSUE PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMP_DEFAULT_ISSUE_ID),
	CONSTRAINT FK_NON_COMP_DEFAULT_ISSUE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.AUDIT_TYPE_NON_COMP_DEFAULT (
	CSRIMP_SESSION_ID			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10, 0) NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_AUDIT_TYPE_NON_COMP_DEFAULT PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_ID, NON_COMP_DEFAULT_ID),
	CONSTRAINT FK_AUDIT_TYPE_NON_COMP_DEF_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE CSRIMP.NON_COMPLIANCE ADD FROM_NON_COMP_DEFAULT_ID NUMBER(10, 0);

CREATE TABLE csrimp.map_non_comp_default (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_id			NUMBER(10) NOT NULL,
	new_non_comp_default_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default PRIMARY KEY (old_non_comp_default_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default UNIQUE (new_non_comp_default_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEFAULT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_comp_default_issue (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_issue_id	NUMBER(10) NOT NULL,
	new_non_comp_default_issue_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default_issue PRIMARY KEY (old_non_comp_default_issue_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default_issue UNIQUE (new_non_comp_default_issue_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEF_ISSUE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- CSRIMP RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'NON_COMP_DEFAULT',
		policy_name     => 'NON_COMP_DEFAULT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
		
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'NON_COMP_DEFAULT_ISSUE',
		policy_name     => 'NON_COMP_DEFAULT_ISSUE_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
		
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'AUDIT_TYPE_NON_COMP_DEFAULT',
		policy_name     => 'AUDIT_TYPE_NON_COMP_DEFAUL_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
		
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'MAP_NON_COMP_DEFAULT',
		policy_name     => 'MAP_NON_COMP_DEFAULT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
		
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'MAP_NON_COMP_DEFAULT_ISSUE',
		policy_name     => 'MAP_NON_COMP_DEFAULT_ISSUE_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);		
END;
/

-- Grants
grant insert on csr.audit_type_non_comp_default to csrimp;
grant insert on csr.non_comp_default to csrimp;
grant insert on csr.non_comp_default_issue to csrimp;
grant select on csr.non_comp_default_id_seq to csrimp;
grant select on csr.non_comp_default_issue_id_seq to csrimp;
grant select,insert,update,delete on csrimp.audit_type_non_comp_default to web_user;
grant select,insert,update,delete on csrimp.non_comp_default to web_user;
grant select,insert,update,delete on csrimp.non_comp_default_issue to web_user;

-- Packages
@../audit_pkg
@../issue_pkg
@../schema_pkg

@../audit_body
@../issue_body
@../schema_body
@../quick_survey_body
@../csrimp/imp_body

@update_tail