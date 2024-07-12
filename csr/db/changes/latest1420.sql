-- Please update version.sql too -- this keeps clean builds in sync
define version=1420
@update_header


DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	-- Add missing nullable that wasn't in a clean script for a while 
	SELECT nullable 
	  INTO v_nullable
	  FROM all_tab_columns 
	 WHERE table_name = 'COMPONENT_RELATIONSHIP' 
	   AND owner= 'CHAIN' 
	   AND column_name='AMOUNT_UNIT_ID';	
	
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.COMPONENT_RELATIONSHIP MODIFY (AMOUNT_UNIT_ID NULL)';
	END IF;
END;
/

@update_tail
