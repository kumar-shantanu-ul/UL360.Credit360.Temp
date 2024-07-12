-- Please update version.sql too -- this keeps clean builds in sync
define version=3032
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

grant select,insert,update,delete on csrimp.cms_enum_group to tool_user;
grant select,insert,update,delete on csrimp.cms_enum_group_member to tool_user;
grant select,insert,update,delete on csrimp.cms_enum_group_tab to tool_user;
grant select,insert,update,delete on csrimp.scenario_run_version to tool_user;
grant select,insert,update,delete on csrimp.scenario_run_version_file to tool_user;

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
