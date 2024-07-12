-- Please update version.sql too -- this keeps clean builds in sync
define version=759
@update_header

BEGIN
	INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('View emission factors', 0);
	commit;
END;
/

@update_tail
