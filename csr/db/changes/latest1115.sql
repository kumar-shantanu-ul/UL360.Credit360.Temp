-- Please update version.sql too -- this keeps clean builds in sync
define version=1115
@update_header

DECLARE
	v_itemExists	NUMBER;
BEGIN
	-- Check if this unit of measure has already been added
	-- If not, ignore as it will be named correctly when added
	SELECT COUNT(*) INTO v_itemExists
	FROM CSR.STD_MEASURE_CONVERSION
	WHERE STD_MEASURE_CONVERSION_ID=4;
	
	IF v_itemExists = 0 THEN
		UPDATE CSR.STD_MEASURE_CONVERSION
		SET DESCRIPTION = 'metric ton'
		WHERE STD_MEASURE_CONVERSION_ID=4;
	END IF;

	-- Check if this unit of measure has already been added
	-- If not, ignore as it will be named correctly when added
	SELECT COUNT(*) INTO v_itemExists
	FROM CSR.STD_MEASURE_CONVERSION
	WHERE STD_MEASURE_CONVERSION_ID=119;
	
	IF v_itemExists = 0	THEN
		UPDATE CSR.STD_MEASURE_CONVERSION
		SET DESCRIPTION = 'metric ton/litre'
		WHERE STD_MEASURE_CONVERSION_ID=119;
	END IF;
END;
/

@update_tail