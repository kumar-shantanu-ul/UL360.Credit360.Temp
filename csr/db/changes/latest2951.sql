-- Please update version.sql too -- this keeps clean builds in sync
define version=2951
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
-- RLS

-- Data
	INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15776, 'Grid Electricity Generated - Supplier Specific', 9, 0, 10484);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
