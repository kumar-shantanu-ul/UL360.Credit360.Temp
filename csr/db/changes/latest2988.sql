-- Please update version.sql too -- this keeps clean builds in sync
define version=2988
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CSR.UK_SPACE_TYPE_MAP_DEFAULT;
ALTER TABLE CSR.EST_SPACE_TYPE_MAP DROP COLUMN IS_PUSH;

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
@../energy_star_pkg

@../property_body
@../energy_star_body
@../energy_star_job_body
@../energy_star_job_data_body
@../energy_star_attr_body

@update_tail
