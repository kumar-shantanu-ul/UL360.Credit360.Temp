-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=27
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

EXEC security.user_pkg.LogonAdmin;

UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.PropertyCmsPluginDto'
 WHERE plugin_type_id = 1
   AND js_class = 'Controls.CmsTab'
   AND cs_class = 'Credit360.Plugins.PluginDto';

UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.AuditCmsPluginDto'
 WHERE plugin_type_id IN (13,14)
   AND js_class IN ('Audit.Controls.CmsTab', 'Audit.Controls.CmsHeader')
   AND cs_class = 'Credit360.Plugins.PluginDto';

UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.ChainCmsPluginDto'
 WHERE plugin_type_id IN (10,11)
   AND js_class IN ('Chain.ManageCompany.CmsTab', 'Chain.ManageCompany.CmsHeader')
   AND cs_class = 'Credit360.Plugins.PluginDto';

UPDATE csr.plugin
   SET cs_class = 'Credit360.Plugins.InitiativeCmsPluginDto'
 WHERE plugin_type_id = 8
   AND js_class = 'Credit360.Initiatives.Plugins.GridPanel'
   AND cs_class = 'Credit360.Plugins.PluginDto';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
