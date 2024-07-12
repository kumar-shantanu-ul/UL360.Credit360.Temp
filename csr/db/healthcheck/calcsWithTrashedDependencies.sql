exec user_pkg.logonadmin('volkerwessels.credit360.com');

WITH trashed AS (
	SELECT ind_sid
	  FROM ind
	 START WITH parent_sid = securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp,'Trash')
	CONNECT BY PRIOR ind_sid = parent_Sid
)
SELECT calc_ind_Sid, indicator_pkg.INTERNAL_GetIndPathString(calc_ind_sid), trashed_ind_sids
  FROM (
	SELECT cd.calc_ind_sid, stragg(cd.ind_sid) trashed_ind_sids
	  FROM trashed, calc_dependency cd
	 WHERE trashed.ind_sid = cd.ind_sid
	   AND calc_ind_sid NOT IN (
			SELECT ind_sid 
			  FROM trashed
		)
	 GROUP BY calc_ind_sid
);




 /*
 or
 
-- dependent calc indicators that aren't in the main indicator tree
select ind_sid
  from calc_dependency
 where calc_ind_sid in (
    select ind_sid
      from ind 
     start with ind_sid = (select ind_root_sid from customer)
    connect by prior ind_sid = parent_sid    
 )
 minus
    select ind_sid
      from ind 
     start with ind_sid = (select ind_root_sid from customer)
    connect by prior ind_sid = parent_sid
 ;
 */