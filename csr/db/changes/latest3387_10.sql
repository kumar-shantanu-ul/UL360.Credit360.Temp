-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.batch_job bj
   SET retry_dtm = SYSDATE + 1,
	   updated_dtm = SYSDATE,
	   completed_dtm = NULL,
	   failed = 0
 WHERE bj.failed = 1
   AND bj.requested_dtm > '01-JAN-2022'
   AND EXISTS (
	SELECT NULL
	  FROM chain.company_request_action
	 WHERE batch_job_id = bj.batch_job_id
	);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
