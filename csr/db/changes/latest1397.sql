-- Please update version.sql too -- this keeps clean builds in sync
define version=1397
@update_header 

DECLARE
	v_count number;
BEGIN
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints 
	 WHERE constraint_name = 'CHK_PROCESS_DESTINATION'
	   AND owner = 'CHEM';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHEM.PROCESS_DESTINATION ADD CONSTRAINT CHK_PROCESS_DESTINATION CHECK (TO_AIR_PCT >= 0 AND TO_PRODUCT_PCT >= 0 AND TO_WASTE_PCT >= 0 AND TO_WATER_PCT >= 0 AND REMAINING_PCT >= 0 AND (TO_AIR_PCT + TO_PRODUCT_PCT + TO_WASTE_PCT + TO_WATER_PCT + REMAINING_PCT) <= 1)';
	END IF;
END;
/

@update_tail
