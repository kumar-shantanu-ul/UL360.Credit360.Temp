-- Please update version.sql too -- this keeps clean builds in sync
define version=1510
@update_header
			
BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can filter section userview', 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		-- it's on live already
		NULL;
END;
/

@../section_pkg
@../section_body

@update_tail