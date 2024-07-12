-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.flow_item TO surveys;
GRANT SELECT ON csr.flow_state TO surveys;
GRANT SELECT ON csr.flow_state_survey_tag TO surveys;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
--@../surveys/survey_pkg
--@../surveys/survey_body

@update_tail
