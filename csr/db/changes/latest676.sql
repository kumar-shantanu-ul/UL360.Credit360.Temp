-- Please update version.sql too -- this keeps clean builds in sync
define version=676
@update_header

begin
	for r in (select * from all_objects where owner='CSR' and object_name='RAG_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package csr.rag_pkg';
	end loop;
end;
/

@../calc_pkg
@../calc_body

@update_tail
