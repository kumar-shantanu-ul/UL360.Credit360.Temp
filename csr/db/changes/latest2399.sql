-- Please update version.sql too -- this keeps clean builds in sync
define version=2399
@update_header

create or replace force view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_ind as
	select di.app_sid, di.delegation_sid, di.ind_sid, di.mandatory, NVL(did.description, id.description) description,
		   di.pos, di.section_key, di.var_expl_group_id, di.visibility, di.css_class, di.allowed_na
	  from delegation_ind di
	  join ind_description id 
	    on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_ind_description did
	    on di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
	   and di.ind_sid = did.ind_sid AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$region as
	select r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, rd.description, r.active, 
		   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type, 
		   r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, 
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden, r.last_modified_dtm, r.region_ref
	  from region r, region_description rd
	 where r.app_sid = rd.app_sid and r.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_region as
	select dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility, dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
	  from delegation_region dr
	  join region_description rd
	    on dr.app_sid = rd.app_sid and dr.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_region_description drd
	    on dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   and dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
	  
CREATE OR REPLACE VIEW csr.v$resolved_region_description AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, rd.description, r.link_to_region_sid, r.parent_sid,
		   r.name, r.active, r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type,
		   r.lookup_key, r.region_ref, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude,
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden,  r.last_modified_dtm
	  FROM v$resolved_region r
	  JOIN region_description rd ON NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');


@update_tail
