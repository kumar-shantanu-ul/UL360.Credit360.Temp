-- Please update version.sql too -- this keeps clean builds in sync
define version=2306
@update_header

--csrimp and csrexp doesn't have to do anything with PASSWORD_REGEXP table any more, it's in basedata.sql:
grant select on SECURITY.PASSWORD_REGEXP to csrimp;
begin
	for r in (select * from dba_tab_privs where table_Name='PASSWORD_REGEXP' and grantee='CSRIMP' and privilege='INSERT') loop
		execute immediate 'revoke insert on SECURITY.PASSWORD_REGEXP FROM csrimp';
	end loop;
end;
/

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name in ('PASSWORD_REGEXP', 'MAP_PASSWORD_REGEXP')) loop
		execute immediate 'DROP TABLE CSRIMP.'||r.table_name||' CASCADE CONSTRAINTS';
	end loop;
end;
/

@../csrimp/imp_body
@../schema_pkg
@../schema_body

@update_tail
