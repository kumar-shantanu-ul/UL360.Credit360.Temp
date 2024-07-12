-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=31
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

BEGIN
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('matrixdynamic', 'Matrix (dynamic rows)');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
