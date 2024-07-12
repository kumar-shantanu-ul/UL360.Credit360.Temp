-- Please update version.sql too -- this keeps clean builds in sync
define version=3141
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
DELETE FROM csr.factor_type 
 WHERE factor_type_id in (
	15847,
	15835,
	15836,
	15837,
	15838,
	15839,
	15840,
	15841,
	15842,
	15843,
	15846,
	15845,
	15844);
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
