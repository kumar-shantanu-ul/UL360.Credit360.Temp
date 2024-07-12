-- Please update version.sql too -- this keeps clean builds in sync
define version=2527
@update_header

@..\delegation_pkg
@..\delegation_body
@..\csr_app_body
@..\enable_body
@..\sheet_body

@update_tail
