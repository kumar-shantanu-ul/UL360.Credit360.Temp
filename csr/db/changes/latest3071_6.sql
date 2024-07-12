-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Fix broken constraints
ALTER TABLE CSR.QUESTION_TAG DROP CONSTRAINT CHK_QT_QUESTION_DRAFT;
ALTER TABLE CSR.QUESTION_TAG ADD  CONSTRAINT CHK_QT_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));

ALTER TABLE CSRIMP.QUESTION_TAG DROP CONSTRAINT CHK_QT_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QUESTION_TAG ADD  CONSTRAINT CHK_QT_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));

ALTER TABLE CSR.QS_QUESTION_OPTION DROP CONSTRAINT CHK_QSQO_QUESTION_DRAFT;
ALTER TABLE CSR.QS_QUESTION_OPTION ADD  CONSTRAINT CHK_QSQO_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));

ALTER TABLE CSR.QUICK_SURVEY_QUESTION DROP CONSTRAINT CHK_QSQ_QUESTION_DRAFT;
ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD  CONSTRAINT CHK_QSQ_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));

ALTER TABLE CSR.NON_COMPLIANCE DROP CONSTRAINT CHK_NC_QUESTION_DRAFT;
ALTER TABLE CSR.NON_COMPLIANCE ADD  CONSTRAINT CHK_NC_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));


ALTER TABLE CHAIN.HIGG_QUESTION_OPTION_SURVEY DROP CONSTRAINT CHK_HQOS_QUESTION_DRAFT;
ALTER TABLE CHAIN.HIGG_QUESTION_OPTION_SURVEY ADD  CONSTRAINT CHK_HQOS_QUESTION_DRAFT CHECK (QS_QUESTION_DRAFT IN (0,1));

ALTER TABLE CSRIMP.QS_QUESTION_OPTION DROP CONSTRAINT CHK_QSQO_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QS_QUESTION_OPTION ADD  CONSTRAINT CHK_QSQO_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION DROP CONSTRAINT CHK_QSQ_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD  CONSTRAINT CHK_QSQ_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));

ALTER TABLE CSRIMP.NON_COMPLIANCE DROP CONSTRAINT CHK_NC_QUESTION_DRAFT;
ALTER TABLE CSRIMP.NON_COMPLIANCE ADD  CONSTRAINT CHK_NC_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));

ALTER TABLE CSRIMP.HIGG_QUESTION_OPTION_SURVEY DROP CONSTRAINT CHK_HQOS_QUESTION_DRAFT;
ALTER TABLE CSRIMP.HIGG_QUESTION_OPTION_SURVEY ADD  CONSTRAINT CHK_HQOS_QUESTION_DRAFT CHECK (QS_QUESTION_DRAFT IN (0,1));

	
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
@../question_library_pkg

@../question_library_body

@update_tail
