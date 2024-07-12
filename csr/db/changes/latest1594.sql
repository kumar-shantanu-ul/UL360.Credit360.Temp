-- Please update version.sql too -- this keeps clean builds in sync
define version=1594
@update_header

-- add column CSR.FLOW_STATE.POS
DECLARE
	v_count	number(10);
BEGIN
	select count(*) into v_count from all_tab_cols where owner = 'CSR' and table_name = 'FLOW_STATE' AND column_name = 'POS';

	if v_count = 0 then
		execute immediate 'ALTER TABLE CSR.FLOW_STATE ADD (POS NUMBER(10, 0) DEFAULT 1 NOT NULL)';
	end if;

END;
/

@../flow_body

@update_tail