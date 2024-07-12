-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.TEMP_METER_READING_ROWS ADD (
	UNIT_OF_MEASURE 			VARCHAR2(10),
	IMPORT_CONVERSION_ID 		NUMBER(10),
	METER_CONVERSION_ID 		NUMBER(10),
	MEASURE_SID					NUMBER(10)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$temp_meter_reading_rows AS
       SELECT t.source_row, t.region_sid, t.start_dtm, t.end_dtm, t.reference, t.note, t.reset_val,
              t.priority, v.consumption consumption, c.consumption cost,
			  v.import_conversion_id cons_import_conv_id, c.import_conversion_id cost_import_conv_id,
			  v.meter_conversion_id  cons_meter_conv_id , c.meter_conversion_id cost_meter_conv_id,
			  v.error_msg cons_error_msg, c.error_msg cost_error_msg
	    FROM ( SELECT DISTINCT source_row,
			    region_sid,
			    start_dtm,
			    end_dtm,
			    REFERENCE,
			    priority,
			    note,
			    reset_val
    			FROM csr.temp_meter_reading_rows
			  ) t
	LEFT JOIN csr.temp_meter_reading_rows v
		   ON v.source_row       = t.source_row
		  AND t.region_sid       = v.region_sid
		  AND v.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'CONSUMPTION'
								  )
	LEFT JOIN csr.temp_meter_reading_rows c
		   ON c.source_row       = t.source_row
		  AND t.region_sid       = c.region_sid
		  AND c.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'COST'
								  );

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../meter_monitor_pkg

@../meter_monitor_body
@../meter_body

@update_tail
