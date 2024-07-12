-- Please update version.sql too -- this keeps clean builds in sync
define version=3268
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW "CHEM"."V$OUTPUTS" 
AS
SELECT spu.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id,
	   c.cas_code, c.name, c.is_voc, c.category, s.substance_Id,
	   s.ref substance_ref, s.description substance_description,
	   sr.waiver_status_id, sr.region_sid, spu.start_dtm, spu.end_dtm,
	   spcd.to_air_pct * spu.mass_value * sc.pct_composition air_mass_value,
	   spcd.to_water_pct * spu.mass_value * sc.pct_composition water_mass_value,
	   spu.mass_value * sc.pct_composition cas_weight,
	   spcd.to_air_pct,
	   spcd.to_water_pct,
	   spcd.to_waste_pct,
	   spcd.to_product_pct,
	   spcd.remaining_pct,
	   root_delegation_sid,
	   sr.local_ref,
	   sr.first_used_dtm,
	   srp.first_used_dtm process_first_used_dtm
  FROM chem.substance_process_use spu
  JOIN chem.substance_region_process srp
    ON spu.substance_id = srp.substance_id
   AND spu.region_sid = srp.region_sid
   AND spu.process_id = srp.process_id
   AND spu.app_sid = srp.app_sid
  JOIN chem.substance_region sr ON srp.substance_id = sr.substance_id AND srp.region_sid = sr.region_sid AND srp.app_sid = sr.app_sid
  JOIN chem.substance s ON sr.substance_id = s.substance_id AND sr.app_sid = s.app_sid
  JOIN chem.substance_cas sc ON s.substance_id = sc.substance_id
  JOIN chem.cas c ON sc.cas_code = c.cas_code
  LEFT JOIN chem.substance_process_cas_dest spcd
    ON spu.substance_process_use_id = spcd.substance_process_use_id
   AND spu.substance_id = spcd.substance_id
   AND spu.app_sid = spcd.app_sid
   AND c.cas_code = spcd.cas_code
  LEFT JOIN chem.cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN chem.cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chem/report_body
@../chem/substance_body

@update_tail
