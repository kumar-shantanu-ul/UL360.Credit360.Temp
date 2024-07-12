-- Please update version.sql too -- this keeps clean builds in sync
define version=888
@update_header

create or replace view csr.v$ind_selection_group_dep as
	select isg.app_sid, isg.master_ind_sid, isg.master_ind_sid ind_sid, i.description
	  from csr.ind_selection_group isg, csr.ind i
	 where i.app_sid = isg.app_sid and i.ind_sid = isg.master_ind_sid
	 union all
	select isgm.app_sid, isgm.master_ind_sid, isgm.ind_sid, isgm.description
	  from csr.ind_selection_group_member isgm;

-- hide any child inds in selection groups in delegations
UPDATE csr.delegation_ind
   SET visibility = 'HIDE'
 WHERE (app_sid, ind_sid) IN (SELECT app_sid, ind_sid FROM csr.ind_selection_group_member);
 
-- make sure any fiddled with delegations have all the correct inds in place
INSERT INTO csr.delegation_ind (app_sid, delegation_sid, ind_sid, pos, description, visibility)
	SELECT d.app_sid, d.delegation_sid, isgm.ind_sid, 0, isgm.description, 'HIDE'
	  FROM csr.ind_selection_group_member isgm, csr.delegation d
	 WHERE (isgm.app_sid, isgm.master_ind_sid) IN 
	 		(SELECT isgd.app_sid, isgd.master_ind_sid
			   FROM csr.v$ind_selection_group_dep isgd, csr.delegation_ind di
			  WHERE di.app_sid = isgd.app_sid AND di.ind_sid = isgd.ind_sid
			    AND di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid)
	   AND (isgm.app_sid, isgm.ind_sid) NOT IN 
	   		(SELECT app_sid, ind_sid
	   		   FROM csr.delegation_ind
	   		  WHERE delegation_sid = d.delegation_sid);

@../delegation_body
@../deleg_plan_body

@update_tail
