-- Please update version.sql too -- this keeps clean builds in sync
define version=451
@update_header

declare
	v_cnt	number;
begin
	select count(*)
	  into v_cnt
	  from user_tab_columns
	 where table_name = 'CUSTOMER' and column_name = 'MESSAGE';
	if v_cnt = 0 then
		execute immediate 'alter table customer add message clob';
	end if;
end;
/

@update_tail
