-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=41
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.quick_survey_type ADD tearoff_toolbar NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.quick_survey_type ADD CONSTRAINT CHK_TEAROFF_TOOLBAR CHECK (tearoff_toolbar IN (0,1));

ALTER TABLE CSR.quick_survey_type MODIFY cs_class NULL;

ALTER TABLE CSRIMP.quick_survey_type ADD tearoff_toolbar NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.quick_survey_type ADD CONSTRAINT CHK_TEAROFF_TOOLBAR CHECK (tearoff_toolbar IN (0,1));
ALTER TABLE CSRIMP.quick_survey_type MODIFY cs_class NULL;

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
@../quick_survey_pkg
@../quick_survey_body
@../csrimp/imp_body
@../schema_body


@update_tail
