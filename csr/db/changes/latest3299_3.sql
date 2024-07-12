-- Please update version.sql too -- this keeps clean builds in sync
define version=3299
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.batch_job_structure_import
ADD create_users_with_blank_pwd NUMBER(1, 0) DEFAULT 0;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../structure_import_pkg
@../structure_import_body

@update_tail
