-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.qs_campaign
MODIFY survey_sid NULL;

ALTER TABLE csrimp.qs_campaign
MODIFY survey_sid NULL;

ALTER TABLE csr.qs_campaign
ADD CONSTRAINT CHK_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL));

ALTER TABLE csrimp.qs_campaign
ADD CONSTRAINT CHK_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL));

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
