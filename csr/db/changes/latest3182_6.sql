-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX csr.ix_audit_comparison_response ON csr.internal_audit(app_sid, comparison_response_id);

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
@..\quick_survey_body

@update_tail
