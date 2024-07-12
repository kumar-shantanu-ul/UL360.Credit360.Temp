-- Please update version.sql too -- this keeps clean builds in sync
define version=1340
@update_header

BEGIN
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('FLOWS_30000');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('LBACSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WKPROXY');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WKSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WK_TEST');
	UPDATE cms.sys_schema SET oracle_schema = 'XS$NULL' where oracle_schema = 'X$NULL';
END;
/

@update_tail
