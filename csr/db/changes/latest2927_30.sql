-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- update nullability of csrimp.metric_dashboard_ind to match csr.metric_dashboard_ind
DECLARE
	PROCEDURE makeNull(in_col IN VARCHAR2)
	AS
	BEGIN
		FOR r IN (SELECT 1 FROM all_tab_columns WHERE owner = 'CSRIMP' AND table_name = 'METRIC_DASHBOARD_IND' AND column_name = in_col AND nullable = 'N') LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE csrimp.metric_dashboard_ind MODIFY '||in_col||' NULL';
		END LOOP;
	END;

	PROCEDURE makeNotNull(in_col IN VARCHAR2)
	AS
	BEGIN
		FOR r IN (SELECT 1 FROM all_tab_columns WHERE owner = 'CSRIMP' AND table_name = 'METRIC_DASHBOARD_IND' AND column_name = in_col AND nullable = 'Y') LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE csrimp.metric_dashboard_ind MODIFY '||in_col||' NOT NULL';
		END LOOP;
	END;
BEGIN
	makeNull('INTEN_VIEW_SCENARIO_RUN_SID');
	makeNotNull('INTEN_VIEW_FLOOR_AREA_IND_SID');
	makeNull('ABSOL_VIEW_SCENARIO_RUN_SID');
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

@..\schema_body

@update_tail
