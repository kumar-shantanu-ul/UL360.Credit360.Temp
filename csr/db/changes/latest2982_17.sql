-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.region MODIFY geo_latitude NUMBER;
ALTER TABLE csrimp.region MODIFY geo_longitude NUMBER;

-- conditional fix of local dev environments
DECLARE
	v_require_fix	NUMBER(1);
BEGIN
	SELECT CASE WHEN data_scale IS NULL THEN 0 ELSE 1 END 
	  INTO v_require_fix
	  FROM all_tab_columns 
	 WHERE table_name = 'REGION'  and OWNER = 'CSR' and COLUMN_NAME = 'GEO_LATITUDE';	-- check for latitude, it will apply to longitude as well
	 
	 IF v_require_fix = 1 THEN 
		execute immediate('ALTER TABLE csr.region MODIFY geo_latitude NUMBER');
		execute immediate('ALTER TABLE csr.region MODIFY geo_longitude NUMBER');
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
