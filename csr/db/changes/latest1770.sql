-- Please update version.sql too -- this keeps clean builds in sync
define version=1770
@update_header

CREATE OR REPLACE VIEW CHEM.V$AUDIT_LOG AS
	 SELECT su.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id, 
		c.cas_code, c.name,  
		s.ref substance_ref, s.description substance_description,
		sr.waiver_status_id, sr.region_sid, su.start_dtm, su.end_dtm, 
		pd.to_air_pct * su.mass_value * sc.pct_composition air_mass_value,
		pd.to_water_pct * su.mass_value * sc.pct_composition water_mass_value,
		su.mass_value * sc.pct_composition cas_weight,
		pd.to_air_pct,
		pd.to_water_pct,
		pd.to_waste_pct,
		pd.to_product_pct,
		pd.remaining_pct,
		root_delegation_sid,
		su.changed_by,
		su.created_dtm,
		su.mass_value,
		su.retired_dtm
	  FROM substance_use su
	  JOIN substance s ON su.substance_id = s.substance_id AND su.app_sid = s.app_sid
	  JOIN substance_region sr ON su.substance_id = sr.substance_id AND su.region_sid = sr.region_sid AND su.app_sid = sr.app_sid
	  LEFT JOIN process_destination pd ON su.process_destination_id = pd.process_destination_id AND su.app_sid = pd.app_sid 
	  JOIN substance_cas sc ON s.substance_id = sc.substance_id
	  JOIN cas c ON sc.cas_code = c.cas_code
	  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code 
	  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

@..\chem\substance_body

@update_tail