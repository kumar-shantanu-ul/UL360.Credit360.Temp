-- Please update version.sql too -- this keeps clean builds in sync
define version=841
@update_header

CREATE FUNCTION csr.IsFullyDelegated(
	in_delegation_sid	IN NUMBER
) RETURN NUMBER
AS
	v_region_sid	NUMBER;
	v_ind_sid		NUMBER;
	v_num			NUMBER(10);
	CURSOR c IS
		 SELECT region_sid, di.ind_sid 
		   FROM delegation_region dr, delegation_ind di, ind i, delegation_grid dg
		  WHERE dr.app_sid = di.app_sid
		    AND dr.app_sid = i.app_sid
		    AND di.app_sid = i.app_sid
		    AND dr.delegation_sid = in_delegation_sid
			AND di.delegation_sid = in_delegation_sid
			AND di.ind_sid = i.ind_sid
			AND i.ind_sid = dg.ind_sid(+)
		    AND (
				i.measure_sid IS NOT NULL 
				OR 
				dg.ind_sid IS NOT NULL
				) -- we dont' care about cross-headers (i.e. container nodes with no UoM), but we do care about delegations with just grids on them
		MINUS	 
		 SELECT aggregate_to_region_sid, ind_sid FROM delegation_region dr, delegation_ind di, delegation d
		  WHERE dr.app_sid = di.app_sid
		    AND dr.app_sid = d.app_sid
		    AND di.app_sid = d.app_sid
		    AND dr.delegation_sid = d.delegation_sid
		    AND di.delegation_sid = d.delegation_sid
			AND d.parent_sid = in_delegation_sid;
BEGIN			 
	OPEN c;
	FETCH c INTO v_region_sid, v_ind_sid;
	IF c%NOTFOUND THEN
		-- do some more checks
		SELECT COUNT(*) INTO v_num
			FROM delegation d
		 WHERE d.parent_sid = in_delegation_sid;
		IF v_num > 1 THEN
			RETURN 2; -- more than 1 sub delegation
		ELSE
			RETURN 1; -- everything delegated to one person
		END IF;
	ELSE
		RETURN 0;
	END IF;
END;
/

DECLARE
	v_fully_delegated	NUMBER;
BEGIN
	FOR r IN (
		SELECT delegation_sid
		  FROM csr.delegation
		 WHERE delegation_sid IN (SELECT parent_sid FROM csr.delegation)
		 START WITH delegation_sid IN (SELECT maps_to_root_deleg_sid FROM csr.V$DELEG_PLAN_DELEG_REGION)
		CONNECT BY PRIOR delegation_sid = parent_sid
	) LOOP
		v_fully_delegated := csr.IsFullyDelegated(r.delegation_sid);
		
		UPDATE csr.delegation
		   SET fully_delegated = v_fully_delegated
		 WHERE delegation_sid = r.delegation_sid;
		
	END LOOP;
END;
/

DROP FUNCTION csr.IsFullyDelegated;

@..\deleg_plan_body

@update_tail
