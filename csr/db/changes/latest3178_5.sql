-- Please update version.sql too -- this keeps clean builds in sync
define version=3178
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$comp_item_rollout_location AS
	SELECT cir.app_sid, cir.compliance_item_id,
			listagg(pc.name, ', ') within GROUP(ORDER BY pc.name) AS countries,
			listagg(pr.name, ', ') within GROUP(order by pr.name) AS regions,
			listagg(rg.group_name, ', ') within GROUP(ORDER BY region_group_id) AS region_group_names,
			listagg(cg.group_name, ', ') within GROUP(ORDER BY country_group_id) AS country_group_names
	  FROM csr.compliance_item_rollout cir
	  LEFT JOIN postcode.country pc ON cir.country = pc.country
	  LEFT JOIN postcode.region pr ON cir.country = pr.country AND cir.region = pr.region
	  LEFT JOIN csr.region_group rg ON cir.region_group = rg.region_group_id
	  LEFT JOIN csr.country_group cg ON cir.country_group = cg.country_group_id
	 GROUP BY cir.app_sid, cir.compliance_item_id
;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
