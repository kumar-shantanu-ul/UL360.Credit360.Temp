-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select on csr.user_measure_conversion to actions;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\indicator_body
@..\actions\initiative_reporting_body

@update_tail
