-- Please update version.sql too -- this keeps clean builds in sync
define version=3366
define minor_version=6
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
	security.user_pkg.logonadmin;

	/* runs faster through a loop, rather than a single UPDATE (i.e. 3 sec vs 2 mins on supdb)*/
	FOR r in (
		SELECT i.issue_id 
		  FROM csr.issue i
		 WHERE i.issue_type_id = 13 /*Supplier action*/
	)
	LOOP
		UPDATE csr.issue_log 
		   SET is_system_generated = 0
		 WHERE issue_id = r.issue_id
		   AND is_system_generated = 1
		   AND logged_by_user_sid !=3;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../supplier_body

@update_tail
