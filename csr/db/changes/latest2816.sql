-- Please update version.sql too -- this keeps clean builds in sync
define version=2816
define minor_version=0
@update_header

DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_METLD_RGINAGPR';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE INDEX CSR.IX_METLD_RGINAGPR ON CSR.METER_LIVE_DATA(APP_SID, REGION_SID, METER_INPUT_ID, AGGREGATOR, PRIORITY)';
	END IF;
END;
/

@../meter_monitor_body

@update_tail
