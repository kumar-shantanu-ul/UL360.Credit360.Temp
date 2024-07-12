-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'EST_BUILDING'
	   AND column_name = 'PREV_REGION_SID';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_BUILDING ADD (PREV_REGION_SID NUMBER(10))';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'EST_SPACE'
	   AND column_name = 'PREV_REGION_SID';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_SPACE ADD (PREV_REGION_SID NUMBER(10))';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'FK_EST_BLDNG_PRGN';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_BUILDING ADD CONSTRAINT FK_EST_BLDNG_PRGN FOREIGN KEY (APP_SID, PREV_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'FK_EST_SPACE_PRGN';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_SPACE ADD CONSTRAINT FK_EST_SPACE_PRGN FOREIGN KEY (APP_SID, PREV_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	END IF;
END;
/

DECLARE
	index_already_exists EXCEPTION;
	PRAGMA exception_init(index_already_exists, -955);
	table_doesnt_exists EXCEPTION;
	PRAGMA exception_init(table_doesnt_exists, -942);
	already_indexed EXCEPTION;
	PRAGMA exception_init(already_indexed, -1408);

	TYPE t_indexes IS TABLE OF VARCHAR2(2000);
	v_indexes t_indexes;
BEGIN	
	v_indexes := t_indexes(
		'create index csr.ix_est_building_prev_region_s on csr.est_building (app_sid, prev_region_sid)',
		'create index csr.ix_est_energy_me_prev_region_s on csr.est_energy_meter (app_sid, prev_region_sid)',
		'create index csr.ix_est_space_prev_region_s on csr.est_space (app_sid, prev_region_sid)',
		'create index csr.ix_est_water_met_prev_region_s on csr.est_water_meter (app_sid, prev_region_sid)'

	);
	
	FOR i IN 1 .. v_indexes.COUNT LOOP
		BEGIN
			EXECUTE IMMEDIATE v_indexes(i);
		EXCEPTION
			WHEN index_already_exists THEN
				NULL;
			WHEN table_doesnt_exists THEN
				NULL;
			WHEN already_indexed THEN
				NULL;
		END;	
	END LOOP;
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
