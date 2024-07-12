-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE surveys.audit_log_detail MODIFY (
	new_value VARCHAR2(4000),
	old_value VARCHAR2(4000),
	user_disp_new_value VARCHAR2(4000),
	user_disp_old_value VARCHAR2(4000)
);

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

@update_tail
