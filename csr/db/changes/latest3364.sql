-- Please update version.sql too -- this keeps clean builds in sync
define version=3364
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CREDENTIAL_MANAGEMENT';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSRIMP.CREDENTIAL_MANAGEMENT (
							CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,
							CREDENTIAL_ID		NUMBER(10, 0)		NOT NULL,
							LABEL				VARCHAR2(255)		NOT NULL,
							AUTH_TYPE_ID		NUMBER(10, 0)		NOT NULL,
							AUTH_SCOPE_ID		NUMBER(10, 0)		NOT NULL,
							CREATED_DTM			DATE				NOT NULL,
							UPDATED_DTM			DATE				NOT NULL,
							LOGIN_HINT			VARCHAR2(500)
						)';
	END IF;
END;
/


-- Alter tables
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CUSTOMER'
	   AND constraint_name = 'CK_ENABLE_MOBILE_BRANDING';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_ENABLE_MOBILE_BRANDING CHECK (MOBILE_BRANDING_ENABLED IN (0,1))';
	END IF;
END;
/

-- *** Grants ***
grant select,insert, update on csr.credential_management to csrimp;
grant select,insert,update,delete on csrimp.credential_management to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../customer_body
@../schema_body
@../csrimp/imp_body

@update_tail
