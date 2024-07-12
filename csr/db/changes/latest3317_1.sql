-- Please update version.sql too -- this keeps clean builds in sync
define version=3317
define minor_version=1
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

-- remove empty profile factors
DELETE FROM csr.emission_factor_profile_factor
 WHERE (app_sid, profile_id, factor_type_id, custom_factor_set_id, region_sid, geo_country) IN (
	SELECT efpf.app_sid, efpf.profile_id, efpf.factor_type_id, efpf.custom_factor_set_id, efpf.region_sid, efpf.geo_country
      FROM csr.emission_factor_profile_factor efpf
      LEFT JOIN csr.factor f ON f.factor_type_id = efpf.factor_type_id AND f.region_sid = efpf.region_sid
     WHERE efpf.region_sid IS NOT NULL 
	   AND f.factor_type_id IS NULL
	);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
