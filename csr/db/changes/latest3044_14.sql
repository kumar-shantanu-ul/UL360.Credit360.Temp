-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD (
	QUESTION_LIBRARY_ENABLED NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_QUESTION_LIBRARY_ENABLED CHECK (QUESTION_LIBRARY_ENABLED IN (0,1))
);

ALTER TABLE csrimp.customer ADD (
	QUESTION_LIBRARY_ENABLED NUMBER(1) NOT NULL,
	CONSTRAINT CK_QUESTION_LIBRARY_ENABLED CHECK (QUESTION_LIBRARY_ENABLED IN (0,1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.module SET description = 'Enable surveys'
 WHERE enable_sp = 'EnableSurveys';

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (94, 'Question Library', 'EnableQuestionLibrary', 'Enables the Question Library module used in conjunction with Surveys, supporting a question bank for repeatable, reusable questions across multiple surveys and reporting periods.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_pkg

@..\enable_body
@..\schema_body
@..\customer_body
@..\csrimp\imp_body

@update_tail
