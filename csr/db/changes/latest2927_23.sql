-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.qs_expr_non_compl_action MODIFY assign_to_role_sid NULL;

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
@../quick_survey_body

@update_tail
