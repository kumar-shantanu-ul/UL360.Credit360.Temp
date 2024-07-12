-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin();

	UPDATE surveys.question_version
	   SET allow_copy_answer = 0
	 WHERE question_id IN (SELECT question_id
							 FROM surveys.question
							WHERE question_type IN ('matrixset', 'matrixdynamic')
						);
	END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@ ../surveys/survey_body

@update_tail
