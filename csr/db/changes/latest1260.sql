-- Please update version.sql too -- this keeps clean builds in sync
define version=1260
@update_header

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Administer Chemical module', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

grant execute on csr.delegation_pkg to chem;
grant select on csr.sheet to chem;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
	