-- Please update version.sql too -- this keeps clean builds in sync
define version=1466
@update_header

DECLARE
	v_region_sid	csr.region.region_sid%TYPE;
	v_ind_sid		csr.ind.ind_sid%TYPE;
	v_num			NUMBER(10);

	CURSOR c(in_delegation_sid csr.delegation.delegation_sid%TYPE) IS
	  SELECT region_sid, di.ind_sid
	    FROM csr.delegation_region dr 
        JOIN csr.delegation_ind di on (di.app_sid = dr.app_sid and di.delegation_sid = dr.delegation_sid)
        JOIN csr.ind i on (i.app_sid = di.app_sid and i.ind_sid = di.ind_sid)
        LEFT JOIN csr.delegation_grid dg on (dg.app_sid = i.app_sid and dg.ind_sid = i.ind_sid)
        LEFT JOIN csr.delegation_plugin dp on (dp.app_sid = i.app_sid and dp.ind_sid = i.ind_sid)
	   WHERE dr.delegation_sid = in_delegation_sid
         AND (
          i.measure_sid IS NOT NULL
          OR
          dg.ind_sid IS NOT NULL
          OR
          dp.ind_sid IS NOT NULL
		) -- we dont' care about cross-headers (i.e. container nodes with no UoM), but we do care about delegations with just grids on them
     MINUS
	  SELECT aggregate_to_region_sid, ind_sid FROM csr.delegation_region dr, csr.delegation_ind di, csr.delegation d
	   WHERE dr.app_sid = di.app_sid
	     AND dr.app_sid = d.app_sid
	     AND di.app_sid = d.app_sid
	     AND dr.delegation_sid = d.delegation_sid
	     AND di.delegation_sid = d.delegation_sid
		 AND d.parent_sid = in_delegation_sid;		
	v_val NUMBER;
	v_not_found BOOLEAN;
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (SELECT app_sid FROM csr.customer) LOOP
		security.security_pkg.setapp(r.app_sid);

		FOR s IN (SELECT delegation_sid FROM csr.delegation) LOOP
			OPEN c(s.delegation_sid);
			FETCH c INTO v_region_sid, v_ind_sid;
			v_not_found := c%NOTFOUND;
			CLOSE c;
			IF v_not_found THEN
				-- do some more checks
				SELECT COUNT(*) INTO v_num
					FROM csr.delegation d
				 WHERE d.parent_sid = s.delegation_sid;
				IF v_num > 1 THEN
					v_val := 2; -- csr_data_pkg.FULLY_DELEGATED_TO_MANY; -- more than 1 sub delegation
				ELSIF v_num = 1 THEN
					v_val := 1; --csr_data_pkg.FULLY_DELEGATED_TO_ONE; -- everything delegated to one person
				ELSE
					v_val := 0; --csr_data_pkg.NOT_FULLY_DELEGATED; -- No sub delegations so top level delegation
				END IF;
			ELSE
				v_val := 0; -- csr_data_pkg.NOT_FULLY_DELEGATED;
			END IF;
		
			UPDATE csr.delegation
			   SET fully_delegated = v_val
			 WHERE delegation_sid = s.delegation_sid
			   AND fully_delegated != v_val;
		END LOOP;
		COMMIT;
	END LOOP;
END;
/

@../delegation_body

@update_tail
