-- Please update version.sql too -- this keeps clean builds in sync
define version=1170
@update_header

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 101, 'User role change');

@..\csr_data_pkg
@..\role_body

@update_tail
