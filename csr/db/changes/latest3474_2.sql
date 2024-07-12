-- Please update version.sql too -- this keeps clean builds in sync
define version=3474
define minor_version=2
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

UPDATE csr.module
    SET module_name = 'ESG Disclosures',
        description = 'Enable the new ESG Disclosures module'
WHERE module_id = 119;

UPDATE security.menu
   SET description = 'ESG Disclosures'
 WHERE description = 'Framework Disclosures';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
