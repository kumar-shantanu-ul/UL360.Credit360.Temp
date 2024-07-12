-- Please update version.sql too -- this keeps clean builds in sync
define version=508
@update_header

delete from csr.superadmin where not exists (select * from security.securable_object where sid_id = superadmin.csr_user_sid);

@..\csr_user_body

@update_tail
