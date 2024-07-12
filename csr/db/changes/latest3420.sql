-- Please update version.sql too -- this keeps clean builds in sync
define version=3420
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM security.menu
 WHERE action = '/app/ui.disclosures.admin/disclosuresAdmin'
   AND description = 'Frameworks';

UPDATE security.menu
   SET action = '/app/ui.disclosures/disclosures'
 WHERE action = '/app/ui.disclosures.admin/disclosuresAdmin';

UPDATE security.web_resource
   SET path = '/app/ui.disclosures'
 WHERE path = '/app/ui.disclosures.admin';

UPDATE security.securable_object
   SET name = 'ui.disclosures'
 WHERE name = 'ui.disclosures.admin';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
