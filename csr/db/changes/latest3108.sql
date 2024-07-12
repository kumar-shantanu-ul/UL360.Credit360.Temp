-- Please update version.sql too -- this keeps clean builds in sync
define version=3108
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.auto_exp_filecreate_dsv drop column quotes_as_literals;

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

@../automated_export_pkg
@../automated_export_body

@update_tail
