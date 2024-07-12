-- Please update version.sql too -- this keeps clean builds in sync
define version=1111
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Issue type management', 0);

@..\issue_body

@update_tail
