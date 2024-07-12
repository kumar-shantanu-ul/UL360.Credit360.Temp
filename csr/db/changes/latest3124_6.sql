-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	PROCEDURE RenameTable(s IN VARCHAR2, t IN VARCHAR2)
	AS
	BEGIN
		BEGIN
			--EXECUTE IMMEDIATE 'DROP TABLE '||t;
			--dbms_output.put_line('Dropped '||t);
			EXECUTE IMMEDIATE 'ALTER TABLE '||s||t||' RENAME TO '||t||'_old';
			dbms_output.put_line('Renamed '||t);
		EXCEPTION
			-- Ignore errors if tables are not present; they aren't likely to be on any non-live db's.
			WHEN OTHERS THEN
				IF SQLCODE = -942 THEN
					dbms_output.put_line('table '||t||' doesn''t exist');
				END IF;
				IF SQLCODE != -942 THEN
					dbms_output.put_line('Unable to rename '||t);
				END IF;
		END;
	END;
BEGIN
	RenameTable('csr.','ss_11752037');
	RenameTable('csr.','ss_11752037_period');
	RenameTable('csr.','ss_16572575');
	RenameTable('csr.','ss_16572575_period');
	RenameTable('csr.','ss_DB_ENERGY');
	RenameTable('csr.','ss_DB_ENERGY_period');
	RenameTable('csr.','ss_DELOITTE_ENERGY');
	RenameTable('csr.','ss_DELOITTE_ENERGY_period');
	RenameTable('csr.','ss_DELOITTE_TRAVEL');
	RenameTable('csr.','ss_DELOITTE_TRAVEL_period');
	RenameTable('csr.','ss_IMI_QUARTERLY_HOURS');
	RenameTable('csr.','ss_IMI_QUARTERLY_HOURS_period');
	RenameTable('csr.','ss_KPIS_CATEGORY');
	RenameTable('csr.','ss_KPIS_CATEGORY_period');
	RenameTable('csr.','ss_KPIS_TYPE');
	RenameTable('csr.','ss_KPIS_TYPE_period');
	RenameTable('csr.','ss_LINDE');
	RenameTable('csr.','ss_LINDE_period');
	RenameTable('csr.','ss_SNAPSHOT_ANNUALLY');
	RenameTable('csr.','ss_SNAPSHOT_ANNUALLY_period');
	RenameTable('csr.','ss_SNAPSHOT_HALF_YEARLY');
	RenameTable('csr.','ss_SNAPSHOT_HALF_YEARLY_period');
	RenameTable('csr.','ss_SNAPSHOT_HALFYEARLY');
	RenameTable('csr.','ss_SNAPSHOT_HALFYEARLY_period');
	RenameTable('csr.','ss_SNAPSHOT_QUARTERLY');
	RenameTable('csr.','ss_SNAPSHOT_QUARTERLY_period');
	RenameTable('csr.','ss_SR_ENERGY');
	RenameTable('csr.','ss_SR_ENERGY_period');
END;
/



-- Remove the fallout from the tag description change

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
