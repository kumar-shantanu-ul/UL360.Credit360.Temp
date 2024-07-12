-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- This is to fix differences between the change scripts and the create schema,
-- so they need to be conditional so that it works for both people that have just used latests
-- and people that have used the create_schema
DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='PROPERTY_TYPE' AND column_name='LOOKUP_KEY';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.PROPERTY_TYPE modify LOOKUP_KEY NULL';
	END IF;
	
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='PROPERTY_TYPE' AND column_name='GRESB_PROP_TYPE_CODE';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.PROPERTY_TYPE modify GRESB_PROP_TYPE_CODE NULL';
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


@update_tail
