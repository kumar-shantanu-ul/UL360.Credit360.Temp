-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.COMPLIANCE_ITEM_HISTORY' ;
	EXCEPTION
	WHEN OTHERS THEN
		IF SQLCODE != -942 THEN  -- Raise exception if there is any other exception other than table not found"
			RAISE;
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
@../compliance_pkg
@../compliance_body
@../csr_app_body

@update_tail
