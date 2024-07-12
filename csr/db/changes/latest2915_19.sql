-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=19
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
	FOR r IN (
		-- Find all est_meters where the parent region sid is actually the region sid of an est_space
		SELECT m.app_sid, m.region_sid, s.pm_space_id,
			m.est_account_sid, m.pm_customer_id, m.pm_building_id, m.pm_meter_id
		  FROM csr.est_meter m
		  JOIN csr.region r
			ON r.app_sid = m.app_sid 
		   AND r.region_sid = m.region_sid
		  JOIN csr.est_space s 
			ON s.app_sid = m.app_sid 
		   AND s.est_account_sid = m.est_account_sid 
		   AND s.pm_customer_id = m.pm_customer_id 
		   AND s.pm_building_id = m.pm_building_id 
		   AND s.region_sid = r.parent_sid
		 ORDER BY app_sid
	) LOOP
		-- Update the space id inthe est_meter table
		UPDATE csr.est_meter
		   SET pm_space_id = r.pm_space_id
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid
		   AND NVL(pm_space_id, -1) != NVL(r.pm_space_id, -1);

		-- Create change log entries that will kick-off energy star jobs
		BEGIN
			INSERT INTO csr.est_meter_change_log (app_sid, est_account_sid, pm_customer_id, pm_building_id, pm_meter_id)
			VALUES (r.app_sid, r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_job_pkg

@../energy_star_job_body
@../region_body

@update_tail
