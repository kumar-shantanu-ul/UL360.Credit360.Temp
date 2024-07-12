-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=6
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
UPDATE security.menu
   SET action = '/csr/site/admin/translations/translationsImport.acds'
 WHERE action = '''/csr/site/admin/translations/translationsImport.acds';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
