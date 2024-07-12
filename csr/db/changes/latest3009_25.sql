-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.meter_import_revert_batch_job(
	app_sid         	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	batch_job_id    	NUMBER(10, 0)    NOT NULL,
	meter_raw_data_id   NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_IMPORT_REVERT_BATCH_JOB PRIMARY KEY (app_sid, batch_job_id, meter_raw_data_id)
);

-- Alter tables
ALTER TABLE csr.meter_import_revert_batch_job ADD CONSTRAINT FK_BJ_MIRBJ
	FOREIGN KEY (app_sid, batch_job_id)
	REFERENCES csr.batch_job(app_sid, batch_job_id)
;

ALTER TABLE csr.meter_import_revert_batch_job ADD CONSTRAINT FK_MRD_MIRBJ
	FOREIGN KEY (app_sid, meter_raw_data_id)
	REFERENCES csr.meter_raw_data(app_sid, meter_raw_data_id)
;

-- FK Indexes
CREATE INDEX csr.IX_BJ_MIRBJ ON csr.meter_import_revert_batch_job (app_sid, batch_job_id);
CREATE INDEX csr.IX_MRD_MIRBJ ON csr.meter_import_revert_batch_job (app_sid, meter_raw_data_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

-- RLS

-- Data
BEGIN
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing)
		 VALUES (8, 'Reverting', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing)
		 VALUES (9, 'Reverted', 0);
END;
/

BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, one_at_a_time)
		 VALUES (53, 'Raw meter data import revert', 'csr.meter_monitor_pkg.ProcessRawDataImportRevert', 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../meter_patch_pkg
@../meter_monitor_pkg

@../meter_monitor_body

@update_tail
