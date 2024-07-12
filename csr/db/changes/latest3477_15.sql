-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.USER_ANONYMISATION_BATCH_JOB(
	APP_SID			NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	USER_SID		NUMBER(10, 0)    NOT NULL,
	BATCH_JOB_ID	NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_USER_ANONYMISATION_BATCH_JOB PRIMARY KEY (APP_SID, USER_SID, BATCH_JOB_ID)
)
;

CREATE INDEX CSR.IX_USER_ANONBATJOB ON CSR.USER_ANONYMISATION_BATCH_JOB (APP_SID, USER_SID);

-- Add constraints
ALTER TABLE CSR.USER_ANONYMISATION_BATCH_JOB ADD CONSTRAINT FK_USER_USERANONBATJOB
	FOREIGN KEY (APP_SID, USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.CSR_USER ADD ANONYMISED NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE CSRIMP.CSR_USER ADD ANONYMISED NUMBER(1) DEFAULT 0 NOT NULL;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
VALUES (96, 'Anonymise users', 'csr.csr_user_pkg.ProcessAnonymiseUsersBatchJob', 0, 120);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../batch_job_pkg
@../csr_user_pkg
@../csr_user_body
@../csrimp/imp_body

@update_tail
