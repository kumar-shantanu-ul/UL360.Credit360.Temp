-- Please update version.sql too -- this keeps clean builds in sync
define version=1302
@update_header

CREATE OR REPLACE VIEW CHEM.V$OUTPUTS AS
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
		root_delegation_sid
	  FROM substance_use su
	  JOIN substance s ON su.substance_id = s.substance_id AND su.app_sid = s.app_sid
	  JOIN substance_region sr ON su.substance_id = sr.substance_id AND su.region_sid = sr.region_sid AND su.app_sid = sr.app_sid
	  LEFT JOIN process_destination pd ON su.process_destination_id = pd.process_destination_id AND su.app_sid = pd.app_sid 
	  JOIN substance_cas sc ON s.substance_id = sc.substance_id
	  JOIN cas c ON sc.cas_code = c.cas_code
	  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code 
	  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;
			
-- there's a limit of 17 CAS codes per substance but this is actually pretty much the maximum that you'll
-- get on an MSDS for a substance.
CREATE OR REPLACE VIEW chem.v$flat_substance_cas AS
	SELECT app_sid, substance_id, ref, description, classification_id, classification, manufacturer,
		MAX(DECODE(row_rank, 1, cas_comp)) cas_comp_0,
		MAX(DECODE(row_rank, 1, cas_code)) cas_code_0,
		MAX(DECODE(row_rank, 1, pct_composition)) perc_0,
		MAX(DECODE(row_rank, 2, cas_comp)) cas_comp_1,
		MAX(DECODE(row_rank, 2, cas_code)) cas_code_1,
		MAX(DECODE(row_rank, 2, pct_composition)) perc_1,
		MAX(DECODE(row_rank, 3, cas_comp)) cas_comp_2,
		MAX(DECODE(row_rank, 3, cas_code)) cas_code_2,
		MAX(DECODE(row_rank, 3, pct_composition)) perc_2,
		MAX(DECODE(row_rank, 4, cas_comp)) cas_comp_3,
		MAX(DECODE(row_rank, 4, cas_code)) cas_code_3,
		MAX(DECODE(row_rank, 4, pct_composition)) perc_3,
		MAX(DECODE(row_rank, 5, cas_comp)) cas_comp_4,
		MAX(DECODE(row_rank, 5, cas_code)) cas_code_4,
		MAX(DECODE(row_rank, 5, pct_composition)) perc_4,
		MAX(DECODE(row_rank, 6, cas_comp)) cas_comp_5,
		MAX(DECODE(row_rank, 6, cas_code)) cas_code_5,
		MAX(DECODE(row_rank, 6, pct_composition)) perc_5,
		MAX(DECODE(row_rank, 7, cas_comp)) cas_comp_6,
		MAX(DECODE(row_rank, 7, cas_code)) cas_code_6,
		MAX(DECODE(row_rank, 7, pct_composition)) perc_6,
		MAX(DECODE(row_rank, 8, cas_comp)) cas_comp_7,
		MAX(DECODE(row_rank, 8, cas_code)) cas_code_7,
		MAX(DECODE(row_rank, 8, pct_composition)) perc_7,
		MAX(DECODE(row_rank, 9, cas_comp)) cas_comp_8,
		MAX(DECODE(row_rank, 9, cas_code)) cas_code_8,
		MAX(DECODE(row_rank, 9, pct_composition)) perc_8,
		MAX(DECODE(row_rank, 10, cas_comp)) cas_comp_9,
		MAX(DECODE(row_rank, 10, cas_code)) cas_code_9,
		MAX(DECODE(row_rank, 10, pct_composition)) perc_9,
		MAX(DECODE(row_rank, 11, cas_comp)) cas_comp_10,
		MAX(DECODE(row_rank, 11, cas_code)) cas_code_10,
		MAX(DECODE(row_rank, 11, pct_composition)) perc_10,
		MAX(DECODE(row_rank, 12, cas_comp)) cas_comp_11,
		MAX(DECODE(row_rank, 12, cas_code)) cas_code_11,
		MAX(DECODE(row_rank, 12, pct_composition)) perc_11,
		MAX(DECODE(row_rank, 13, cas_comp)) cas_comp_12,
		MAX(DECODE(row_rank, 13, cas_code)) cas_code_12,
		MAX(DECODE(row_rank, 13, pct_composition)) perc_12,
		MAX(DECODE(row_rank, 14, cas_comp)) cas_comp_13,
		MAX(DECODE(row_rank, 14, cas_code)) cas_code_13,
		MAX(DECODE(row_rank, 14, pct_composition)) perc_13,
		MAX(DECODE(row_rank, 15, cas_comp)) cas_comp_14,
		MAX(DECODE(row_rank, 15, cas_code)) cas_code_14,
		MAX(DECODE(row_rank, 15, pct_composition)) perc_14,
		MAX(DECODE(row_rank, 16, cas_comp)) cas_comp_15,
		MAX(DECODE(row_rank, 16, cas_code)) cas_code_15,
		MAX(DECODE(row_rank, 16, pct_composition)) perc_15,
		MAX(DECODE(row_rank, 17, cas_comp)) cas_comp_16,
		MAX(DECODE(row_rank, 17, cas_code)) cas_code_16,
		MAX(DECODE(row_rank, 17, pct_composition)) perc_16
	FROM (	
		SELECT s.app_sid, s.substance_id, s.ref, s.description, s.classification_id, cl.description classification, 
			m.name manufacturer, 
			rank() OVER (PARTITION BY s.substance_id ORDER BY sc.cas_code) row_rank,
			sc.cas_code cas_code, sc.pct_composition pct_composition, c.name cas_comp
		 FROM substance s
			JOIN substance_cas sc ON s.substance_id = sc.substance_id
			JOIN cas c ON c.cas_code = sc.cas_code
			JOIN classification cl on cl.classification_id = s.classification_id
			JOIN manufacturer m on m.manufacturer_id = s.manufacturer_id
	)x
	GROUP BY app_sid, substance_id, ref, description, classification_id, classification, manufacturer;
	
grant references on csr.region to chem;
grant references on csr.customer to chem;
grant references on csr.file_upload to chem;

grant select on aspen2.filecache to chem;
grant select on csr.region to chem;
grant select on csr.sheet to chem;
grant select on csr.csr_user to chem;
grant select on csr.sheet_history to chem;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
