-- Please update version.sql too -- this keeps clean builds in sync
define version=1323
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

begin
	begin
		insert into cms.col_type (col_type, description) values (29, 'Tree');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/
@update_tail
