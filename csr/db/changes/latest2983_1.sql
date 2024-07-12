-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.FILTER_EXPORT_BATCH (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10) NOT NULL,
	COMPOUND_FILTER_ID		NUMBER(10) NULL,
	CARD_GROUP_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_FILTER_EXPORT_BATCH PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_BATCH_COMPOUND_FILTER 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID)
	REFERENCES CHAIN.COMPOUND_FILTER (APP_SID, COMPOUND_FILTER_ID);


ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_CARD_GROUP 
    FOREIGN KEY (CARD_GROUP_ID)
	REFERENCES CHAIN.CARD_GROUP (CARD_GROUP_ID);

-- Alter tables
ALTER TABLE CSR.BATCH_JOB
ADD REQUESTED_BY_COMPANY_SID NUMBER(10, 0);

-- *** Grants ***

-- ** Cross schema constraints ***
 
ALTER TABLE CSR.BATCH_JOB ADD CONSTRAINT FK_BATCH_JOB_COMPANY 
    FOREIGN KEY (APP_SID, REQUESTED_BY_COMPANY_SID)
	REFERENCES CSR.SUPPLIER (APP_SID, COMPANY_SID);


ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_BATCH_JOB 
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB (APP_SID, BATCH_JOB_ID);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (10, 'Filter list export', 'Credit360.ExportImport.Export.Batched.Exporters.FilterListExcelExport');

UPDATE CSR.MODULE_PARAM 
   SET PARAM_HINT = 'Should the audit score synchronization be enabled? Y/N' 
 WHERE PARAM_HINT = 'Should the audit score syncronization be enabled? Y/N';

UPDATE CSR.MODULE_PARAM 
   SET PARAM_HINT = 'Date from which audits should be synchronized (yyyy-mm-dd or leave blank for full history or is not using this feature).' 
 WHERE PARAM_HINT = 'Date from which audits should be syncronized (yyyy-mm-dd or leave blank for full history or is not using this feature).';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../chain/filter_pkg

@../batch_job_body
@../chain/filter_body

@update_tail
