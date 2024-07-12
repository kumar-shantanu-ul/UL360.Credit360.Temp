-- Please update version.sql too -- this keeps clean builds in sync
define version=3129
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.FACTOR ADD (PROFILE_ID	NUMBER(10, 0))';
EXCEPTION
	WHEN OTHERS THEN
		-- column being added already exists in table
		IF SQLCODE != -1430 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.FACTOR ADD (PROFILE_ID	NUMBER(10, 0))';
EXCEPTION
	WHEN OTHERS THEN
		-- column being added already exists in table
		IF SQLCODE != -1430 THEN
			RAISE;
		END IF;
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
@../factor_body

@../schema_body
@../csrimp/imp_body

@update_tail
