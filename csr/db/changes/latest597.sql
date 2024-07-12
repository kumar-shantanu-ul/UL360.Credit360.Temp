-- Please update version.sql too -- this keeps clean builds in sync
define version=597
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Configure strategy dashboard', 0);
INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('View strategy dashboard', 0);

@..\strategy_pkg
@..\strategy_body

@update_tail
