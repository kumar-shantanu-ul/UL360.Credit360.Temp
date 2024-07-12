-- Please update version.sql too -- this keeps clean builds in sync
define version=2083
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Highlight unmerged data', 0);

@update_tail
