-- Please update version.sql too -- this keeps clean builds in sync
define version=2100
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
  v_column_exists number := 0;  
BEGIN
	-- add deleted column to flow_alert_type
	SELECT COUNT(*) INTO v_column_exists
	  FROM all_tab_cols
	 WHERE column_name = 'DELETED'
	   AND table_name = 'FLOW_ALERT_TYPE'
	   AND owner = 'CSR';

	IF (v_column_exists = 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.flow_alert_type ADD (deleted NUMBER(1,0) DEFAULT 0 NOT NULL)';
	END IF;
	
	-- add deleted column to cms_alert_type
	SELECT COUNT(*) INTO v_column_exists
	  FROM all_tab_cols
	 WHERE column_name = 'DELETED'
	   AND table_name = 'CMS_ALERT_TYPE'
	   AND owner = 'CSR';

	IF (v_column_exists = 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.cms_alert_type ADD (deleted NUMBER(1,0) DEFAULT 0 NOT NULL)';
	END IF;
	
	-- CSRIMP add deleted column to flow_alert_type
	SELECT COUNT(*) INTO v_column_exists
	  FROM all_tab_cols
	 WHERE column_name = 'DELETED'
	   AND table_name = 'FLOW_ALERT_TYPE'
	   AND owner = 'CSRIMP';

	IF (v_column_exists = 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.flow_alert_type ADD (deleted NUMBER(1,0) DEFAULT 0 NOT NULL)';
	END IF;
	
	-- CSRIMP add deleted column to cms_alert_type
	SELECT COUNT(*) INTO v_column_exists
	  FROM all_tab_cols
	 WHERE column_name = 'DELETED'
	   AND table_name = 'CMS_ALERT_TYPE'
	   AND owner = 'CSRIMP';

	IF (v_column_exists = 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.cms_alert_type ADD (deleted NUMBER(1,0) DEFAULT 0 NOT NULL)';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- *** Packages ***

@../flow_pkg
@../flow_body

@update_tail