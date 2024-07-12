-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table surveys.question_version add (
    NUMBER_EMPTY_ROWS_EXCEL_EXPORT NUMBER 
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
--@../surveys/question_library_pkg
--@../surveys/question_library_body
@update_tail
