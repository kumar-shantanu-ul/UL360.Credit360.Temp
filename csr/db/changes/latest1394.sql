-- Please update version.sql too -- this keeps clean builds in sync
define version=1394
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Logon directly', 1);
 

@update_tail
