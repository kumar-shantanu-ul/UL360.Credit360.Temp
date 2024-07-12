-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE
	surveys.question_Version
MODIFY
(
	default_numeric_value		NUMBER(26,10),
	min_numeric_value			NUMBER(26,10),
	max_numeric_value			NUMBER(26,10),
	numeric_value_tolerance		NUMBER(26,10)
);

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
