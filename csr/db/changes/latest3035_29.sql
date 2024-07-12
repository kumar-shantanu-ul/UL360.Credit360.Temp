-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.SHEET_COMPLETENESS_SHEET (
	APP_SID		NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SHEET_ID	NUMBER(10, 0)		NOT NULL,
	CONSTRAINT PK_SHEET_COMPLETENESS_SHEET PRIMARY KEY (app_sid, sheet_id)
);

ALTER TABLE CSR.SHEET_COMPLETENESS_SHEET ADD CONSTRAINT FK_SHEET_COMPLETENESS_SHEET 
	FOREIGN KEY (APP_SID, SHEET_ID)
	REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;

BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid, sheet_id
		  FROM csr.sheet_completeness_job
	)
	LOOP
		INSERT INTO csr.sheet_completeness_sheet
			(app_sid, sheet_id)
		VALUES
			(r.app_sid, r.sheet_id);
	END LOOP;
END;
/

DROP TABLE csr.sheet_completeness_job;


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
delete from csr.batch_job where batch_job_type_id = 18;
delete from CSR.BATCH_JOB_TYPE_APP_STAT where batch_job_type_id = 18;
delete from csr.batch_job_type where batch_job_type_id = 18;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../sheet_pkg

@../sheet_body
@../csr_app_body

@update_tail
