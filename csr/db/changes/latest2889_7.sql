-- Please update version.sql too -- this keeps clean builds in sync
define version=2889
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Column is NOT NULL in schema but created as NULL in change script...
BEGIN
	FOR r IN (
		SELECT nullable
		  FROM all_tab_columns
		 WHERE owner = 'CHAIN'
		   AND table_name = 'SAVED_FILTER'
		   AND column_name = 'GROUP_KEY'
		   AND nullable = 'N'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.saved_filter MODIFY group_key NULL';
	END LOOP;
END;
/

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
