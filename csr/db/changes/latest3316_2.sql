-- Please update version.sql too -- this keeps clean builds in sync
define version=3316
define minor_version=2
@update_header


@@latest3316_2_packages

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

-- reprocess the meter imports that are affected.
DECLARE
  out_cur security.security_pkg.T_OUTPUT_CUR;
BEGIN
	-- ~175 records at 28.08.2020, will increase daily
  FOR apps IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE app_sid IN (10016697, 27503257, 49728743) -- Process jmfamily, Hyatt, lendlease. Ignore BritishLand, Danske Bank, hm, UL
	)
  LOOP
    security.user_pkg.logonadmin(apps.host);
    FOR r IN (
      SELECT meter_raw_data_id
        FROM csr.meter_raw_data
       WHERE 
           orphan_count != 0 AND
           meter_raw_data_id >= 2846459 --i.e. where received_dtm > DATE '2020-06-26' or thereabouts
    )
    LOOP
      dbms_output.put_line(r.meter_raw_data_id);
      csr.temp_meter_monitor_pkg.ResubmitRawData(r.meter_raw_data_id, out_cur);
    END LOOP;

    security.user_pkg.logonadmin();
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

DROP PACKAGE csr.temp_meter_monitor_pkg;

@update_tail
