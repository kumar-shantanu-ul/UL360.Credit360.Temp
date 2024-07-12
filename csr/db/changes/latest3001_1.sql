-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'SUPPLIER'
	   AND table_name = 'GT_TARGET_SCORES'
	   AND column_name = 'APP_SID'
	   AND nullable = 'Y';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.GT_TARGET_SCORES MODIFY APP_SID NOT NULL';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'SUPPLIER'
	   AND table_name = 'GT_TARGET_SCORES'
	   AND column_name = 'GT_PRODUCT_TYPE_ID'
	   AND nullable = 'Y';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.GT_TARGET_SCORES MODIFY GT_PRODUCT_TYPE_ID NOT NULL';
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
