-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=25
@update_header

-- FB64265

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_import_class_step
  RENAME COLUMN helper_pkg to on_completion_sp;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\automated_import_pkg
@..\automated_import_body
@..\automated_export_body

@update_tail
