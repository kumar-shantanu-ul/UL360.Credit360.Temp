-- Please update version too -- this keeps clean builds in sync
define version=1722
@update_header

declare
	v_cnt number;
begin
	select count(*) 
	  into v_cnt
	  from all_tab_cols
	 where owner = 'CSR' and table_name = 'CUSTOMER' and column_name = 'SCRAG_QUEUE';
	if v_cnt = 0 then
		execute immediate 'alter table csr.customer add scrag_queue varchar2(100)';
	end if;
end;
/

@../stored_calc_datasource_body

@update_tail