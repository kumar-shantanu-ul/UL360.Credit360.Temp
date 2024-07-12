-- Please update version.sql too -- this keeps clean builds in sync
define version=2589
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
	   AND table_name = 'CMS_IMP_CLASS'
	   AND column_name = 'EMAIL_ON_PARTIAL';
	
	IF v_col_check = 0 THEN
		DBMS_OUTPUT.PUT_LINE('Add new column');
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CMS_IMP_CLASS ADD EMAIL_ON_PARTIAL VARCHAR2(2048)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already added.');
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.cms_imp_result SET label = 'Success' WHERE cms_imp_result_id = 0;
UPDATE csr.cms_imp_result SET label = 'Partial success' WHERE cms_imp_result_id = 1;
UPDATE csr.cms_imp_result SET label = 'Fail' WHERE cms_imp_result_id = 2;
-- critical failure, but without sounding so alarming
UPDATE csr.cms_imp_result SET label = 'Fail (unexpected error)' WHERE cms_imp_result_id = 3;
UPDATE csr.cms_imp_result SET label = 'Not attempted' WHERE cms_imp_result_id = 4;

-- *** Packages ***
@../cms_data_imp_pkg
@../cms_data_imp_body
@../enable_body
@../csr_app_body
@../../../aspen2/cms/db/calc_xml_body

@update_tail