-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=4
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
UPDATE csr.module
   SET description = 'Enable GRESB property integration. Once enabled, the client''s site has to be added to the cr360 GRESB account, '||
       'by adding a new application under account settings, with the callback URL ''https://CLIENT_NAME.credit360.com/csr/site/property/gresb/authorise.acds''. '
 WHERE module_id = 65;

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (65, 'in_use_sandbox', 0, 'Use sandbox GRESB enviornment instead of live? (y|n default=n)');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../property_pkg
@../enable_body
@../property_body

@update_tail
