-- Please update version.sql too -- this keeps clean builds in sync
define version=558
@update_header

alter table customer drop constraint ck_aggregation_engine_version;
alter table customer add constraint ck_aggregation_engine_version check (aggregation_engine_version in (1,2,3,4));

CREATE OR REPLACE VIEW v$calc_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND cd.dep_type = 1 -- csr_data_pkg.DEP_ON_INDICATOR
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.parent_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE cd.dep_type = 2 -- csr_data_pkg.DEP_ON_CHILDREN
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND (
			(ci.map_to_ind_sid IS NULL AND i.map_to_ind_sid IS NULL) -- indicators
			OR
			(ci.map_to_ind_sid IS NOT NULL AND ci.ind_sid != gi.ind_sid AND ci.gas_type_id = gi.gas_type_id) -- gas
	)
;

set define off
@..\stored_calc_datasource_pkg
@..\calc_pkg
@..\stored_calc_datasource_body
@..\calc_body
@..\indicator_body

grant execute on stored_calc_datasource_pkg to web_user;

@update_tail
