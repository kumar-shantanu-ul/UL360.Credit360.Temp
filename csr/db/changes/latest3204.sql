-- Please update version.sql too -- this keeps clean builds in sync
define version=3204
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
  v_nullable all_tab_columns.nullable%type;
BEGIN
  SELECT nullable
    INTO v_nullable
    FROM all_tab_columns
   WHERE owner = 'CSR'
	 AND table_name = 'SCHEDULED_STORED_PROC'
     AND column_name = 'NEXT_RUN_DTM';

  IF v_nullable = 'N' THEN
    EXECUTE IMMEDIATE 'ALTER TABLE CSR.SCHEDULED_STORED_PROC MODIFY (NEXT_RUN_DTM NULL)';
  END IF;
END;
/

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
