-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.HIGG_CONFIG ADD (COPY_SCORE_ON_SURVEY_SUBMIT NUMBER(1) DEFAULT 0 NOT NULL);

ALTER TABLE CHAIN.HIGG_CONFIG ADD CONSTRAINT CHK_COPY_SCORE_0_OR_1 CHECK (COPY_SCORE_ON_SURVEY_SUBMIT IN (0,1));

ALTER TABLE CSRIMP.HIGG_CONFIG ADD (COPY_SCORE_ON_SURVEY_SUBMIT NUMBER(1));

-- *** Grants ***
grant select on csr.internal_audit_survey to chain;
grant select on csr.v$quick_survey_response to chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/higg_setup_pkg

@../chain/higg_body
@../chain/higg_setup_body
@../csrimp/imp_body
@../schema_body


@update_tail
