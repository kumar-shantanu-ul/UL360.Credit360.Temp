
SET DEFINE OFF

DECLARE
	v_copied_deleg_sid 			security_pkg.T_SID_ID;
	out_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	user_pkg.logonadmin('imi.credit360.com');
	FOR rd IN (
		SELECT delegation_sid master_delegation_sid
		  FROM delegation 
		 WHERE delegation_sid IN (10811336, 10811334, 11161240, 11245885)
	)
	LOOP
		FOR r IN (
			-- retrieves region-based delegation chains for a 
			-- set of regions
			WITH td AS (
				SELECT d.delegation_sid, region_sid
				  FROM delegation d
					JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
				 WHERE d.name = 'Health & Safety (Incl. people numbers and hours worked)' 
				   AND d.start_dtm = '1 jan 2010' 
				   AND d.end_dtm = '1 jan 2011'
				   AND d.app_sid = d.parent_sid
			)
			SELECT root_delegation_sid, description, region_sid, lvl max_lvl, LTRIM(SYS_CONNECT_BY_PATH(csr_user_sids, '/'),'/') path
			  FROM (
				SELECT root_delegation_sid, description, region_sid, lvl, stragg(csr_user_sid) csr_user_sids
				  FROM (
					SELECT r.region_sid, r.description, cu.csr_user_sid, lvl, root_delegation_sid
					  FROM (
						SELECT d.lvl, du.user_sid, d.root_delegation_sid
						  FROM (
							SELECT delegation_sid, level lvl, CONNECT_BY_ROOT delegation_sid root_delegation_sid
							  FROM delegation
							 START WITH delegation_sid IN (
								SELECT delegation_Sid FROM td
							 )
							CONNECT BY PRIOR delegation_sid = parent_sid
						  )d JOIN delegation_user du ON d.delegation_sid = du.delegation_sid
					  )uh 
						JOIN delegation_region dr ON uh.root_delegation_sid = dr.delegation_sid
						JOIN region r ON dr.region_sid = r.region_sid
						JOIN csr_user cu ON uh.user_sid = cu.csr_user_sid
					)
				GROUP BY root_delegation_sid, description, region_sid, lvl
			   )
			 WHERE CONNECT_BY_ISLEAF = 1
			 START WITH lvl = 1
			CONNECT BY PRIOR root_delegation_sid = root_delegation_sid
			 AND PRIOR region_sid = region_sid
			 AND PRIOR lvl = lvl-1
		)
		LOOP
			delegation_pkg.CopyDelegation(security_pkg.getACT, rd.master_delegation_sid, null, v_copied_deleg_sid);
			delegation_pkg.ApplyChainToRegion(security_pkg.getACT, v_copied_deleg_sid, r.region_sid, r.path, 1, out_cur);
		END LOOP;
	END LOOP;
END;
/
		  