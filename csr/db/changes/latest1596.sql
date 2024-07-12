define version=1596
@update_header

ALTER TABLE chain.filter_value RENAME COLUMN dtm_value TO start_dtm_value;
ALTER TABLE chain.filter_value ADD end_dtm_value DATE;

CREATE OR REPLACE VIEW CHAIN.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value, fv.num_value, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid, NVL(NVL(r.description, cu.full_name), cr.name) description
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
@../chain/filter_pkg
@../chain/filter_body
@../issue_body

	 
@update_tail
