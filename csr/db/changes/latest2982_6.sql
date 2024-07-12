-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER MODIFY QUESTIONNAIRE_ID NUMBER(10) NULL;
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER ADD COMPANY_SID NUMBER(10) NOT NULL;
ALTER TABLE CHAIN.TT_QUESTIONNAIRE_ORGANIZER ADD QUESTIONNAIRE_TYPE_ID NUMBER(10) NOT NULL;

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
@../chain/questionnaire_body

@update_tail
