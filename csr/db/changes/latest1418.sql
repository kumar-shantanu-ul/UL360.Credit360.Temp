-- Please update version.sql too -- this keeps clean builds in sync
define version=1418
@update_header


DECLARE
	v_count number;
BEGIN
	-- Add missing table that wasn't in a clean script for a while 
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'DEFAULT_PRODUCT_CODE_TYPE'
	   AND owner = 'CHAIN';	
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CHAIN.DEFAULT_PRODUCT_CODE_TYPE (APP_SID NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'', ''APP'') NOT NULL, CODE_LABEL1    VARCHAR2(100)    NOT NULL, CODE_LABEL2    VARCHAR2(100), CODE_LABEL3    VARCHAR2(100), CONSTRAINT PK407 PRIMARY KEY (APP_SID))';
	END IF;
END;
/

@update_tail
