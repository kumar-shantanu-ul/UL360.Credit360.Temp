-- Please update version.sql too -- this keeps clean builds in sync
define version=1366
@update_header 

-- Add default to app_sid column.
ALTER TABLE csr.deleg_meta_role_ind_selection 
MODIFY app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');

@update_tail