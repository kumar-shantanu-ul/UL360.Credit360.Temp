-- Please update version.sql too -- this keeps clean builds in sync
define version=1869
@update_header

--missing from latest1381

DECLARE 
    v_count NUMBER;
BEGIN
	SELECT 	count(*) INTO v_count
	  FROM 	all_cons_columns
	 WHERE 	owner = 'CSR'
	   AND 	constraint_name = 'PK_CMS_ALERT_TYPE'
	   AND 	table_name = 'CMS_ALERT_TYPE'
	   AND 	column_name = 'CUSTOMER_ALERT_TYPE_ID';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.cms_alert_type DROP PRIMARY KEY DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.cms_alert_type ADD CONSTRAINT pk_cms_alert_type PRIMARY KEY (app_sid, tab_sid, customer_alert_type_id)';
	END IF;
END;
/

@update_tail