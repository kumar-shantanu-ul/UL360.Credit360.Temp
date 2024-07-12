-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE 
	v_expr VARCHAR2(1024) := '^/compliance/RegionCompliance.acds\?flowItemId=(\d+)';
BEGIN
	security.user_pkg.LogonAdmin(NULL);

	UPDATE csr.issue 
	   SET source_url = 
			'/csr/site/compliance/RegionCompliance.acds?flowItemId=' || 
			REGEXP_SUBSTR(source_url, v_expr, 1, 1, NULL, 1)
	 WHERE REGEXP_LIKE(source_url, v_expr);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
