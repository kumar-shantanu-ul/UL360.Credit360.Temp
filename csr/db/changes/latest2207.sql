-- Please update version.sql too -- this keeps clean builds in sync
define version=2207
@update_header

declare
	v_exists number;
begin
	select count(*) into v_exists from all_sequences where sequence_owner='CHAIN' and sequence_name='COMPANY_TAB_ID_SEQ';
	if v_exists = 0 then
		execute immediate 'CREATE SEQUENCE CHAIN.COMPANY_TAB_ID_SEQ START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
	end if;
end;
/

@update_tail
