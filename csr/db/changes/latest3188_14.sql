-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.scenario
  ADD DONT_RUN_AGGREGATE_INDICATORS NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE csr.scenario
  ADD CONSTRAINT ck_dont_run_agg_inds CHECK (DONT_RUN_AGGREGATE_INDICATORS IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- Set all approval dashboard scenarios to not run aggregate indicators
BEGIN
	UPDATE csr.scenario
	   SET dont_run_aggregate_indicators = 1
	 WHERE scenario_sid in (
		SELECT scenario_sid 
		  FROM csr.scenario_run sr
		  JOIN csr.approval_dashboard ad ON (
			sr.scenario_run_sid = ad.active_period_scenario_run_sid OR 
			sr.scenario_run_sid = ad.signed_off_scenario_run_sid
		)
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../scenario_body
@../approval_dashboard_body

@update_tail
