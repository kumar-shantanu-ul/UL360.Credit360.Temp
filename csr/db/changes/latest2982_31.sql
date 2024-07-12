-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.REGION_SURVEY_RESPONSE DROP CONSTRAINT PK_REGION_SURVEY_RESPONSE DROP INDEX;

ALTER TABLE CSR.REGION_SURVEY_RESPONSE DROP CONSTRAINT UQ_REG_SUR_RESP_RESP_ID DROP INDEX;

ALTER TABLE CSR.REGION_SURVEY_RESPONSE ADD (
	CONSTRAINT PK_REGION_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID)
);

ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE DROP CONSTRAINT PK_REGION_SURVEY_RESPONSE DROP INDEX;

ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE DROP CONSTRAINT UQ_REG_SUR_RESP_RESP_ID DROP INDEX; 

ALTER TABLE CSRIMP.REGION_SURVEY_RESPONSE ADD (
	CONSTRAINT PK_REGION_SURVEY_RESPONSE PRIMARY KEY (CSRIMP_SESSION_ID, SURVEY_RESPONSE_ID)
);

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
@../campaign_body
@../quick_survey_body

@update_tail
