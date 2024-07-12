-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.DEDUPE_BATCH_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	IMPORT_SOURCE_ID				NUMBER(10)		NOT NULL,
	BATCH_NUMBER					NUMBER(10),
	FORCE_RE_EVAL					NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_DEDUPE_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.DEDUPE_BATCH_JOB ADD CONSTRAINT FK_BATCHJOB_DEDUPEBATJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;
-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (60, 'Dedupe batch job', null, 'process-dedupe-records', 0, null);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../chain/company_dedupe_pkg
@../chain/company_dedupe_body

@update_tail
