-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.customer_file_upload_type_opt (
	app_sid				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	file_extension		VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			DEFAULT 0 NOT NULL,
	CONSTRAINT pk_customer_file_upld_type_opt PRIMARY KEY (app_sid, file_extension),
	CONSTRAINT chk_file_upld_type_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_type_file_ext CHECK (file_extension = LOWER(TRIM(file_extension)))
);

CREATE TABLE csr.customer_file_upload_mime_opt (
	app_sid				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	mime_type			VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			DEFAULT 0 NOT NULL,
	CONSTRAINT pk_customer_file_upld_mime_opt PRIMARY KEY (app_sid, mime_type),
	CONSTRAINT chk_file_upld_mime_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_mime_file_ext CHECK (mime_type = LOWER(TRIM(mime_type)))
);

CREATE TABLE csrimp.customer_file_upload_type_opt (
	csrimp_session_id	NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	file_extension		VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			NOT NULL,
	CONSTRAINT pk_customer_file_upld_type_opt PRIMARY KEY (csrimp_session_id, file_extension),
	CONSTRAINT chk_file_upld_type_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_type_file_ext CHECK (file_extension = LOWER(TRIM(file_extension)))
);

CREATE TABLE csrimp.customer_file_upload_mime_opt (
	csrimp_session_id	NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	mime_type			VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			NOT NULL,
	CONSTRAINT pk_customer_file_upld_mime_opt PRIMARY KEY (csrimp_session_id, mime_type),
	CONSTRAINT chk_file_upld_mime_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_mime_file_ext CHECK (mime_type = LOWER(TRIM(mime_type)))
);

-- Alter tables
ALTER TABLE csr.customer_file_upload_type_opt
  ADD CONSTRAINT fk_file_upld_type_opt_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);

ALTER TABLE csr.customer_file_upload_mime_opt
  ADD CONSTRAINT fk_file_upld_mime_opt_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);

ALTER TABLE csrimp.customer_file_upload_type_opt
  ADD CONSTRAINT fk_file_upld_type_opt_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

ALTER TABLE csrimp.customer_file_upload_mime_opt
  ADD CONSTRAINT fk_file_upld_mime_opt_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
  
-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.customer_file_upload_type_opt TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.customer_file_upload_mime_opt TO web_user;
GRANT SELECT, INSERT ON csr.customer_file_upload_type_opt TO csrimp;
GRANT SELECT, INSERT ON csr.customer_file_upload_mime_opt TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED		EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS	EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_FILE_UPLOAD_TYPE_OPT',
		policy_name     => 'CUST_FILE_UPLD_TYPE_OPT_POL', 
		function_schema => 'CSR',
		policy_function => 'AppSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED		EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS	EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_FILE_UPLOAD_MIME_OPT',
		policy_name     => 'CUST_FILE_UPLD_MIME_OPT_POL', 
		function_schema => 'CSR',
		policy_function => 'AppSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/


DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'CUSTOMER_FILE_UPLOAD_TYPE_OPT',
		policy_name     => 'CUST_FILE_UPLD_TYPE_OPT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'CUSTOMER_FILE_UPLOAD_MIME_OPT',
		policy_name     => 'CUST_FILE_UPLD_MIME_OPT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/

-- Data

-- ** New package grants **

-- *** Packages ***
@..\customer_pkg
@..\customer_body
@..\schema_pkg
@..\schema_body
@..\csr_app_body;
@..\csrimp\imp_body;

@update_tail
