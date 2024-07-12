-- Please update version too -- this keeps clean builds in sync
define version=1734
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Delete and copy values', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

@update_tail