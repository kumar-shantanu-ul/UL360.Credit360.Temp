-- Please update version.sql too -- this keeps clean builds in sync
define version=1345
@update_header

begin
	begin
		insert into csr.source_type (source_type_id, description) values (12, 'Aggregate group');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

@update_tail
