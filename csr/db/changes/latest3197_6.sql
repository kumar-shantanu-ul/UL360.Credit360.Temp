-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=6
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
	INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15888, 'Fugitive Gas - R-436a', 1, 0, 11158);
	INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15889, 'Fugitive Gas - R-452a', 1, 0, 11158);
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
