select x.calc_ind_sid, x.ind_sid, 
	indicator_pkg.INTERNAL_GetIndPathString(x.calc_ind_sid) calc_ind_path, 
	indicator_pkg.INTERNAL_GetIndPathString(x.ind_sid) dep_ind_path
  from (
	select cd.calc_ind_sid, cd.ind_sid
	  from calc_dependency cd, ind i, customer c
	 where c.host='rbs3.credit360.com'
	   and c.app_sid = i.app_Sid
	   and i.ind_type IN (1,2)
	   and i.ind_sid = cd.calc_ind_sid
	   and cd.dep_type =1
	 union
	select cd.calc_ind_sid, ic.ind_sid
	  from calc_dependency cd, ind i, customer c, ind ic
	 where c.host='rbs3.credit360.com'
	   and c.app_sid = i.app_Sid
	   and i.ind_type IN (1,2)
	   and i.ind_sid = cd.calc_ind_sid
	   and cd.ind_sid = ic.parent_sid 
	   and cd.dep_type =2
 )x
where connect_by_iscycle  = 1
connect by nocycle prior calc_ind_sid = ind_sid;
