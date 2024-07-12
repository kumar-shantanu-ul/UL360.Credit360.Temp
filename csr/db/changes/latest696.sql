-- Please update version.sql too -- this keeps clean builds in sync
define version=696
@update_header

alter table csr.delegation drop column regions_are_children;

begin
	for r in (select * from all_objects where owner='CSR' and object_name='CHECKREGIONALSUBDELEGPOSSIBLE' and object_type='PROCEDURE') loop
		execute immediate 'drop procedure csr.'||r.object_name;
	end loop;
end;
/

@../delegation_pkg
@../delegation_body
@../sheet_body
@../schema_body

@update_tail
