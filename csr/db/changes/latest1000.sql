-- Please update version.sql too -- this keeps clean builds in sync
define version=1000
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Message users', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user details', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user groups', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user starting points', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user delegation cover', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user roles', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('User roles admin', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user active', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user accessibility', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user alerts', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user regional settings', 1);
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user region association', 1);
END;
/

@update_tail
