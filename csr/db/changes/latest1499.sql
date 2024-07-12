-- Please update version.sql too -- this keeps clean builds in sync
define version=1499
@update_header

DECLARE
v_cnt	NUMBER(10);

BEGIN
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CSR' 
	   AND table_name = 'SECTION_MODULE'
	   AND column_name ='SHOW_FLOW_SUMMARY_TAB';
	
	--ALTER TABLE CSR.SECTION_MODULE ADD (
	--	SHOW_FLOW_SUMMARY_TAB NUMBER(1) DEFAULT 0 NOT NULL 
	--);
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_MODULE ADD (SHOW_FLOW_SUMMARY_TAB NUMBER(1) DEFAULT 0 NOT NULL )';
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CSR' 
	   AND table_name = 'FLOW_STATE'
	   AND column_name ='STATE_COLOUR';

	--ALTER TABLE CSR.FLOW_STATE ADD (
	--	STATE_COLOUR      NUMBER(10)
	--);
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_STATE ADD (STATE_COLOUR      NUMBER(10))';
	END IF;

END;
/

@..\section_pkg
@..\section_body
@..\section_status_pkg
@..\section_status_body
@..\section_root_pkg
@..\section_root_body

@update_tail