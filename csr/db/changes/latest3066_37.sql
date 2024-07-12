-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=37
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
UPDATE security.menu
   SET description = 'Permits'
 WHERE action = '/csr/site/compliance/permitlist.acds'
   AND description = 'Permit Library';
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_library_report_pkg

@../compliance_library_report_body
@../compliance_register_report_body
@../compliance_setup_body
@../enable_body

@update_tail
