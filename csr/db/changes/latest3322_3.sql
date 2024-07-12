-- Please update version.sql too -- this keeps clean builds in sync
define version=3322
define minor_version=3
@update_header

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
-- 96 rows
DELETE FROM csr.emission_factor_profile_factor pf
 WHERE (pf.app_sid, pf.profile_id, pf.factor_type_id) IN (
	SELECT pf.app_sid, pf.profile_id, pf.factor_type_id
	  FROM csr.emission_factor_profile_factor pf
	  JOIN csr.factor_type ft ON ft.factor_type_id = pf.factor_type_id
	 WHERE ft.std_measure_id IS NULL
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
