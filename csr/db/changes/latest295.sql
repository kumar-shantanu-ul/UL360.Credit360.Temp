-- Please update version.sql too -- this keeps clean builds in sync
define version=295
@update_header


INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Split delegations', 1);

@..\delegation_body


@update_tail
