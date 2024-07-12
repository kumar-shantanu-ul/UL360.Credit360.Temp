-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('evidence', 'Evidence question', null);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
