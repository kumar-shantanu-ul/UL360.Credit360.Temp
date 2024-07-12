-- Please update version.sql too -- this keeps clean builds in sync
define version=699
@update_header

DECLARE
	v_count		NUMBER(10);
BEGIN
	-- get rid of old columns that may or may not exist
	FOR r IN (
		SELECT * 
		  FROM all_tab_columns 
		 WHERE owner = 'CSR' AND table_name = 'CUSTOMER' 
		   AND column_name IN ('LAST_TRUCOST_REPORT_ID', 'CURRENT_TRUCOST_REPORT_ID')
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.CUSTOMER DROP COLUMN '||r.column_name;
	END LOOP;
	
	-- add a new column that may or may not exist
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns 
	 WHERE owner = 'CSR' AND table_name = 'CUSTOMER' 
	   AND column_name IN ('TRUCOST_COMPANY_ID');
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.CUSTOMER ADD (TRUCOST_COMPANY_ID NUMBER(10))';
	END IF;
	
END;
/

-- add a column that defo doesn't exist
ALTER TABLE csr.CUSTOMER ADD (TRUCOST_PORTLET_TAB_ID NUMBER(10));

ALTER TABLE csr.CUSTOMER ADD CONSTRAINT FK_TRUCOST_PORTLET_TAB_ID 
    FOREIGN KEY (APP_SID, TRUCOST_PORTLET_TAB_ID)
    REFERENCES csr.TAB(APP_SID, TAB_ID) ON DELETE SET NULL
;

@update_tail
