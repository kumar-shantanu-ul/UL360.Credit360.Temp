DECLARE
	v_secondary_root_sid	security_pkg.T_SID_ID;
BEGIN
	FOR app IN (
		SELECT host
		  FROM chain.v$chain_host h
		 WHERE EXISTS (SELECT NULL FROM chain.sector s WHERE s.app_sid = h.app_sid)
		   AND EXISTS (SELECT NULL FROM csr.supplier s WHERE s.app_sid = s.app_sid)
	) LOOP
		user_pkg.LogonAdmin(app.host);
		
		BEGIN
			v_secondary_root_sid := csr.region_tree_pkg.GetSecondaryRegionTreeRootSid('suppliers by sector');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- no secondary tree
		END;
		
		IF v_secondary_root_sid IS NOT NULL THEN
			
			-- Delete old structure
			FOR r IN (
				SELECT region_sid
				  FROM csr.region
				 WHERE parent_sid = v_secondary_root_sid
			) LOOP
				securableobject_pkg.DeleteSO(security_pkg.GetAct, r.region_sid);
			END LOOP;
			
			FOR r IN (
				SELECT company_sid
				  FROM chain.v$company
			) LOOP
				csr.supplier_pkg.UpdateCompany(r.company_sid);
			END LOOP;
		END IF;
		
	END LOOP;
END;
/
