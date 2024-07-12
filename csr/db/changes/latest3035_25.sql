-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=25
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

/*
	NOTE: templated_report_pkg now relies on a new type declared in in a different branch that has since been merged into trunk

	If this doesn't compile build csr.T_GENERIC_SO_TABLE from cvs\csr\db\create_types.sql
*/

@../templated_report_pkg

@../templated_report_body
@../region_body

@update_tail
