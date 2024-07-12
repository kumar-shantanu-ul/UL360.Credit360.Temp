-- Please update version.sql too -- this keeps clean builds in sync
define version=2141
@update_header

DECLARE
	v_exists NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_exists
	  FROM csr.capability
	 WHERE name = 'Automatically approve Data Change Requests';

	IF v_exists = 0 THEN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Automatically approve Data Change Requests', 0);
	END IF;
END;
/

@..\sheet_body

@update_tail
