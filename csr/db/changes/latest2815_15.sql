-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.page_error_log_detail ADD (
	FORM				CLOB,
	JSON				CLOB,
	NPSL_SESSION		CLOB);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\db\error_pkg
@..\..\..\aspen2\db\error_body

@update_tail
