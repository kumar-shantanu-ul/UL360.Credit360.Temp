-- Please update version.sql too -- this keeps clean builds in sync
define version=3398
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer MODIFY (SHOW_FEEDBACK_FAB NUMBER(1) DEFAULT 0);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.customer SET show_feedback_fab = 0;
UPDATE csr.util_script SET util_script_name = 'Feedback - Enable' WHERE util_script_id = 71;
UPDATE csr.util_script SET util_script_name = 'Feedback - Disable' WHERE util_script_id = 72;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
