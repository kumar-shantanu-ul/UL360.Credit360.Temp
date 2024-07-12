-- Please update version.sql too -- this keeps clean builds in sync
define version=2422
@update_header

INSERT INTO csr.capability (NAME,ALLOW_BY_DEFAULT) VALUES ('Compare Chain Survey to previous submission', 0);

@update_tail