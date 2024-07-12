-- Please update version.sql too -- this keeps clean builds in sync
define version=1508
@update_header

@..\indicator_pkg
@..\indicator_body
@..\region_pkg
@..\region_body
@..\csr_user_pkg
@..\csr_user_body
 
@update_tail
