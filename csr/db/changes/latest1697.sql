-- Please update version too -- this keeps clean builds in sync
define version=1697
@update_header

alter table csr.scenario add equality_epsilon number;
alter table csr.customer add equality_epsilon number default 0 not null;

-- clean out junk in csrimp
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.scenario add equality_epsilon number not null;
alter table csrimp.customer add equality_epsilon number;
alter table csr.ind add calc_output_round_dp number(10);
alter table csrimp.ind add calc_output_round_dp number(10);
create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisible, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

@../indicator_pkg
@../indicator_body
@../vb_legacy_body
@../pending_datasource_body
@../calc_body
@../csrimp/imp_body
@../range_body
@../dataview_body
@../delegation_body
@../stored_calc_datasource_body
@../dataset_legacy_body
@../pending_body
@../csr_data_body
@../datasource_body
@../val_datasource_body
@../schema_body
@../scenario_body
@../csr_app_body

@update_tail
