-- Please update version.sql too -- this keeps clean builds in sync
define version=1504
@update_header

@..\indicator_pkg
@..\indicator_body
@..\csr_data_pkg
@..\csr_data_body
 
@update_tail
