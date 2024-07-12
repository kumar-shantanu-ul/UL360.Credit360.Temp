-- Please update version.sql too -- this keeps clean builds in sync
define version=636
@update_header


alter table csr.model add load_state char(1) default 'N' not null;
alter table csr.model add constraint ck_load_state check (load_state in ('N', 'L', 'U'));

insert into csr.model_map_type (model_map_type_id, map_type) values (7, 'Exported Formula');



CREATE OR REPLACE VIEW csr.v$calc_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment) AS
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
	 WHERE (i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	        OR EXISTS(SELECT * FROM model_map WHERE app_sid = cd.app_sid and model_sid = cd.ind_sid))
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
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, 0
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

@../csr_data_pkg
@../datasource_pkg
@../datasource_body
@../indicator_pkg
@../indicator_body
@../model_pkg
@../model_body
@../stored_calc_datasource_body
@../val_datasource_pkg
@../val_datasource_body

@update_tail
