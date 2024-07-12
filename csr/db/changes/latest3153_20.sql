-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table surveys.question_version add NUMBER_ROWS_EXCEL_EXPORT_TEMP NUMBER;
update surveys.question_version set NUMBER_ROWS_EXCEL_EXPORT_TEMP = NUMBER_EMPTY_ROWS_EXCEL_EXPORT;
update surveys.question_version set NUMBER_EMPTY_ROWS_EXCEL_EXPORT = null;
alter table surveys.question_version modify NUMBER_EMPTY_ROWS_EXCEL_EXPORT NUMBER(3,0);
update surveys.question_version set NUMBER_EMPTY_ROWS_EXCEL_EXPORT = NUMBER_ROWS_EXCEL_EXPORT_TEMP;
alter table surveys.question_version drop column NUMBER_ROWS_EXCEL_EXPORT_TEMP;

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
