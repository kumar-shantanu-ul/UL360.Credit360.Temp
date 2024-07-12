-- Please update version.sql too -- this keeps clean builds in sync
define version=2032
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow changing Indicator lookup keys', 0);

@update_tail
