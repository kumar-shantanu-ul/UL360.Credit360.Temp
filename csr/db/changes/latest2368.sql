-- Please update version.sql too -- this keeps clean builds in sync
define version=2368
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Enable Delegation Sheet changes warning', 0);

@update_tail

