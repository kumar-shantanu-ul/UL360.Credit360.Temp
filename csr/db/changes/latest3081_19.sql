-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP
  ADD ignore_file_not_found_excptn NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP
  ADD CONSTRAINT ck_ignore_file_nt_fnd_excptn CHECK (ignore_file_not_found_excptn IN (0, 1));

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

@update_tail
