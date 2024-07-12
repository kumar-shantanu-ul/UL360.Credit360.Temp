-- Please update version.sql too -- this keeps clean builds in sync
define version=1267
@update_header

create or replace package csr.user_setting_pkg as
procedure dummy;
end;
/
create or replace package body csr.user_setting_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.user_setting_pkg to web_user;

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='DELEGATION_IND' and column_name='DESCRIPTION') loop
		execute immediate 'alter table csr.delegation_ind drop column description';
	end loop;
end;
/

@../user_setting_pkg
@../user_setting_body

@update_tail
