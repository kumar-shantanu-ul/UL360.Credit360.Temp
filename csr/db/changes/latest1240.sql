-- Please update version.sql too -- this keeps clean builds in sync
define version=1240
@update_header

begin
	begin
		INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (11, 'Two levels down');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

@../templated_report_pkg
@../templated_report_body

@update_tail
