-- Please update version.sql too -- this keeps clean builds in sync
define version=3331
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.module ADD (
	enable_class		VARCHAR2(1024)
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableBranding' WHERE enable_sp = 'EnableBranding';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableQuestionLibrary';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableFileSharingApi';
UPDATE csr.module SET enable_class = 'Credit360.Enable.EnableAmforiIntegration' WHERE enable_sp = 'EnableAmforiIntegration';
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../enable_pkg
@../quick_survey_pkg

@../audit_body
@../enable_body
@../quick_survey_body

@update_tail
