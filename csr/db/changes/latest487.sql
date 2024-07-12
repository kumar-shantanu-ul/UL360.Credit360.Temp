-- Please update version.sql too -- this keeps clean builds in sync
define version=487
@update_header

BEGIN
	INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow adding snapshots', 0);
	commit;
END;
/

@update_tail
