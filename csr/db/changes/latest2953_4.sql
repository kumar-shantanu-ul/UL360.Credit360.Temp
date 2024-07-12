-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.batch_job_event (
    event_id                        NUMBER(10, 0) PRIMARY KEY,
    label                           VARCHAR2(50)
);

CREATE TABLE csr.batch_job_log (
    batch_job_id                    NUMBER(10, 0) NOT NULL,
    event_type_id                   NUMBER(10, 0) NOT NULL,
    caused_by_user_sid              NUMBER(10, 0),
    description                     VARCHAR2(512),
    event_dtm                       DATE NOT NULL,
    CONSTRAINT fk_batch_job_log_event FOREIGN KEY (event_type_id)
    REFERENCES csr.batch_job_event(event_id)
);

-- Alter tables
ALTER TABLE csr.batch_job
ADD aborted_dtm DATE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batch_job_event (event_id, label) VALUES (0, 'Abort');
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Abort any batch job', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg;
@../batch_job_body;

@update_tail
