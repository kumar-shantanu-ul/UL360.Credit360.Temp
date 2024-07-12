-- Please update version.sql too -- this keeps clean builds in sync
define version=1174
@update_header

declare
	v_cnt number;
begin
	select count(*)
	  into v_cnt
	  from all_objects 
	 where object_name='REPORT_PKG' and owner='CSR';
	if v_cnt > 0 then
		execute immediate 'drop package csr.report_pkg';
	end if;
end;
/

@update_tail
