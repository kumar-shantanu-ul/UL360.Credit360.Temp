-- Please update version.sql too -- this keeps clean builds in sync
define version=1253
@update_header

begin
	begin
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 18, 'Feed');
	exception 
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 19, 'SSO logon');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

@../csr_data_pkg
@../csr_user_body

@update_tail
