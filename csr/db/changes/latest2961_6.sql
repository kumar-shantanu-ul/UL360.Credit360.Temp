-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

--fixing wrongly added column on csrimp.user_table
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'USER_TABLE'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.USER_TABLE DROP COLUMN REMOVE_ROLES_ON_DEACTIVATION';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column not existing.');
	END IF;
END;
/

-- adding missing column
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CSR_USER ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0)';
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
	   AND column_name = 'USER_REF';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CSR_USER ADD USER_REF VARCHAR2(255)';
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CSR.UK_USER_REF ON CSR.CSR_USER(APP_SID,LOWER(NVL(USER_REF, ''CR360_'' || CSR_USER_SID)))';
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
	   AND table_name = 'CSR_USER'
	   AND column_name = 'USER_REF';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CSR_USER ADD USER_REF VARCHAR2(255)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
--C:\cvs\csr\db\create_views.sql ln838
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm,
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria, cu.user_ref
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body
@../user_report_body
@../delegation_body
@../schema_body
@../csrimp/imp_body
@../structure_import_pkg
@../structure_import_body


@update_tail
