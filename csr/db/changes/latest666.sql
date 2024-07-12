-- Please update version.sql too -- this keeps clean builds in sync
define version=666
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Create users for approval', 0);

@..\csr_user_pkg

@..\csr_user_body
@..\csr_data_body

@update_tail
