-- adds specified region (and any necessary parent regions) to any current pending_region trees
-- do we need similar code to delete? and move?
CREATE OR REPLACE PROCEDURE AddRegionToPending(
	in_region_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
        SELECT *
		  FROM (
			  -- we need to do the row_number in a wrapper round the main select, otherwise the PRIOR region_sid
			  -- returns null
			  SELECT row_number() over (partition by x.pending_dataset_id order by lvl desc) rn, x.*
				FROM (
					SELECT region_sid, level lvl, 
						r.description, r.parent_sid, pending_region_id, pending_dataset_id, PRIOR region_sid prior_region_sid
					  FROM region r, pending_region pr
					 WHERE r.region_sid = pr.maps_to_region_sid(+)
					 START with region_sid = in_region_sid
				   CONNECT BY PRIOR parent_sid = region_sid
					   and prior pr.maps_to_region_sid is null
			    )x, pending_dataset pds, customer c
			   WHERE x.pending_dataset_id = pds.pending_dataset_id 
                 AND pds.reporting_period_sid = c.current_reporting_period_sid -- only fiddle with structures in current reporting period
			     AND prior_region_sid IS NOT NULL -- means it exists already
		  )
		WHERE rn = 1
	)
	LOOP
		-- copy this chunk
		FOR rr IN (
			SELECT region_sid, parent_sid, description
			  FROM region
			 START WITH region_sid =  r.prior_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		     ORDER SIBLINGS BY description
		)
		LOOP
			INSERT INTO pending_region (pending_region_id, parent_region_id, pending_dataset_id, maps_to_region_sid, description)
				SELECT pending_region_id_seq.nextval, pending_region_id, pending_dataset_id, rr.region_sid, rr.description
				  FROM pending_region
				 WHERE pending_dataset_id = r.pending_dataset_id
				   AND maps_to_region_sid = rr.parent_sid;
		END LOOP;
	END LOOP;
END;
/
