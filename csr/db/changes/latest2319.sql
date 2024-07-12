-- Please update version.sql too -- this keeps clean builds in sync
define version=2319
@update_header




alter table chain.filter_value add MIN_NUM_VAL NUMBER(10,0) NULL;
	alter table chain.filter_value add MAX_NUM_VAL NUMBER(10,0) NULL;
	
	
	CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, Fv.Min_Num_Val, Fv.Max_Num_Val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END) description
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN chain.filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');


@..\chain\filter_pkg
@..\chain\filter_body

@update_tail
