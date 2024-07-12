-- Please update version.sql too -- this keeps clean builds in sync
define version=856
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage meter readings', 1);

@update_tail