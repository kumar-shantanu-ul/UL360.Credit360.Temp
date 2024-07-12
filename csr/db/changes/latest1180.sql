-- Please update version.sql too -- this keeps clean builds in sync
define version=1180
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Run sheet export report', 0);

@../region_pkg
@../sheet_pkg
@../region_body
@../sheet_body

@update_tail
