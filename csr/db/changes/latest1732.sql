-- Please update version.sql too -- this keeps clean builds in sync
define version=1732
@update_header

DECLARE 
	v_company_ca_group_type_id 	chain.company_group_type.company_group_type_id%TYPE;
	v_ca_permission_set			security.security_pkg.T_PERMISSION DEFAULT 0;
BEGIN
	SELECT company_group_type_id
	  INTO v_company_ca_group_type_id
	  FROM chain.company_group_type
	 WHERE name = 'Chain Administrators';

	INSERT INTO chain.company_type_relationship
	(app_sid, primary_company_type_id, secondary_company_type_id)
	SELECT p.app_sid, p.company_type_id, s.company_type_id
	  FROM chain.company_type p, chain.company_type s
	 WHERE p.app_sid = s.app_sid
	   AND p.lookup_key = 'TOP'
	   AND s.lookup_key = 'SUPPLIER'
	   AND p.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	 MINUS
	 SELECT app_sid, primary_company_type_id, secondary_company_type_id
	   FROM chain.company_type_relationship;
		
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
	SELECT ct.app_sid, ct.company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
	  FROM chain.group_capability gc, chain.capability c, chain.company_type ct
	 WHERE ct.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND gc.capability_id = c.capability_id
	   AND c.is_supplier = 0
	   AND (ct.company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
			SELECT primary_company_type_id, primary_company_group_type_id, capability_id
			  FROM chain.company_type_capability
	   );


	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
	SELECT ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
	  FROM chain.group_capability gc, chain.capability c, chain.company_type_relationship ctr, chain.company_type ct
	 WHERE ct.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND ct.app_sid = ctr.app_sid
	   AND ct.company_type_id = ctr.primary_company_type_id
	   AND gc.capability_id = c.capability_id
	   AND c.is_supplier = 1
	   AND c.capability_type_id <> 3
	   AND (ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
			SELECT primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id
			  FROM chain.company_type_capability
	   );

	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
	SELECT ct.app_sid, ct.company_type_id, ctrs.secondary_company_type_id, ctrt.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
	  FROM chain.group_capability gc, chain.capability c, chain.company_type_relationship ctrs, chain.company_type_relationship ctrt, chain.company_type ct
	 WHERE ct.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND ct.app_sid = ctrs.app_sid
	   AND ct.app_sid = ctrt.app_sid
	   AND ct.company_type_id = ctrs.primary_company_type_id
	   AND ctrs.secondary_company_type_id = ctrt.primary_company_type_id
	   AND gc.capability_id = c.capability_id
	   AND c.is_supplier = 1
	   AND c.capability_type_id = 3
	   AND (ct.company_type_id, ctrs.secondary_company_type_id, ctrt.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
			SELECT primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id
			  FROM chain.company_type_capability
	   );


	-- extended ct capabilities
	DELETE FROM chain.company_type_capability 
	 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND capability_id IN (SELECT capability_id FROM chain.capability WHERE capability_name IN ('Send questionnaire invitation', 'Is top company'));
	
	-- extended ct capabilities
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id, permission_set)
	SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id, s.company_type_id, NULL, 2
	  FROM chain.company_type p, chain.company_type s, chain.company_group_type cgt, chain.capability c
	 WHERE p.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND p.app_sid = s.app_sid
	   AND p.lookup_key = 'TOP'
	   AND s.lookup_key = 'SUPPLIER'
	   AND c.capability_name = 'Send questionnaire invitation'
	   AND cgt.name = 'Users';
	
	-- extended ct capabilities
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id, permission_set)
	SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id, NULL, NULL, 2
	  FROM chain.company_type p, chain.company_group_type cgt, chain.capability c
	 WHERE p.app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND p.lookup_key = 'TOP'
	   AND c.capability_name = 'Is top company'
	   AND cgt.name = 'Users';

	
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id)
	SELECT app_sid, primary_company_type_id, v_company_ca_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
	  FROM (
		SELECT UNIQUE app_sid, primary_company_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM chain.company_type_capability
		 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
		)
	MINUS
	SELECT app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
	  FROM chain.company_type_capability
	 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
	   AND primary_company_group_type_id = v_company_ca_group_type_id;
		
	FOR r IN (
		SELECT app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM chain.company_type_capability
		 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT')
		   AND primary_company_group_type_id = v_company_ca_group_type_id
	) LOOP
		v_ca_permission_set := 0;

		FOR p IN (
			SELECT ctc.permission_set
			  FROM chain.company_type_capability ctc, chain.company_group_type cgt
			 WHERE ctc.app_sid = r.app_sid
			   AND ctc.primary_company_type_id = r.primary_company_type_id
			   AND ctc.capability_id = r.capability_id
			   AND ctc.primary_company_group_type_id = cgt.company_group_type_id
			   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
			   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
			   AND cgt.is_global = 0
		) LOOP
			v_ca_permission_set := security.bitwise_pkg.bitor(v_ca_permission_set, p.permission_set);	
		END LOOP;

		-- update the chain admin permission set
		UPDATE chain.company_type_capability
		   SET permission_set = v_ca_permission_set
		 WHERE app_sid = r.app_sid
		   AND primary_company_type_id = r.primary_company_type_id
		   AND primary_company_group_type_id = r.primary_company_group_type_id
		   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
		   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
		   AND capability_id = r.capability_id;
	END LOOP;

END;
/

@update_tail
