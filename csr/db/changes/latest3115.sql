-- Please update version.sql too -- this keeps clean builds in sync
define version=3115
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE surveys.question_version MODIFY min_numeric_value NUMBER(20,10);
ALTER TABLE surveys.question_version MODIFY max_numeric_value NUMBER(20,10);

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

@update_tail
