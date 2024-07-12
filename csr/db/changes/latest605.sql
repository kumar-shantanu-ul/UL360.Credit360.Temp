-- Please update version.sql too -- this keeps clean builds in sync
define version=605
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Use gauge-style charts', 0);

@update_tail

