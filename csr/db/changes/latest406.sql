-- Please update version.sql too -- this keeps clean builds in sync
define version=406
@update_header

alter table customer add fogbugz_ixproject number(10);

INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Read Fogbugz', 0);

@update_tail
