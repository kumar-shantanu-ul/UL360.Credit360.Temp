-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_EXPORT_SYSTEM_VALUES (
	REGION_SID				NUMBER(10),
	START_DTM				DATE,
	END_DTM					DATE,
	CONSTRAINT PK_TEMP_EXPORT_SYSTEM_VALUES PRIMARY KEY (REGION_SID)
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE CSR.METER_RAW_DATA_IMPORT_JOB ADD (
	RAW_DATA_SOURCE_ID		NUMBER(10)
);

ALTER TABLE CSR.BATCH_JOB ADD (
	IN_ORDER_GROUP			VARCHAR2(256)
);

ALTER TABLE CSR.TEMP_METER_READING_ROWS MODIFY (
	UNIT_OF_MEASURE			VARCHAR2(256)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.batch_job_type 
	   SET in_order = 1 
	 WHERE plugin_name = 'meter-raw-data-import';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../meter_monitor_pkg

@../batch_job_body
@../meter_body
@../meter_monitor_body
@../meter_patch_body

@update_tail
