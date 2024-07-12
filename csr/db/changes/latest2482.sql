-- Please update version.sql too -- this keeps clean builds in sync
define version=2482
@update_header

UPDATE csr.Internal_Audit_Type
   SET nc_audit_child_region = 0
 WHERE nc_audit_child_region IS NULL;

ALTER TABLE csr.internal_audit_type MODIFY nc_audit_child_region DEFAULT 0 NOT NULL;

@update_tail
