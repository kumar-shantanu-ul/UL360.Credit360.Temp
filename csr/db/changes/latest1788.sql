-- Please update version.sql too -- this keeps clean builds in sync
define version=1788
@update_header

-- Database changes from HEINEKEN SPM PHASE 3 UAT

-- FB32388 CHG003-ID092-Assigning Users
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
     VALUES (1035,'Heineken SPM secondary region picker','HeinekenSpm.Portlets.SecondaryRegionPicker', EMPTY_CLOB(),'/heinekenspm/site/portal/portlets/SecondaryRegionPicker.js');

-- FB32651 CHG003-ID122-3A Add UI and persistence for the new setting
-- add column CSR.CUSTOMER.LOCK_PREVENTS_EDITING
DECLARE
	v_count	number(10);
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_tab_cols WHERE owner = 'CSR' AND table_name = 'CUSTOMER' AND column_name = 'LOCK_PREVENTS_EDITING';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.customer ADD (LOCK_PREVENTS_EDITING NUMBER(1, 0) DEFAULT 0 NOT NULL)';
	END IF;
END;
/

@..\csr_data_pkg
@..\csr_data_body
@..\csr_app_body

@update_tail