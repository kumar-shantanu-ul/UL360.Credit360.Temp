-- Please update version.sql too -- this keeps clean builds in sync
define version=1011
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow user to share CMS filters', 1);

@update_tail