-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=0
@update_header

declare
	v_exists NUMBER;
begin
	select count(*)
	  into v_exists 
	  from all_constraints 
	 where constraint_name = 'FK_ISSUE_TYPE' and owner = 'CSRIMP' and table_name = 'INTERNAL_AUDIT_TYPE_GROUP';

	if v_exists = 1 then
		execute immediate 'alter table csrimp.internal_audit_type_group drop constraint fk_issue_type';
	end if;
end;
/

@update_tail
