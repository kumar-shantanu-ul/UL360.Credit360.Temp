-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.METER_PROCESSING_PIPELINE_INFO (
	APP_SID						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONTAINER_ID				VARCHAR2(256)	NOT NULL,
	JOB_ID						VARCHAR2(256)	NOT NULL,
	PIPELINE_ID					VARCHAR2(256)	NULL,
	PIPELINE_STATUS				VARCHAR2(256)	NULL,
	PIPELINE_MESSAGE			VARCHAR2(2048)	NULL,		
	PIPELINE_RUN_START			DATE			NULL,	
	PIPELINE_RUN_END			DATE			NULL,		
	PIPELINE_LAST_UPDATED		DATE			NULL,
	PIPELINE_LA_RUN_ID			VARCHAR2(2048)	NULL,
	PIPELINE_LA_NAME			VARCHAR2(2048)	NULL,	
	PIPELINE_LA_STATUS			VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORCODE		VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORMESSAGE	VARCHAR2(2048)	NULL,
	PIPELINE_LA_ERRORLOG		CLOB			NULL,	
	CONSTRAINT METER_PROCESSING_PIPELINE_INFO PRIMARY KEY (APP_SID, CONTAINER_ID, JOB_ID)
);

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.meter_processing_job_pkg TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_processing_job_pkg
@../meter_monitor_pkg

@../meter_processing_job_body
@../meter_monitor_body


@update_tail
