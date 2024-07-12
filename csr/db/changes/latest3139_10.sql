-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD calc_future_window NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csr.customer ADD CONSTRAINT chk_calc_future_window CHECK (calc_future_window >= 1 AND calc_future_window < 15);
ALTER TABLE csrimp.customer ADD calc_future_window NUMBER(2) NOT NULL;
ALTER TABLE csrimp.customer ADD CONSTRAINT chk_calc_future_window CHECK (calc_future_window >= 1 AND calc_future_window < 15);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (40, 'Set calc end of time window', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the number of years to bound calculation "end of time"', 'SetCalcFutureWindow', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (40, 'Number of years', 'How far forward should calculations extend', 0, 1, 0);
END;
/

BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.REFRESH_CALC_WINDOWS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.customer_pkg.RefreshCalcWindows; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1), 'YYYY/MM/DD') || ' 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1;BYHOUR=02;BYMINUTE=00;BYSECOND=00',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Refresh calculation start/end time window for all customers'
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\customer_pkg
@..\util_script_pkg

@..\csr_app_body
@..\customer_body
@..\schema_body
@..\util_script_body
@..\csrimp\imp_body

@update_tail

