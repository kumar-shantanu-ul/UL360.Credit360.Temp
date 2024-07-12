-- Please update version.sql too -- this keeps clean builds in sync
define version=1279
@update_header

-- there's no way to rename a sequence in another schema in Oracle
declare
	v_n number(10);
begin
	for r in (select 1 from all_sequences where sequence_name='REGION_SET_ID' and sequence_owner='CSR') loop
		execute immediate 'begin select csr.region_set_id.nextval into :1 from dual; end;'
		using out v_n;
		execute immediate 'DROP SEQUENCE CSR.REGION_SET_ID';
		execute immediate 'CREATE SEQUENCE CSR.REGION_SET_ID_SEQ START WITH '||v_n||' INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
	end loop;
end;
/

@../region_set_body

@update_tail
