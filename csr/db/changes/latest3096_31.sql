-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	FOR r IN (SELECT 1 FROM all_indexes WHERE owner='CSR' AND index_name='UK_FACTOR_1') LOOP
		EXECUTE IMMEDIATE 'DROP INDEX csr.UK_FACTOR_1';
	END LOOP;
END;
/
CREATE UNIQUE INDEX CSR.UK_FACTOR_1 ON CSR.FACTOR (
 APP_SID, FACTOR_TYPE_ID, NVL(GEO_COUNTRY, 'XX'), NVL(GEO_REGION, 'XX'), NVL(EGRID_REF, 'XX'), NVL(REGION_SID, -1), START_DTM, END_DTM, GAS_TYPE_ID,
  NVL(std_factor_id, -is_selected), NVL(custom_factor_id, -is_selected)
);

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
