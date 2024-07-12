-- Please update version.sql too -- this keeps clean builds in sync
define version=2612
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can edit forms before system lock date', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
