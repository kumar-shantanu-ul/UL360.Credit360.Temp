-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=4
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

BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE chain.chain_user
	   SET registration_status_id = 1 /* chain_pkg.REGISTERED */
	 WHERE (app_sid, user_sid) IN (
		-- look for users that were created by dedupe
		 SELECT ch.app_sid, ch.user_sid
		   FROM chain.dedupe_merge_log ml
		   JOIN chain.dedupe_processed_record dpr
		     ON dpr.app_sid = ml.app_sid
		    AND dpr.dedupe_processed_record_id = ml.dedupe_processed_record_id
		   JOIN chain.chain_user ch
		     ON ch.user_sid = dpr.imported_user_sid
		    AND ch.app_sid = dpr.app_sid
		  WHERE ml.old_val IS NULL
			AND ml.dedupe_field_id = 105 /*  USERNAME */
			AND ch.registration_status_id = 0 /* chain_pkg.PENDING */
	 );

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\company_dedupe_body

@update_tail
