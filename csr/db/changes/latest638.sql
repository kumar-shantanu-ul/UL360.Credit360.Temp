-- Please update version.sql too -- this keeps clean builds in sync
define version=638
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Load models into the calculation engine', 0);

@update_tail

