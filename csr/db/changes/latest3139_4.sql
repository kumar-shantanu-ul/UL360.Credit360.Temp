-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.non_compliance_type
  ADD is_default_survey_finding NUMBER(1,0) DEFAULT 0 NOT NULL;

ALTER TABLE csr.non_compliance_type
  ADD CONSTRAINT chk_is_default_survey_finding CHECK (is_default_survey_finding IN (1, 0));

ALTER TABLE csrimp.non_compliance_type
  ADD is_default_survey_finding NUMBER(1,0) NOT NULL;

ALTER TABLE csrimp.non_compliance_type
  ADD CONSTRAINT chk_is_default_survey_finding CHECK (is_default_survey_finding IN (1, 0));

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
@../audit_pkg

@../audit_body
@../schema_body
@../csrimp/imp_body


@update_tail
