-- Please update version.sql too -- this keeps clean builds in sync
define version=832
@update_header

@..\csr_app_pkg
@..\csr_app_body

@update_tail