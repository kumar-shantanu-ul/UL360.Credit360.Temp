-- Please update version.sql too -- this keeps clean builds in sync
define version=265
@update_header

begin
	for r in (select 1 from user_tab_columns where table_name='SNAPSHOT' and column_name='TAG_GROUP_ID' and nullable='N') loop
		execute immediate 'alter table snapshot modify    TAG_GROUP_ID   NULL';
	end loop;
end;
/

-- i've nuked the old delegations browser
update security.menu set action = replace(action, 'browse/','browse2/') where action like '/csr/site/delegation/browse/browse%';

@update_tail

