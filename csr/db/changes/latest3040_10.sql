-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
drop user dyntab cascade;
drop package csr.logging_form_pkg;

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
@../tree_pkg
@../tree_body
@../../../aspen2/db/tree_body
@../csr_app_body
@../csr_user_body
@../delegation_body
@../supplier/product_pkg
@../supplier/product_body

@update_tail
