--Please update version.sql too -- this keeps clean builds in sync
define version=2677
@update_header

DECLARE v_host 					VARCHAR2(255);
	v_company_ca_group_type_id 	NUMBER DEFAULT 4;--global for chain admins
	v_ca_permission_set			security.security_pkg.T_PERMISSION;
BEGIN
	security.user_pkg.logonadmin;
	
	--fill missing chain_admin permissions
	FOR i IN (
		SELECT primary_company_type_id, capability_id, host
		  FROM chain.company_type_capability ctc
		  JOIN csr.customer c ON c.app_sid = ctc.app_sid
		 WHERE ctc.primary_company_type_role_sid IS NOT NULL
		 ORDER BY ctc.app_sid
	)
	LOOP
		IF NVL(v_host, ' ') <> i.host THEN
			security.user_pkg.logonadmin(i.host);
			v_host := i.host;
		END IF;
		dbms_output.put_line('running for host:' || i.host || ' and capability_id' || i.capability_id);
		--RefreshChainAdminPermissionSet copied from type_capability_body
		INSERT INTO chain.company_type_capability
		(primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id)
		SELECT primary_company_type_id, v_company_ca_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM (
			SELECT UNIQUE primary_company_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
			  FROM chain.company_type_capability
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND primary_company_type_id = i.primary_company_type_id
			   AND capability_id = NVL(i.capability_id, capability_id)
			)
		MINUS
		SELECT primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM chain.company_type_capability
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND primary_company_type_id = i.primary_company_type_id
		   AND primary_company_group_type_id = v_company_ca_group_type_id
		   AND capability_id = NVL(i.capability_id, capability_id);
		
		FOR r IN (
			SELECT primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
			  FROM chain.company_type_capability
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND primary_company_type_id = i.primary_company_type_id
			   AND primary_company_group_type_id = v_company_ca_group_type_id
			   AND capability_id = NVL(i.capability_id, capability_id) 
		) LOOP
			v_ca_permission_set := 0;
			
			FOR p IN (
				SELECT ctc.permission_set
				  FROM chain.company_type_capability ctc
				  LEFT JOIN chain.company_group_type cgt ON ctc.primary_company_group_type_id = cgt.company_group_type_id
				 WHERE ctc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND ctc.primary_company_type_id = r.primary_company_type_id
				   AND ctc.capability_id = r.capability_id
				   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
				   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
				   AND (cgt.is_global = 0 OR cgt.company_group_type_id IS NULL)
			) LOOP
				v_ca_permission_set := security.bitwise_pkg.bitor(v_ca_permission_set, p.permission_set);
			END LOOP;
			
			-- update the chain admin permission set
			UPDATE chain.company_type_capability
			   SET permission_set = v_ca_permission_set
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND primary_company_type_id = r.primary_company_type_id
			   AND primary_company_group_type_id = v_company_ca_group_type_id
			   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
			   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
			   AND capability_id = r.capability_id;
		END LOOP;
	END LOOP;
END;
/

@../chain/type_capability_body

@update_tail