-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.ind ADD (
    TOLERANCE_NUMBER_OF_PERIODS  NUMBER(10, 0),
    TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE    NUMBER(10, 0)
);

ALTER TABLE csrimp.ind ADD (
    TOLERANCE_NUMBER_OF_PERIODS  NUMBER(10, 0),
    TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE    NUMBER(10, 0)
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type,
		   i.pct_upper_tolerance, i.pct_lower_tolerance, 
		   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
		   i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm,
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid,
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid,
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize,
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../indicator_pkg

@../dataview_body
@../delegation_body
@../indicator_api_body
@../indicator_body
@../schema_body
@../stored_calc_datasource_body
@../val_datasource_body

@../csrimp/imp_body

@update_tail
