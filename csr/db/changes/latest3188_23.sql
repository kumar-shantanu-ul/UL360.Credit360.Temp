-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DROP TABLE CSR.EXT_METER_DATA;

CREATE TABLE CSR.EXT_METER_DATA (
	CONTAINER_ID	VARCHAR2(1024),
	JOB_ID			VARCHAR2(1024),
	BUCKET_NAME		VARCHAR2(256),
	START_DTM		DATE,
	SERIAL_ID		VARCHAR2(1024),
	INPUT_KEY		VARCHAR2(256),
	UOM				VARCHAR2(256),
	VAL				NUMBER(24, 10)
)
ORGANIZATION EXTERNAL 
(
	TYPE ORACLE_LOADER 
	DEFAULT DIRECTORY DIR_EXT_METER_DATA 
	ACCESS PARAMETERS 
	( 
		RECORDS DELIMITED BY NEWLINE
		PREPROCESSOR DIR_SCRIPTS:'concatAllFiles.sh'
		FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
		MISSING FIELD VALUES ARE NULL 
		(
			CONTAINER_ID,
			JOB_ID,
			BUCKET_NAME,
			START_DTM DATE 'YYYY-MM-DD HH24:MI:SS',
			SERIAL_ID,
			INPUT_KEY,
			UOM,
			VAL
		) 
	)
	LOCATION('path.txt') 
)
REJECT LIMIT UNLIMITED;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg

@../meter_body
@../meter_processing_job_body

@update_tail
