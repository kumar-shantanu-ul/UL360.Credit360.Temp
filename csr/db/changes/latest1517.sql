-- Please update version.sql too -- this keeps clean builds in sync
define version=1517
@update_header

@..\indicator_body
@..\region_body
@..\csr_user_body
 
@update_tail
