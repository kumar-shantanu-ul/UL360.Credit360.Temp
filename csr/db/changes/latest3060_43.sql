-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.automated_import_instance
ADD debug_log_file BLOB;

ALTER TABLE csr.automated_import_instance
ADD session_log_file BLOB;

ALTER TABLE csr.automated_export_instance
ADD debug_log_file BLOB;

ALTER TABLE csr.automated_export_instance
ADD session_log_file BLOB;

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
@../automated_export_pkg

@../automated_import_body
@../automated_export_body


@update_tail
