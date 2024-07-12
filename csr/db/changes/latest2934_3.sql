-- Please update version.sql too -- this keeps clean builds in sync
define version=2934
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'CUSTOMER'
	   AND column_name = 'REMOVE_ROLES_ON_ACCOUNT_EXPIR';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER ADD REMOVE_ROLES_ON_ACCOUNT_EXPIR NUMBER(1,0) DEFAULT 0 NOT NULL';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/

DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CSR_USER ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0) DEFAULT 0 NOT NULL';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/

DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'BATCH_JOB_STRUCTURE_IMPORT'
	   AND column_name = 'REMOVE_FROM_ROLES_INACTIVATED';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.BATCH_JOB_STRUCTURE_IMPORT ADD REMOVE_FROM_ROLES_INACTIVATED NUMBER(1,0) DEFAULT 0';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/

DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CUSTOMER'
	   AND column_name = 'REMOVE_ROLES_ON_ACCOUNT_EXPIR';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CUSTOMER ADD REMOVE_ROLES_ON_ACCOUNT_EXPIR NUMBER(1,0)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/

DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'USER_TABLE'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.USER_TABLE ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../../../security/db/oracle/user_pkg
@../../../security/db/oracle/user_body
@../role_pkg
@../role_body
@../csr_user_pkg
@../csr_user_body
@../customer_pkg
@../customer_body
@../structure_import_pkg
@../structure_import_body
@../../../security/db/oracle/accountpolicyhelper_body

@../schema_body
@../csrimp/imp_body

@update_tail
