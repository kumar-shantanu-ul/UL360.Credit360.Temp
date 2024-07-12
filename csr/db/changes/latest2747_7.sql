-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS
-- Insert the data entry form issue type for customer without it
BEGIN
	FOR r in (
		SELECT app_sid
		  FROM csr.customer
		 WHERE app_sid NOT IN (
			SELECT app_sid
			  FROM csr.issue_type
			 WHERE issue_type_id = 1
			)
	) LOOP
		INSERT INTO csr.issue_type 
			(app_sid, issue_type_id, label)
		VALUES
			(r.app_sid, 1, 'Data entry form');
	END LOOP;
END;
/
-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
