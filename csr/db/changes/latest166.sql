-- Please update version.sql too -- this keeps clean builds in sync
define version=166
@update_header

begin
	for r in (select column_name from user_tab_columns where table_name = 'CSR_USER' AND column_name = 'FAILED_LOGON_ATTEMPTS') loop
		execute immediate 'alter table csr_user drop column failed_logon_attempts';
	end loop;
end;
/

@update_tail
