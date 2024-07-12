-- Please update version.sql too -- this keeps clean builds in sync
define version=2899
define minor_version=5
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

-- ** New package grants **

-- *** Packages ***
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
