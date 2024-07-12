-- Please update version.sql too -- this keeps clean builds in sync
define version=1423
@update_header

begin
	begin
		INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Add portal tabs', 1);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

@update_tail
