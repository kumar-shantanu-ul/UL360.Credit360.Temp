-- shows delegations in current reporting period involving users who are inactive or trashed
WITH trashed AS  (
	SELECT sid_id
	  FROM security.securable_object
	 START WITH sid_id = securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Trash')
	CONNECT BY PRIOR sid_id = parent_sid_id
)
select d.delegation_sid, d.name, csR_user_sid, cu.full_name, 
	case when t.sid_id is null then 'Inactive' else 'Trashed' end status
  from csr_user cu, security.user_Table ut, delegation_user du, delegation d, trashed t, customer c, reporting_period rp
 where d.app_sid = c.app_sid
   and cu.csr_user_sid = ut.sid_id 
   and account_enabled = 0 
   and du.user_sid = cu.csr_user_sid 
   and du.app_sid = cu.app_sid
   and du.delegation_sid =d.delegation_sid 
   and du.app_sid = d.app_sid
   AND c.current_reporting_period_sid = rp.reporting_period_sid
   and c.app_sid = rp.app_sid
   and d.start_dtm >= rp.start_dtm
   and d.end_dtm <= rp.end_dtm
   and d.app_sid = rp.app_sid
   and ut.sid_id= t.sid_id(+);
