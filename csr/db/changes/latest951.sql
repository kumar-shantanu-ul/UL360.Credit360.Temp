-- Please update version.sql too -- this keeps clean builds in sync
define version=951
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow users to raise data change requests', 0);

@..\sheet_body.sql

@update_tail
