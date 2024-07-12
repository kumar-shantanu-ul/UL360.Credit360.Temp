-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CSR.METER_RAW_DATA_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE TABLE CSR.METER_RAW_DATA_LOG(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_RAW_DATA_ID    NUMBER(10, 0)     NOT NULL,
    LOG_ID               NUMBER(10, 0)     NOT NULL,
    USER_SID             NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    LOG_TEXT             VARCHAR2(4000)    NOT NULL,
    LOG_DTM              DATE              DEFAULT SYSDATE NOT NULL,
    MIME_TYPE            VARCHAR2(256),
    FILE_NAME            VARCHAR2(1024),
    DATA                 BLOB,
    CONSTRAINT PK_METER_RAW_DATA_LOG PRIMARY KEY (APP_SID, METER_RAW_DATA_ID, LOG_ID)
);

CREATE TABLE CSRIMP.METER_RAW_DATA_LOG(
    CSRIMP_SESSION_ID    NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    METER_RAW_DATA_ID    NUMBER(10, 0)     NOT NULL,
    LOG_ID               NUMBER(10, 0)     NOT NULL,
    USER_SID             NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    LOG_TEXT             VARCHAR2(4000)    NOT NULL,
    LOG_DTM              DATE              DEFAULT SYSDATE NOT NULL,
    MIME_TYPE            VARCHAR2(256),
    FILE_NAME            VARCHAR2(1024),
    DATA                 BLOB,
    CONSTRAINT PK_METER_RAW_DATA_LOG PRIMARY KEY (CSRIMP_SESSION_ID, METER_RAW_DATA_ID, LOG_ID),
    CONSTRAINT FK_METER_RAW_DATA_LOG FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE CSR.METER_RAW_DATA_LOG ADD CONSTRAINT FK_CSRUSR_METRAWDATLOG 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.METER_RAW_DATA_LOG ADD CONSTRAINT FK_METRAWDAT_METRAWDATLOG 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES CSR.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

ALTER TABLE CSR.METER_RAW_DATA ADD (
	ORIGINAL_MIME_TYPE              VARCHAR2(256),
    ORIGINAL_FILE_NAME              VARCHAR2(1024),
    ORIGINAL_DATA                   BLOB,
    AUTOMATED_IMPORT_INSTANCE_ID    NUMBER(10, 0)
);

ALTER TABLE CSR.METER_RAW_DATA ADD CONSTRAINT FK_AUTIMPINST_METRAWDATLOG 
    FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
    REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE(APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
;

CREATE INDEX CSR.IX_CSRUSR_METRAWDATLOG ON CSR.METER_RAW_DATA_LOG (APP_SID, USER_SID);
CREATE INDEX CSR.IX_METRAWDAT_METRAWDATLOG ON CSR.METER_RAW_DATA_LOG (APP_SID, METER_RAW_DATA_ID);
CREATE INDEX CSR.IX_AUTIMPINST_METRAWDATLOG ON CSR.METER_RAW_DATA (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID);

ALTER TABLE CSRIMP.METER_RAW_DATA ADD (
	ORIGINAL_MIME_TYPE              VARCHAR2(256),
    ORIGINAL_FILE_NAME              VARCHAR2(1024),
    ORIGINAL_DATA                   BLOB,
    AUTOMATED_IMPORT_INSTANCE_ID    NUMBER(10, 0)
);

-- *** Grants ***
grant insert on csr.meter_raw_data_log to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	-- Hook-up automated import ids and raw data rows using the latest file name
	-- Error files
	FOR r IN (
		SELECT app_sid, automated_import_instance_id, meter_raw_data_id
		  FROM csr.urjanet_import_instance
	) LOOP
		UPDATE csr.meter_raw_data
		   SET automated_import_instance_id = r.automated_import_instance_id
		 WHERE app_sid = r.app_sid 
		   AND meter_raw_data_id = r.meter_raw_data_id
		   AND automated_import_instance_id IS NULL; 
	END LOOP;
	-- Normal files
	FOR r IN (
		SELECT DISTINCT d.app_sid, d.meter_raw_data_id, d.file_name,
			FIRST_VALUE(s.automated_import_instance_id) OVER (
				PARTITION BY s.payload_filename 
				ORDER BY s.completed_dtm DESC NULLS LAST, s.started_dtm DESC, s.automated_import_instance_id DESC
			) automated_import_instance_id
		  FROM csr.meter_raw_data d
		  JOIN csr.automated_import_instance_step s ON s.app_sid = d.app_sid AND s.payload_filename = d.file_name
	) LOOP
		UPDATE csr.meter_raw_data
		   SET automated_import_instance_id = r.automated_import_instance_id
		 WHERE app_sid = r.app_sid 
		   AND meter_raw_data_id = r.meter_raw_data_id
		   AND automated_import_instance_id IS NULL;
	END LOOP;
END;
/

BEGIN
	-- Keep urjanet files for 365 days
	FOR r IN (
		SELECT app_sid, automated_import_class_sid
		  FROM csr.automated_import_class
		 WHERE lookup_key = 'URJANET_IMPORTER'
	) LOOP
		UPDATE csr.automated_import_class_step
		   SET days_to_retain_payload = 365
		 WHERE app_sid = r.app_sid
		   AND automated_import_class_sid = r.automated_import_class_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../meter_monitor_pkg
@../schema_pkg

@../meter_monitor_body
@../schema_body
@../csrimp/imp_body

@update_tail
