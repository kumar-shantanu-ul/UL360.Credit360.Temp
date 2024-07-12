declare
begin
	for r in (
		-- all the calculations we want to convert to stored
		   SELECT ind_sid 
		       FROM IND 
 			  where ind_type = 1
		      START WITH ind_sid = 713562
		    CONNECT BY PRIOR ind_sid = parent_sid)
      LOOP
        -- set to be stored, quarterly
       	UPDATE IND SET default_interval = 'y', ind_type = 2
         WHERE IND_SID = r.ind_sid;
       	calc_pkg.AddJobsForCalc(r.ind_sid);
       	calc_pkg.AddJobsForInd(r.ind_sid);
     end loop;
end;