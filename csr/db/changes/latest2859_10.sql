-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=10
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

@..\..\..\aspen2\cms\db\filter_pkg
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\form_pkg
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\cms\db\pivot_pkg
@..\..\..\aspen2\cms\db\pivot_body
@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\web_publication_pkg
@..\..\..\aspen2\cms\db\web_publication_body

@..\..\..\aspen2\db\aspen_user_pkg
@..\..\..\aspen2\db\aspen_user_body
@..\..\..\aspen2\db\aspenapp_pkg
@..\..\..\aspen2\db\aspenapp_body
@..\..\..\aspen2\db\aspenredirect_pkg
@..\..\..\aspen2\db\aspenredirect_body
@..\..\..\aspen2\db\fp_user_pkg
@..\..\..\aspen2\db\fp_user_body
@..\..\..\aspen2\db\job_pkg
@..\..\..\aspen2\db\job_body
@..\..\..\aspen2\db\poll_pkg
@..\..\..\aspen2\db\poll_body
@..\..\..\aspen2\db\scheduledtask_pkg
@..\..\..\aspen2\db\scheduledtask_body
@..\..\..\aspen2\db\trash_pkg
@..\..\..\aspen2\db\trash_body

@update_tail