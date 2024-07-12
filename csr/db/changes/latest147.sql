-- Please update version.sql too -- this keeps clean builds in sync
define version=147
@update_header

INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id) VALUES (15, 'Meter reading', 1);

@update_tail