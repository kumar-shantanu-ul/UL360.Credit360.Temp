-- Please update version.sql too -- this keeps clean builds in sync
define version=3176
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.METER_SOURCE_DATA ADD (
	STATEMENT_ID		VARCHAR2(256)
);

ALTER TABLE CSR.METER_ORPHAN_DATA ADD (
	STATEMENT_ID		VARCHAR2(256)
);

ALTER TABLE CSRIMP.METER_SOURCE_DATA ADD (
	STATEMENT_ID		VARCHAR2(256)
);

ALTER TABLE CSRIMP.METER_ORPHAN_DATA ADD (
	STATEMENT_ID		VARCHAR2(256)
);

ALTER TABLE CSR.METER_INSERT_DATA ADD (
	STATEMENT_ID		VARCHAR2(256)
);

ALTER TABLE CSR.TEMP_METER_READING_ROWS ADD (
	STATEMENT_ID		VARCHAR2(256)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW CSR.V$AGGR_METER_SOURCE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, priority, start_dtm, end_dtm, 
		SUM(consumption) consumption, MAX(meter_raw_data_id) meter_raw_data_id
	  FROM csr.meter_source_data
	 GROUP BY app_sid, region_sid, meter_input_id, priority, start_dtm, end_dtm
;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (53, 'Metering - Urjanet Statement ID Aggregation', 'Aggregate values from the same meter ID where the start/end dates match and the values come from the same Statement ID', 'EnableUrjanetStatementIdAggr', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (53, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../meter_monitor_pkg
@../util_script_pkg

@../enable_body
@../meter_body
@../meter_monitor_body
@../schema_body
@../util_script_body
@../csrimp/imp_body

@update_tail
