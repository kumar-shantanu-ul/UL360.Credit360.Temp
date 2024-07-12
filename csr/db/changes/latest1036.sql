-- Please update version.sql too -- this keeps clean builds in sync
define version=1036
@update_header

-- FB10770
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 100, 'Region role change');
-- FB21655
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 110, 'Region category change');
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 111, 'Indicator category change');

@..\csr_data_pkg
@..\role_pkg
@..\tag_pkg

@..\csr_data_body
@..\role_body
@..\tag_body

@update_tail
