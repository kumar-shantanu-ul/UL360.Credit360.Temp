-- Please update version.sql too -- this keeps clean builds in sync
define version=3178
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

@@latestDE8539_packages

DECLARE
	v_app_sid	NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT DISTINCT c.host, sd.app_sid, sd.region_sid
		  FROM csr.meter_source_data sd
		  JOIN csr.customer c ON c.app_sid = sd.app_sid
		  JOIN csr.meter_input_aggr_ind ia ON ia.region_sid = sd.region_sid AND ia.meter_input_id = sd.meter_input_id
		  JOIN csr.measure m ON m.measure_sid = ia.measure_sid
		  LEFT JOIN csr.measure_conversion mc ON mc.measure_sid = ia.measure_sid AND mc.measure_conversion_id = ia.measure_conversion_id
		 WHERE lower(nvl(mc.description, m.description)) != lower(sd.raw_uom)
		 ORDER BY sd.app_sid, sd.region_sid
	) LOOP
		IF v_app_sid IS NULL OR v_app_sid != r.app_sid THEN
			security.user_pkg.logonadmin(r.host);
			v_app_sid := r.app_sid;
		END IF;
		CSR.DE8539_PACKAGE.UpdateMeterListCache(r.region_sid);
	END LOOP;
	security.user_pkg.logonadmin;
	COMMIT;
END;
/

DROP PACKAGE CSR.DE8539_PACKAGE;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_body

@update_tail
