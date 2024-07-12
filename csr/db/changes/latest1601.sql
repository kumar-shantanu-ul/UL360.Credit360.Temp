-- Please update version.sql too -- this keeps clean builds in sync
define version=1601
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_READING_PERIOD'
	   AND index_name = 'IX_METER_READING_PERIOD_START';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_meter_reading_period_start on csr.meter_reading_period (app_sid, start_id)';
	END IF;
END;
/

@update_tail