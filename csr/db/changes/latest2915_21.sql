-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=21
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
	-- Find all region metric values in the est_space_attr table that are for the wrong region
	FOR r IN (
		SELECT sa.app_sid, sa.pm_val_id, sa.est_account_sid, sa.pm_customer_id, sa.pm_building_id
		  FROM csr.est_space_attr sa
		  JOIN csr.est_space s ON s.app_sid = sa.app_sid AND s.est_account_sid = sa.est_account_sid AND s.pm_customer_id = sa.pm_customer_id AND s.pm_building_id = sa.pm_building_id AND s.pm_space_id = sa.pm_space_id
		  JOIN csr.region_metric_val v ON v.app_sid = sa.app_sid AND v.region_metric_val_id = sa.region_metric_val_id
		  JOIN csr.est_building b ON b.app_sid = sa.app_sid AND b.est_account_sid = sa.est_account_sid AND b.pm_customer_id = sa.pm_customer_id AND b.pm_building_id = sa.pm_building_id
		  JOIN csr.property p ON p.app_sid = b.app_sid AND p.region_sid = b.region_sid
		 WHERE p.energy_star_sync = 1
		   AND p.energy_star_push = 0
		   AND v.region_sid != s.region_sid
	) LOOP
		-- Null out incorrect reigon metric val id
		UPDATE csr.est_space_attr
		   SET region_metric_val_id = NULL
		 WHERE app_sid = r.app_sid
		   AND pm_val_id = r.pm_val_id;

		-- Force a new job for the associated property
		UPDATE csr.est_building
		   SET last_job_dtm = NULL
		 WHERE app_sid = r.app_sid
		   AND est_account_sid = r.est_account_sid
		   AND pm_customer_id = r.pm_customer_id
		   AND pm_building_id = r.pm_building_id;

	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_body

@update_tail
