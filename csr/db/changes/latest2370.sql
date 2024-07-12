-- Please update version.sql too -- this keeps clean builds in sync
define version=2370
@update_header

CREATE OR REPLACE VIEW csr.v$calc_direct_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
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
	   AND cd.dep_type IN (1, 2) -- csr_data_pkg.DEP_ON_INDICATOR, csr_data_pkg.DEP_ON_CHILDREN
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, mi.calc_start_dtm_adjustment, mi.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	  JOIN ind mi
	        ON mm.app_sid = mi.app_sid
	       AND mm.model_sid = mi.ind_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

@../indicator_body
@../trash_body

@update_tail
