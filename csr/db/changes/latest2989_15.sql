-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.flow TO csrimp;
GRANT SELECT ON csr.flow_item TO csrimp;
GRANT SELECT ON csr.quick_survey_response TO csrimp;
GRANT SELECT ON csr.scenario TO csrimp;
GRANT SELECT ON security.securable_object_attributes TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
