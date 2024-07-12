-- Please update version.sql too -- this keeps clean builds in sync
define version=1506
@update_header

ALTER TABLE CSR.CUSTOMER MODIFY USER_DIRECTORY_TYPE_ID DEFAULT 1;

DECLARE
	v_count	number(10);
BEGIN
	select count(*) into v_count from all_tab_cols where owner = 'CSR' and table_name = 'FLOW_STATE' AND column_name = 'STATE_COLOUR';

	if v_count = 0 then
		execute immediate 'ALTER TABLE CSR.FLOW_STATE ADD (STATE_COLOUR      NUMBER(10))';
	end if;


	select count(*) into v_count from all_tab_cols where owner = 'CSR' and table_name = 'SECTION_MODULE' AND column_name = 'SHOW_FLOW_SUMMARY_TAB';
	
	if v_count = 0 then
		execute immediate 'ALTER TABLE CSR.SECTION_MODULE ADD (SHOW_FLOW_SUMMARY_TAB NUMBER(1) DEFAULT 0 NOT NULL)';
	end if;
	
	begin
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage jobs', 0);
	exception
		when dup_val_on_index then
			null;
	end;
END;
/

@update_tail
