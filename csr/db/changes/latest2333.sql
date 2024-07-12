-- Please update version.sql too -- this keeps clean builds in sync
define version=2333
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Check conditional indicators on delegation import', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
