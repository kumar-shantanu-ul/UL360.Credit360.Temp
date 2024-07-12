-- Please update version.sql too -- this keeps clean builds in sync
define version=1339
@update_header

INSERT INTO cms.sys_schema (oracle_schema) VALUES ('X$NULL');

@update_tail
