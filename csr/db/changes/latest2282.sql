-- Please update version.sql too -- this keeps clean builds in sync
define version=2282
@update_header

CREATE TABLE CSR.BATCH_JOB_METER_EXTRACT(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BATCH_JOB_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0),
    USER_SID        NUMBER(10, 0),
    START_DTM       DATE,
    END_DTM         DATE,
	INTERVAL        VARCHAR2(255),
    IS_FULL         NUMBER(1),
    JOB_FINISHED    NUMBER(1),
    REPORT_DATA     BLOB,
    CONSTRAINT CHK_JOB_FINISHED_ME CHECK (JOB_FINISHED IN (0,1)),
    CONSTRAINT PK_BJME PRIMARY KEY (APP_SID, BATCH_JOB_ID)
)
;
 
ALTER TABLE CSR.BATCH_JOB_TYPE ADD (file_data_sp VARCHAR2(255));

UPDATE CSR.BATCH_JOB_TYPE SET file_data_sp = 'csr.templated_report_pkg.GetBatchJobReportData' WHERE batch_job_type_id = 8;

INSERT INTO CSR.BATCH_JOB_TYPE VALUES (10, 'Meter extract', NULL, 'meter-extract', 0, 'csr.utility_report_pkg.GetBatchJobReportData');

@../batch_job_pkg
@../utility_report_pkg

@../batch_job_body
@../utility_report_body

@update_tail
