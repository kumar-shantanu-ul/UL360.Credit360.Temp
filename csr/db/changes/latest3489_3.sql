-- Please update version.sql too -- this keeps clean builds in sync
define version=3489
define minor_version=3
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
UPDATE csr.automated_export_instance
   SET file_generated = 1
 WHERE file_generated = 0
   AND payload is not null;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_export_body

@update_tail
