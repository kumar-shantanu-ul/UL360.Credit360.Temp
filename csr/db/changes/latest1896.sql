-- Please update version.sql too -- this keeps clean builds in sync
define version=1896
@update_header

begin
	for r in (select 1 from all_tables where owner='CHAIN' and table_name='XXX_INVITE_ON_BEHALF_OF') loop
		execute immediate 'drop table chain.XXX_INVITE_ON_BEHALF_OF';
	end loop;
end;
/

@../chain/chain_body

@update_tail
