-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=18
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

-- ** New package grants **

-- *** Conditional Packages ***
-- These shouldn't exist on environments, they had a missing drop
BEGIN
	FOR r IN (
		SELECT object_name 
		  FROM all_objects 
		 WHERE object_type = 'PACKAGE' 
		   AND object_name IN ('TEST_CORE_API_PKG', 'TEST_EMISSION_FACTORS_PKG')
		   AND owner = 'CSR'
	) LOOP
		EXECUTE IMMEDIATE 'DROP PACKAGE CSR.'||r.object_name;
	END LOOP;
END;
/

-- *** Packages ***
@../region_pkg

@../region_body

@update_tail
