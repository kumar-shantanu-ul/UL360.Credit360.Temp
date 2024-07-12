-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FOLDER_SEARCH_EXTENSION (
  SID_ID       			NUMBER(10, 0)	NOT NULL,
  PARENT_SID			NUMBER(10, 0)	NOT NULL,
  SEARCH_RESULT_TEXT	VARCHAR2(255)
) ON COMMIT DELETE ROWS;

-- Alter tables

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
@../folderlib_pkg.sql
@../quick_survey_pkg.sql

@../folderlib_body.sql
@../quick_survey_body.sql

@update_tail
