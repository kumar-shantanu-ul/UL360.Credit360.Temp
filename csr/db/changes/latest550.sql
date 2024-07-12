-- Please update version.sql too -- this keeps clean builds in sync
define version=550
@update_header

begin
	for r in (select index_name from user_indexes where index_name='IX_IND_GAS_TYPE') loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/

create index ix_ind_gas_type on ind(app_sid, gas_type_id) tablespace indx;

CREATE OR REPLACE VIEW v$calc_dependency (app_sid, calc_ind_sid, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment
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
		   AND cd.calc_ind_sid != gi.ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
	 WHERE i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND cd.dep_type = 1 -- csr_data_pkg.DEP_ON_INDICATOR
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment
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
		   AND cd.calc_ind_sid != gi.ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
	 WHERE cd.dep_type = 2 -- csr_data_pkg.DEP_ON_CHILDREN
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND (
			(ci.map_to_ind_sid IS NULL AND i.map_to_ind_sid IS NULL) -- indicators
			OR
			(ci.map_to_ind_sid IS NOT NULL AND ci.ind_sid != gi.ind_sid AND ci.gas_type_id = gi.gas_type_id) -- gas
	)
;

@update_tail
