-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- fix up index accidentally created as upd instead of csr
BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX ix_scenario_data_source_run';
	EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_scenario_data_source_run ON csr.scenario (app_sid, data_source_run_sid)';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-01418: specified index does not exist
		IF SQLCODE != -1418 THEN
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
