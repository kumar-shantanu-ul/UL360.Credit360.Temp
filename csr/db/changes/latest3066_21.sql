-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.ftp_profile_log (
	app_sid					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ftp_profile_id			NUMBER(10) 		NOT NULL,
	changed_dtm				DATE 			NOT NULL,
	changed_by_user_sid		NUMBER(10) 		NOT NULL,
	message					VARCHAR2(1024) 	NOT NULL
);

CREATE INDEX CSR.IDX_FTP_PROFILE_LOG ON CSR.FTP_PROFILE_LOG(APP_SID)
;


-- Alter tables
CREATE UNIQUE INDEX uk_ftp_profile_label ON csr.ftp_profile(app_sid, lower(label));

DROP TABLE csr.ftp_default_profile;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../automated_export_import_pkg
@../automated_import_pkg

@../automated_export_import_body
@../automated_import_body
@../meter_monitor_body
@../enable_body

@update_tail
