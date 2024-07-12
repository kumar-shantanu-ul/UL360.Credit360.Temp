-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
--use_company_type_css_class was modified to default 0 in an updated version of latest1844, however that change never ran for some db instances
DECLARE 
	v_data_default		all_tab_columns.data_default%TYPE;
BEGIN

	SELECT data_default
	  INTO v_data_default
	  FROM all_tab_columns
	 WHERE owner = 'CHAIN'
	   AND table_name = 'CUSTOMER_OPTIONS'
	   AND column_name = 'USE_COMPANY_TYPE_CSS_CLASS';
	
	IF v_data_default IS NULL OR UPPER(v_data_default)='NULL' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.customer_options MODIFY use_company_type_css_class DEFAULT 0';
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
