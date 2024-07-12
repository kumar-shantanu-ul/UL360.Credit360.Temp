-- Please update version.sql too -- this keeps clean builds in sync
define version=793
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Chain edit site global file groups', 0);

GRANT SELECT, REFERENCES ON csr.capability TO chain;


@update_tail
