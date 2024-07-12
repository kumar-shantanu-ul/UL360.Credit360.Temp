-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_state_group TO tool_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.flow_state_group_member TO tool_user;

GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor_set TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.custom_factor TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csrimp.emission_factor_profile_factor TO tool_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.init_tab_element_layout TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.init_create_page_el_layout TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.initiative_header_element TO tool_user;

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
