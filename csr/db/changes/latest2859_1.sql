-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (59, 'Data change requests', 'EnableDataChangeRequests', 'Enables data change requests. Also enables the alerts and sets up their templates.');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail
