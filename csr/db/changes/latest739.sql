-- Please update version.sql too -- this keeps clean builds in sync
define version=739
@update_header

begin
	for r in (select constraint_name from all_constraints where owner='CSR' and table_name='QS_QUESTION_OPTION' and constraint_type='P') loop
		execute immediate 'alter table csr.qs_question_option drop primary key cascade drop index';
	end loop;
end;
/

@update_tail
