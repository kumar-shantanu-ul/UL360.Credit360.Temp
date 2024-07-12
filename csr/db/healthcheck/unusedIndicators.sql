WITH used_inds AS (
    SELECT DISTINCT ind_sid
      FROM val
     UNION
    SELECT DISTINCT d.delegation_sid
      FROM delegation_ind di
        JOIN delegation d ON d.delegation_sid = di.delegation_sid
        JOIN customer c ON d.app_sid = c.app_sid
        JOIN reporting_period rp ON c.current_reporting_period_sid = rp.reporting_period_sid
     WHERE d.end_dtm > rp.start_dtm -- don't fuss with end date since it might be new deleg we're preparing that's not yet used
     UNION
    SELECT DISTINCT cd.ind_sid
      FROM calc_dependency cd, ind ci
     WHERE cd.ind_sid = ci.ind_sid
       AND ci.active = 1
     UNION
    SELECT cd.calc_ind_sid
      FROM calc_dependency cd
 )
SELECT indicator_pkg.INTERNAL_GetIndPathString(ind_sid)
  FROM (
    SELECT ind_sid
      FROM ind
     WHERE active = 1
     MINUS
    SELECT ind_sid
      FROM ind
     START WITH ind_sid IN (
        SELECT ind_sid
          FROM used_inds
    )
    CONNECT BY PRIOR parent_sid = ind_sid
);