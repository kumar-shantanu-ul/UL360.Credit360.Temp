-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP TRIGGER csr.batch_job_notify_trigger;

DROP MATERIALIZED VIEW LOG ON CSR.BATCH_JOB_NOTIFY;
DROP MATERIALIZED VIEW CSR.V$BATCH_JOB_NOTIFY;

DROP TABLE CSR.BATCH_JOB_NOTIFY;

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

@../batch_job_pkg
@../batch_job_body
@../csr_app_body

@update_tail
