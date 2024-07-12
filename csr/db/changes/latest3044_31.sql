-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1064,'My survey campaigns','Credit360.Portlets.MySurveyCampaigns', EMPTY_CLOB(),'/csr/site/portal/portlets/MySurveyCampaigns.js');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../folderlib_pkg
@@../folderlib_body
@@../campaign_body
@@../enable_body

@update_tail
