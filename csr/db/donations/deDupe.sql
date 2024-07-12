
DECLARE
	v_master_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin('&&1');
	FOR r IN (
		  SELECT y.recipient_sid||'|'||y.org_name||'|'||y.postcode||'|'||rank() OVER (PARTITION BY y.postcode ORDER BY recipient_sid, y.postcode, cnsex) rnk
			FROM (
			SELECT dr.recipient_sid, dr.postcode, cnsex, org_name
			  FROM donations.recipient dr, (
				 SELECT SOUNDEX(org_name) cnsex, postcode 
				   FROM donations.recipient 
				  WHERE LENGTH(postcode)>5 
					AND postcode NOT LIKE '**%' 
				  GROUP BY SOUNDEX(org_name), postcode 
				 HAVING COUNT(*) > 1
			  )x
			WHERE SOUNDEX(dr.org_name) = x.cnsex 
			  AND dr.postcode = x.postcode 
			ORDER BY dr.postcode
			)y
	)
	LOOP
    	IF r.rnk = 1 THEN
        	v_master_sid := r.recipient_sid;
        ELSE
        	UPDATE donations.donation SET recipient_sid = v_master_sid WHERE recipient_sid = r.recipient_sid;
            DELETE FROM donations.recipient WHERE recipient_sid = r.recipient_sid;
        END IF;
	END LOOP;
END;
/
