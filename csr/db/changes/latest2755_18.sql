-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=18
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
UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.InitiativesPlugin'
 WHERE js_include = '/csr/site/teamroom/controls/InitiativesPanel.js'
   AND js_class = 'Teamroom.InitiativesPanel'
   AND app_sid IS NULL;
-- ** New package grants **

-- *** Packages ***

@update_tail