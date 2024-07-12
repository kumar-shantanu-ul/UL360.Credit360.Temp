-- Please update version.sql too -- this keeps clean builds in sync
define version=1405
@update_header


DECLARE
	v_count number;
BEGIN
	-- Remove old incorrect constraint if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'EC_CALCULATION_SOURCE_EC_EM'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.EC_EMISSIONS DROP CONSTRAINT EC_CALCULATION_SOURCE_EC_EM';
	END IF;
	
	-- Replace with correct constraint
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CALCULATION_SOURCE_EC_EM'
	   AND owner = 'CT';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.EC_EMISSIONS ADD CONSTRAINT CALCULATION_SOURCE_EC_EM FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.CALCULATION_SOURCE (CALCULATION_SOURCE_ID)';
	END IF;
	
	-- Remove old incorrect constraint if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'PS_CALCULATION_SOURCE_PS_EM'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_EMISSIONS DROP CONSTRAINT PS_CALCULATION_SOURCE_PS_EM';
	END IF;
	
	-- Replace with correct constraint
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CALCULATION_SOURCE_PS_EM'
	   AND owner = 'CT';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_EMISSIONS ADD CONSTRAINT CALCULATION_SOURCE_PS_EM FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.CALCULATION_SOURCE (CALCULATION_SOURCE_ID)';
	END IF;
	
	-- Remove old incorrect constraint if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CONT_SOURCE_PSLC'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_LEVEL_CONTRIBUTIONS DROP CONSTRAINT CONT_SOURCE_PSLC';
	END IF;
	
	-- Replace with correct constraint
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CONT_SOURCE_PSLC'
	   AND owner = 'CT';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_LEVEL_CONTRIBUTIONS ADD CONSTRAINT CONT_SOURCE_PSLC FOREIGN KEY (CONTRIBUTION_SOURCE_ID) REFERENCES CT.CALCULATION_SOURCE (CALCULATION_SOURCE_ID)';
	END IF;
	
	-- Remove old incorrect constraint if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'PS_CALCULATION_SOURCE_PSLC'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_LEVEL_CONTRIBUTIONS DROP CONSTRAINT PS_CALCULATION_SOURCE_PSLC';
	END IF;
	
	-- Replace with correct constraint
	SELECT count(*) 
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CALCULATION_SOURCE_PSLC'
	   AND owner = 'CT';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CT.PS_LEVEL_CONTRIBUTIONS ADD CONSTRAINT CALCULATION_SOURCE_PSLC FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.CALCULATION_SOURCE (CALCULATION_SOURCE_ID)';
	END IF;
	
	
	-- Remove old incorrect table if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'PS_CALCULATION_SOURCE'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CT.PS_CALCULATION_SOURCE';
	END IF;
	
	-- Remove old incorrect table if it exists (some clean builds will have it)
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'EC_CALCULATION_SOURCE'
	   AND owner = 'CT';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CT.EC_CALCULATION_SOURCE';
	END IF;
END;
/

@update_tail
