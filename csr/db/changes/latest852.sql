-- Please update version.sql too -- this keeps clean builds in sync
define version=852
@update_header

INSERT INTO csr.delegation_ind (app_sid, delegation_sid, ind_sid, pos, description, visibility)
	SELECT di.app_sid, di.delegation_sid, i.ind_sid, 0, i.description, 'HIDE'
	  FROM csr.delegation_ind di, csr.delegation_grid_aggregate_ind dgai, csr.ind i
	 WHERE i.app_sid = dgai.app_sid AND i.ind_sid = dgai.aggregate_to_ind_sid
	   AND di.app_sid = dgai.app_sid AND di.ind_sid = dgai.ind_sid
	   AND (dgai.app_sid, dgai.aggregate_to_ind_sid) NOT IN (SELECT app_sid, ind_sid
					   										   FROM csr.delegation_ind
					   										  WHERE delegation_sid = di.delegation_sid);

@../delegation_body

@update_tail
