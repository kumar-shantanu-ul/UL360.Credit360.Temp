-- Please update version.sql too -- this keeps clean builds in sync
define version=1502
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can delete section comments', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's on live already
		NULL;
END;
/

@../section_pkg
@../section_body

@update_tail