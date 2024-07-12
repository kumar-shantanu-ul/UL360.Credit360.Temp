-- Please update version.sql too -- this keeps clean builds in sync
define version=2084
@update_header

BEGIN
	BEGIN
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 20, 'Group change');
	EXCEPTION 
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

@../csr_data_pkg
@../csr_user_body
@../role_body

@update_tail
