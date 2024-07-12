-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.forecasting_rule drop constraint fk_forecast_rule_scenario;

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.FORECASTING_RULE ADD CONSTRAINT FK_FORECAST_RULE_SCENARIO_RULE FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID) REFERENCES CSR.SCENARIO_RULE (APP_SID, SCENARIO_SID, RULE_ID)';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-02275: such a referential constraint already exists in the table
		IF SQLCODE != -2275 THEN
			RAISE;
		END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
