-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- add missing base data
BEGIN
	BEGIN
		INSERT INTO csr.est_job_type (est_job_type_id, description) VALUES(6, 'ReadOnly Metric');
	EXCEPTION
		WHEN dup_val_on_index THEN	
			NULL;
	END;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
