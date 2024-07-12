-- Please update version.sql too -- this keeps clean builds in sync
define version=150
@update_header

INSERT INTO CSR.AUDIT_TYPE (audit_type_id, label, audit_type_group_id) VALUES (65, 'Supplier tag changed', 1);

@update_tail
