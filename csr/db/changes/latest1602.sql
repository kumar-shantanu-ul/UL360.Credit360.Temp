-- Please update version.sql too -- this keeps clean builds in sync
define version=1602
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_READING_PERIOD'
	   AND index_name = 'IX_METER_READING_PERIOD_APP';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_meter_reading_period_app on csr.meter_reading_period (app_sid)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_READING'
	   AND index_name = 'IX_METER_READING_APP';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_meter_reading_app on csr.meter_reading(app_sid)';
	END IF;
END;
/

@update_tail