-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=25
@update_header

@@latestUS3366_packages

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
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.all_meter m
		  JOIN csr.customer c ON c.app_sid = m.app_sid
		 WHERE m.urjanet_meter_id IS NOT NULL
	) LOOP
		security.user_pkg.logonadmin(a.host);
		-- Usually much quicker to recompute them all in one go
		csr.temp_meter_pkg.UpdateMeterListCache(null);
		security.user_pkg.logonadmin;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

DROP PACKAGE csr.temp_meter_pkg;

-- *** Packages ***
@..\meter_body

@update_tail
