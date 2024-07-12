-- Please update version.sql too -- this keeps clean builds in sync
define version=1903
@update_header


ALTER TABLE CSR.REGION ADD (
	REGION_REF VARCHAR2(255)
);

UPDATE csr.region SET region_ref = lookup_key;

create or replace view csr.v$region as
	select r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, rd.description, r.active, 
		   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type, 
		   r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, 
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden, r.last_modified_dtm, r.region_ref
	  from region r, region_description rd
	 where r.app_sid = rd.app_sid and r.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
	   
create or replace view csr.imp_val_mapped 
	(ind_description, region_description, ind_sid, region_sid, imp_ind_description, imp_region_description, 
	 imp_val_id, imp_ind_id, imp_region_id, unknown, start_dtm, end_dtm, val, file_sid, imp_session_sid, 
	 set_val_id, imp_measure_id, tolerance_type, pct_upper_tolerance, pct_lower_tolerance, note, lookup_key, region_ref,
	 map_entity, roll_forward, acquisition_dtm, a, b, c, calc_description, normalize, do_temporal_aggregation) as	 
	select i.description, r.description, i.ind_sid, r.region_sid, ii.description, ir.description, iv.imp_val_id, 
	       iv.imp_ind_id, iv.imp_region_id, iv.unknown, iv.start_dtm, iv.end_dtm, iv.val, iv.file_sid, iv.imp_session_sid, 
	       iv.set_val_id, iv.imp_measure_id, i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance, iv.note, 
	       r.lookup_key, r.region_ref, r.map_entity, i.roll_forward, r.acquisition_dtm, iv.a, iv.b, iv.c, i.calc_description, 
	       i.normalize, i.do_temporal_aggregation
	  from imp_val iv, imp_ind ii, imp_region ir, v$ind i, v$region r
	 where iv.app_sid = ii.app_sid and iv.imp_ind_id = ii.imp_ind_id 
	   and iv.app_sid = ir.app_sid and iv.imp_region_id = ir.imp_region_id
	   and ii.app_sid = i.app_sid and ii.maps_to_ind_sid = i.ind_sid 
	   and ir.app_sid = r.app_sid and ir.maps_to_region_sid = r.region_sid;


CREATE OR REPLACE VIEW csr.v$resolved_region AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid,
	  	   -- this pattern is a bit messier than NVL, but it avoids taking properties off the link
	  	   -- in the case that the property is unset on the region -- that's only possible if it's
	  	   -- nullable, but quite a few of the properties are.  They should not be set on the link,
	  	   -- but we don't want to return duff data because we do end up with links with properties.
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.name ELSE r.name END name,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.active ELSE r.active END active,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.pos ELSE r.pos END pos,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.info_xml ELSE r.info_xml END info_xml,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.flag ELSE r.flag END flag,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.acquisition_dtm ELSE r.acquisition_dtm END acquisition_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.disposal_dtm ELSE r.disposal_dtm END disposal_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_type ELSE r.region_type END region_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_ref ELSE r.region_ref END region_ref,
		   r.lookup_key, 
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_country ELSE r.geo_country END geo_country,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_region ELSE r.geo_region END geo_region,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_city_id ELSE r.geo_city_id END geo_city_id,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_longitude ELSE r.geo_longitude END geo_longitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_latitude ELSE r.geo_latitude END geo_latitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_type ELSE r.geo_type END geo_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.map_entity ELSE r.map_entity END map_entity,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref ELSE r.egrid_ref END egrid_ref,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref_overridden ELSE r.egrid_ref_overridden END egrid_ref_overridden,
		   -- If either the region or the region link is modified, then the resolved region
		   -- should appear to be modified.  GREATEST returns null if any of its arguments are
		   -- null, so the below ensures that we get the greatest non-null modified date.
		   GREATEST(NVL(r.last_modified_dtm, rl.last_modified_dtm),
				    NVL(rl.last_modified_dtm, r.last_modified_dtm)) last_modified_dtm
	  FROM region r
	  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid;

CREATE OR REPLACE VIEW csr.v$resolved_region_description AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, rd.description, r.link_to_region_sid, r.parent_sid,
		   r.name, r.active, r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type,
		   r.lookup_key, r.region_ref, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude,
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden,  r.last_modified_dtm
	  FROM v$resolved_region r
	  JOIN region_description rd ON NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;

CREATE OR REPLACE VIEW csr.v$my_property_full AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
        p.current_state_colour, p.role_sid, p.role_name, p.is_editable,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, p.pm_building_id
      FROM csr.v$my_property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid;

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can purge initiatives', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		null;
END;
/

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import initiatives', 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		null;
END;
/



@..\region_pkg
@..\property_pkg
@..\space_pkg

@..\region_body
@..\property_body
@..\delegation_body
@..\supplier_body
@..\energy_star_body
@..\space_body
@..\unit_test_body


@update_tail
