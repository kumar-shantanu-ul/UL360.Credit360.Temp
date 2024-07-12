-- Please update version.sql too -- this keeps clean builds in sync
define version=947
@update_header

DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes 
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_METER_READING_START';
	 
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE('
			CREATE INDEX csr.ix_meter_reading_start ON csr.meter_reading_period(start_id)
		');
	END IF;
END;
/

@update_tail