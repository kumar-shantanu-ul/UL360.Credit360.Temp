-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=13
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

BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Null out values in val and region_metric_val for region metrics that have a text measure
	UPDATE csr.val
	   SET val_number = null,
		   entry_val_number = null
	 WHERE val_number = 0
	   AND source_type_id = 14
	   AND (app_sid, ind_sid, region_sid) IN (
		SELECT app_sid, ind_sid, region_sid
		  FROM csr.region_metric_val
		 WHERE val = 0
		   AND (app_sid, measure_sid) IN (
			SELECT app_sid, measure_sid
			  FROM csr.measure
			 WHERE custom_field = '|'
		)
	);

	UPDATE csr.region_metric_val
	   SET val = null,
		   entry_val = null
	 WHERE val = 0
	   AND (app_sid, measure_sid) IN (
		SELECT app_sid, measure_sid
		  FROM csr.measure
		 WHERE custom_field = '|'
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
