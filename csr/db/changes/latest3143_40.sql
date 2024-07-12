-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=40
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
REVOKE SELECT ON csr.flow_item FROM surveys;
REVOKE SELECT ON csr.flow_state FROM surveys;
REVOKE SELECT ON csr.flow_state_survey_tag FROM surveys;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
--@../surveys/survey_body

@update_tail
