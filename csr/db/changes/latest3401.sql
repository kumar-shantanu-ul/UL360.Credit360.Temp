-- Please update version.sql too -- this keeps clean builds in sync
define version=3401
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CMS.FORM_RESPONSE_ANSWER DROP CONSTRAINT CHK_FORM_RESP_ANS_TYPE;
ALTER TABLE CMS.FORM_RESPONSE_ANSWER ADD CONSTRAINT CHK_FORM_RESP_ANS_TYPE CHECK (ANSWER_TYPE IN ('null', 'string', 'number', 'date', 'stringlist', 'fileattachment'));

ALTER TABLE CMS.FORM_RESPONSE_SECTION_ANSWER DROP CONSTRAINT CHK_FORM_RESP_SEC_ANS_TYPE;
ALTER TABLE CMS.FORM_RESPONSE_SECTION_ANSWER ADD CONSTRAINT CHK_FORM_RESP_SEC_ANS_TYPE CHECK (ANSWER_TYPE IN ('null', 'string', 'number', 'date', 'stringlist', 'fileattachment'));

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
