-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=12
@update_header


-- *** DDL ***
-- Create tables

-- Alter tables

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.customer ADD status_from_parent_on_subdeleg NUMBER(1, 0) DEFAULT 0 NOT NULL';
EXCEPTION
	WHEN OTHERS THEN
		IF (SQLCODE = -1430) THEN
			null; -- No worries, table already has the column
		ELSE
			RAISE;
		END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\delegation_pkg
@..\delegation_body
@..\sheet_pkg
@..\sheet_body

@update_tail
