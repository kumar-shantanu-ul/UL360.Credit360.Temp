
SELECT case 
		when aggregate = 'NONE' THEN 'Major problem'
		when aggregate in ('DOWN', 'FORCE DOWN') THEN 'Potential problem if data is not entered at top level region'
	end severity,  
	calc_ind_sid, ind_sid,
	indicator_pkg.INTERNAL_GetIndPathString(calc_ind_sid) calc_ind_path, 
	indicator_pkg.INTERNAL_GetIndPathString(ind_sid) dep_ind_path
   FROM (
	-- look for non-stored calculations where a dependency is NOT set to aggregate
	select cd.calc_ind_sid, di.ind_sid, di.aggregate
	  from calc_dependency cd, ind i, customer c, ind di
	 where c.host='rbs3.credit360.com'
	   and c.app_sid = i.app_Sid
	   and i.ind_type IN (1)
	   and i.ind_sid = cd.calc_ind_sid
       and cd.ind_sid = di.ind_sid
	   and cd.dep_type =1
	   and di.aggregate IN ('NONE', 'DOWN', 'FORCE DOWN') 
	   and i.aggregate != 'NONE'
	 union -- effectively will do a distinct on the two sets
	select cd.calc_ind_sid, ic.ind_sid, ic.aggregate
	  from calc_dependency cd, ind i, customer c, ind ic
	 where c.host='rbs3.credit360.com'
	   and c.app_sid = i.app_Sid
	   and i.ind_type IN (1)
	   and i.ind_sid = cd.calc_ind_sid
	   and cd.ind_sid = ic.parent_sid 
	   and cd.dep_type =2
	   and ic.aggregate IN ('NONE', 'DOWN', 'FORCE DOWN')
       and i.aggregate != 'NONE'
  )
 ORDER BY calc_ind_path