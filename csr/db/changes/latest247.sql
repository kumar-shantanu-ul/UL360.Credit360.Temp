-- Please update version.sql too -- this keeps clean builds in sync
define version=247
@update_header

-- these aren't meant to be in the superadmins table
delete from superadmin where csr_user_sid in (3,5);

@update_tail
