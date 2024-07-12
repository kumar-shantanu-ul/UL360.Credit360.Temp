-- Please update version.sql too -- this keeps clean builds in sync
define version=1092
@update_header 

@..\csr_data_pkg
@..\csrimp\imp_body

@update_tail
