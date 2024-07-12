-- Please update version.sql too -- this keeps clean builds in sync
define version=312
@update_header
	
INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow approvers to edit submitted sheets', 1);

@..\csr_data_pkg
@..\csr_data_body
@..\sheet_body

@update_tail
