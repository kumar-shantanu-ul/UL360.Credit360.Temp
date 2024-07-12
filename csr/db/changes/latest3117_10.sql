-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS DROP COLUMN PAYLOAD_PATH;
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS DROP COLUMN RERUN_ASAP;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../automated_import_body
@../automated_export_pkg
@../automated_export_body

@update_tail
