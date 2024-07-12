-- Please update version.sql too -- this keeps clean builds in sync
define version=946
@update_header

DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables 
	 WHERE owner = 'CSR'
	   AND table_name = 'TEMP_METER_CONSUMPTIONS';
	 
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE('
			CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_CONSUMPTIONS(
				START_DTM				DATE,
				END_DTM					DATE,
				CONSUMPTION				NUMBER(24,10)
			) ON COMMIT DELETE ROWS
		');
	END IF;
END;
/

@../energy_star_pkg
@../energy_star_body

@update_tail