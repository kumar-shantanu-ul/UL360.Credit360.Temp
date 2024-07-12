-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
GRANT CREATE TABLE TO CSR;

CREATE materialized view csr.meter_param_cache REFRESH FORCE ON DEMAND
START WITH TO_DATE('01-01-2021 00:01:00', 'DD-MM-YYYY HH24:MI:SS') NEXT SYSDATE + 1
AS
	SELECT app_sid, MIN(mld.start_dtm) min_start_date, MAX(mld.start_dtm) max_start_date
	  FROM csr.meter_live_data mld
	 GROUP BY app_sid;

REVOKE CREATE TABLE FROM CSR;


-- *** Data changes ***
-- RLS

-- Data
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_report_body

@update_tail
