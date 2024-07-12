-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_imp_core_data_settings
ADD date_string_exact_parse_format VARCHAR2(255);

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
