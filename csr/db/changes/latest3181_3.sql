-- Please update version.sql too -- this keeps clean builds in sync
define version=3181
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	PROC_USE_REMOTE_SERVICE		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_PROC_USE_REMOTE_SERVICE CHECK (PROC_USE_REMOTE_SERVICE IN (0,1))
);

ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	PROC_USE_REMOTE_SERVICE		NUMBER(1) NOT NULL,
	CONSTRAINT CK_PROC_USE_REMOTE_SERVICE CHECK (PROC_USE_REMOTE_SERVICE IN (0,1))
);

ALTER TABLE CSR.METER_PROCESSING_JOB ADD (
	METER_RAW_DATA_ID			NUMBER(10)
);

ALTER TABLE CSR.METER_PROCESSING_JOB ADD CONSTRAINT FK_METERPROCJOB_METERRAWDATA
	FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
	REFERENCES CSR.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

CREATE INDEX CSR.IX_METERPROCJOB_METERRAWDATA ON CSR.METER_PROCESSING_JOB (APP_SID, METER_RAW_DATA_ID);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(10, 'Queued', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(11, 'Merging', 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_monitor_pkg
@../meter_processing_job_pkg

@../meter_monitor_body
@../meter_processing_job_body
@../schema_body
@../csrimp/imp_body

@update_tail
