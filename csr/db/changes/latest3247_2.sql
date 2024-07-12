-- Please update version.sql too -- this keeps clean builds in sync
define version=3247
define minor_version=2
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

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15890, 'Stationary Fuel - Biodiesel (from used cooking oil) (Energy - GCV/HHV) (Upstream)', 9, 0, 7179);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
