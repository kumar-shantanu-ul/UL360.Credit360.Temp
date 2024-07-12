-- Please update version.sql too -- this keeps clean builds in sync
define version=1388
@update_header

DECLARE
	v_count number;
BEGIN
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints 
	 WHERE constraint_name = 'UK_SUBSTANCE_USE'
	   AND owner = 'CHEM';
	
	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT UK_SUBSTANCE_USE';
	END IF;
END;
/

@update_tail