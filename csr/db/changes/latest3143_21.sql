-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=21
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

INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
			values(15887, 13968, 'Road Vehicle Distance - Car (Small) - Gasoline / Petrol Hybrid (Direct)', 10, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
