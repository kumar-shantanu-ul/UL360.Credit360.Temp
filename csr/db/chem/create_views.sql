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
  
CREATE OR REPLACE VIEW "CHEM"."V$AUDIT_LOG"
AS
SELECT spuc.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id,
	c.cas_code, c.name,
	s.ref substance_ref, s.description substance_description,
	sr.waiver_status_id, sr.region_sid, spuc.start_dtm, spuc.end_dtm,
	spcdc.to_air_pct * spuc.mass_value * sc.pct_composition air_mass_value,
	spcdc.to_water_pct * spuc.mass_value * sc.pct_composition water_mass_value,
	spuc.mass_value * sc.pct_composition cas_weight,
	spcdc.to_air_pct,
	spcdc.to_water_pct,
	spcdc.to_waste_pct,
	spcdc.to_product_pct,
	spcdc.remaining_pct,
	root_delegation_sid,
	spuc.changed_by,
	spuc.changed_dtm,
	spuc.mass_value,
	spuc.retired_dtm
  FROM substance_process_use_change spuc
  JOIN substance s ON spuc.substance_id = s.substance_id AND spuc.app_sid = s.app_sid
  JOIN substance_region sr ON spuc.substance_id = sr.substance_id AND spuc.region_sid = sr.region_sid AND spuc.app_sid = sr.app_sid
  LEFT JOIN subst_process_cas_dest_change spcdc
    ON spuc.subst_proc_use_change_id = spcdc.subst_proc_use_change_id
   AND spuc.app_sid = spcdc.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;
  
CREATE OR REPLACE VIEW chem.v$my_substance_region AS
 SELECT sr.app_sid, sr.region_sid, sr.substance_id, MAX(fsr.is_editable) is_editable
  FROM csr.region_role_member rrm
  JOIN csr.role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
  JOIN csr.region rg ON rrm.region_sid = rg.region_sid AND rrm.app_Sid = rg.app_sid
  JOIN csr.flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
  JOIN csr.flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
  JOIN csr.flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
  JOIN chem.substance_region sr ON fi.flow_item_id = sr.flow_item_id AND fi.app_sid = sr.app_sid AND rg.region_sid = sr.region_sid AND rg.app_sid = sr.app_sid
 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
 GROUP BY sr.app_sid, sr.region_sid, sr.substance_id;
 
CREATE OR REPLACE VIEW chem.v$substance_region 
	AS
SELECT sr.app_sid, sr.region_sid, sr.substance_id, sr.flow_item_id, 
	fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
	fs.state_colour current_state_colour, sr.first_used_dtm, sr.local_ref, rg.active
  FROM chem.substance_region sr
  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_Item_id
  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
  JOIN csr.region rg ON sr.region_sid = rg.region_sid AND sr.app_Sid = rg.app_sid;
