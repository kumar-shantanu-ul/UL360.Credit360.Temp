-- Please update version.sql too -- this keeps clean builds in sync
define version=892
@update_header

INSERT INTO csr.audit_type(audit_type_id, label, audit_type_group_id) VALUES (18, 'Feed', 1);

@..\feed_body

@update_tail
