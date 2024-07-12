-- Please update version.sql too -- this keeps clean builds in sync
define version=2536
@update_header

BEGIN
	FOR r IN (
		SELECT 1 FROM all_tables WHERE owner = 'CSR' AND table_name = 'EST_SPACE_ATTR_LEGACY'
	) LOOP
		EXECUTE IMMEDIATE('ALTER TABLE CSR.EST_SPACE_ATTR_LEGACY DROP CONSTRAINT FK_EST_SPACEATTR_SPACE');
	END LOOP;
END;
/

@update_tail
