-- Please update version.sql too -- this keeps clean builds in sync
define version=1915
@update_header

@..\csr_user_body

@update_tail
