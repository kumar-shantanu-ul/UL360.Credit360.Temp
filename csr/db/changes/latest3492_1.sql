-- Please update version.sql too -- this keeps clean builds in sync
define version=3492
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	FOR r IN (
		SELECT *
		  FROM all_tab_columns
		 WHERE owner = 'POSTCODE'
		   AND table_name = 'COUNTRY'
		   AND column_name IN ('AREA_IN_SQKM','CONTINENT')
		   AND nullable = 'N'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE postcode.country MODIFY('||r.column_name||' NULL)';
	END LOOP;
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
@..\dataset_legacy_body

@update_tail
