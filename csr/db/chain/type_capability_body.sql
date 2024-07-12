CREATE OR REPLACE PACKAGE BODY CHAIN.type_capability_pkg
IS

BOOLEAN_PERM_SET				CONSTANT security_Pkg.T_PERMISSION := security_pkg.PERMISSION_WRITE;

/************************************************************** 
			PRIVATE METHODS 
**************************************************************/
PROCEDURE LogTypeCapabilityChange (
	in_description					IN	VARCHAR2,
	in_param_1          			IN  VARCHAR2 DEFAULT NULL,
	in_param_2          			IN  VARCHAR2 DEFAULT NULL,
	in_param_3          			IN  VARCHAR2 DEFAULT NULL,
	in_sub_object_id				IN	NUMBER
)
AS
BEGIN
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id				=> security_pkg.GetAct,
		in_audit_type_id		=> csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid				=> security_pkg.GetApp,
		in_object_sid			=> security_pkg.GetApp,
		in_description			=> in_description,
		in_param_1          	=> in_param_1,
		in_param_2          	=> in_param_2,
		in_param_3          	=> in_param_3,
		in_sub_object_id		=> in_sub_object_id
	);
END;

PROCEDURE LogTypeCapabilityChange (
	in_permission_set				IN	company_type_capability.permission_set%TYPE,
	in_capability_id      			IN  company_type_capability.capability_id%TYPE,
	in_primary_company_type_id		IN  company_type_capability.primary_company_type_id%TYPE,
	in_secondary_company_type_id	IN  company_type_capability.secondary_company_type_id%TYPE,
	in_tertiary_company_type_id		IN  company_type_capability.tertiary_company_type_id%TYPE,
	in_company_group_type_id		IN  company_type_capability.primary_company_group_type_id%TYPE,
	in_company_role_sid				IN  company_type_capability.primary_company_type_role_sid%TYPE
)
AS
	v_desc							VARCHAR2(1024);
	v_permission_set_desc			VARCHAR2(1024);
	v_perm_group_desc				VARCHAR2(1024);
	v_company_type_desc				VARCHAR2(1024);
	v_perm_type						capability.perm_type%TYPE;
BEGIN
	SELECT perm_type
	  INTO v_perm_type
	  FROM capability
	 WHERE capability_id = in_capability_id;

	IF v_perm_type = 1 THEN
		IF in_permission_set = 0 THEN
			v_permission_set_desc := 'False';
		ELSE
			v_permission_set_desc := 'True';
		END IF;
	ELSIF v_perm_type = 0 THEN
		IF in_permission_set = 0 THEN
			v_permission_set_desc := 'None';
		ELSE
			-- Just do common ones
			IF security.bitwise_pkg.BitAnd(in_permission_set, security.security_pkg.PERMISSION_READ) = security.security_pkg.PERMISSION_READ THEN
				v_permission_set_desc := 'Read, ';
			END IF;
			IF security.bitwise_pkg.BitAnd(in_permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE THEN
				v_permission_set_desc := v_permission_set_desc||'Write, ';
			END IF;
			IF security.bitwise_pkg.BitAnd(in_permission_set, security.security_pkg.PERMISSION_DELETE) = security.security_pkg.PERMISSION_DELETE THEN
				v_permission_set_desc := v_permission_set_desc||'Delete, ';
			END IF;
			
			v_permission_set_desc := v_permission_set_desc||'(Permission set '||in_permission_set||')';
		END IF;
	END IF;
	
	v_desc := 'Chain company type capability changed. Capability "{0}" for "{1}" access changed to "'||v_permission_set_desc||'" for';
	
	IF in_company_group_type_id IS NOT NULL THEN
		v_desc := v_desc||' company group type "{2}"';
		
		SELECT name
		  INTO v_perm_group_desc
		  FROM company_group_type
		 WHERE company_group_type_id = in_company_group_type_id;
	ELSE
		v_desc := v_desc||' role "{2}"';
		
		SELECT name
		  INTO v_perm_group_desc
		  FROM csr.role
		 WHERE role_sid = in_company_role_sid;
	END IF;
	
	v_company_type_desc := company_type_pkg.GetCompanyTypeDescription(in_primary_company_type_id);
	IF in_secondary_company_type_id IS NOT NULL THEN
		v_company_type_desc := v_company_type_desc||' => '|| company_type_pkg.GetCompanyTypeDescription(in_secondary_company_type_id);
	END IF;
	IF in_tertiary_company_type_id IS NOT NULL THEN
		v_company_type_desc := v_company_type_desc||' => '|| company_type_pkg.GetCompanyTypeDescription(in_tertiary_company_type_id);
	END IF;

	LogTypeCapabilityChange (
		in_description			=> v_desc,
		in_param_1          	=> capability_pkg.GetCapabilityPath(in_capability_id),
		in_param_2          	=> v_company_type_desc,
		in_param_3          	=> v_perm_group_desc,
		in_sub_object_id		=> in_primary_company_type_id
	);
END;

FUNCTION GetCapabilityId (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_is_supplier			IN  BOOLEAN
) RETURN NUMBER
AS
	v_is_supplier			capability.is_supplier%TYPE DEFAULT CASE WHEN in_is_supplier THEN 1 ELSE 0 END;
	v_capability			chain_pkg.T_CAPABILITY DEFAULT in_capability;
	v_capability_id			capability.capability_id%TYPE;
BEGIN
	IF v_capability = chain_pkg.COMPANYorSUPPLIER THEN
		IF in_is_supplier THEN
			v_capability := chain_pkg.SUPPLIERS;
		ELSE 
			v_capability := chain_pkg.COMPANY;
		END IF;
	END IF;

	BEGIN
		SELECT capability_id
		  INTO v_capability_id
		  FROM capability
		 WHERE capability_name = v_capability
		   AND is_supplier = v_is_supplier
		   AND (
				(is_supplier = 0 AND capability_type_id IN (chain_pkg.CT_COMPANY, chain_pkg.CT_COMMON))
				OR
				(is_supplier = 1 AND capability_type_id IN (chain_pkg.CT_SUPPLIERS, chain_pkg.CT_COMMON, chain_pkg.CT_ON_BEHALF_OF))
		   );
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability not configured or not compatable with company_types: Capability name:'||in_capability);
	END;
	
	RETURN v_capability_id;
END;

FUNCTION IsCapabilityCTCompany(
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = chain_pkg.CT_COMPANY;
	
	RETURN v_count > 0;
END;

FUNCTION IsCapabilityCTSuppliers(
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = chain_pkg.CT_SUPPLIERS;
	
	RETURN v_count > 0;
END;

FUNCTION IsSupplierCapability (
	in_capability_id			IN  capability.capability_id%TYPE
) RETURN BOOLEAN
AS
	v_is_supplier				capability.is_supplier%TYPE;
BEGIN
	SELECT is_supplier
	  INTO v_is_supplier
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	RETURN v_is_supplier = 1;
END;

FUNCTION IsOnBehalfOfCapability (
	in_capability_id			IN  capability.capability_id%TYPE
) RETURN BOOLEAN
AS
	v_capability_type_id		capability_type.capability_type_id%TYPE;
BEGIN
	SELECT MIN(capability_type_id)
	  INTO v_capability_type_id
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	RETURN v_capability_type_id = chain_pkg.CT_ON_BEHALF_OF;
END;

FUNCTION IsOnBehalfOfCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_capability_id				capability.capability_id%TYPE;
BEGIN
	SELECT MIN(capability_id) 
	  INTO v_capability_id
	  FROM capability
	 WHERE capability_name = in_capability;
	
	RETURN IsOnBehalfOfCapability(v_capability_id);
END;

FUNCTION IsGlobalGroup (
	in_company_group_type_id 	IN company_group_type.company_group_type_id%TYPE
) RETURN BOOLEAN
AS
	v_is_global					company_group_type.is_global%TYPE;
BEGIN
	SELECT is_global
	  INTO v_is_global
	  FROM company_group_type
	 WHERE company_group_type_id = in_company_group_type_id;
	
	RETURN v_is_global = 1;
END;

PROCEDURE FillUserGroups
AS
	v_count			NUMBER(10);
	v_user_sid		security_pkg.T_SID_ID DEFAULT security_pkg.GetSid;
	v_company_sid	security_pkg.T_SID_ID DEFAULT company_pkg.GetCompany;
	v_act_id		security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	SELECT COUNT(*) 
	  INTO v_count
	  FROM TT_USER_GROUPS
	 WHERE user_sid = v_user_sid
	   AND company_sid = v_company_sid;
	 
	-- save work by filling once per transaction
	IF v_count = 0 THEN
		INSERT INTO TT_USER_GROUPS
		(user_sid, company_sid, group_sid)
		SELECT v_user_sid, cg.company_sid, cg.group_sid
		  FROM company_group cg, security.act
		 WHERE cg.group_sid = act.sid_id
		   AND cg.company_sid = v_company_sid
		   AND act.act_id = v_act_id;
	END IF;
END;

PROCEDURE CheckPermType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
BEGIN
	CheckPermType(GetCapabilityId(in_capability_type, in_capability), in_expected_pt); 
END;

PROCEDURE GetGroupCapabilityId (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_group				IN  chain_pkg.T_GROUP,
	out_gc_id				OUT group_capability.group_capability_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO group_capability
		(group_capability_id, company_group_type_id, capability_id)
		VALUES
		(group_capability_id_seq.NEXTVAL, company_pkg.GetCompanyGroupTypeId(in_group), in_capability_id)
		RETURNING group_capability_id INTO out_gc_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT group_capability_id
			  INTO out_gc_id
			  FROM group_capability
			 WHERE capability_id = in_capability_id
			   AND company_group_type_id = company_pkg.GetCompanyGroupTypeId(in_group);
	END;
END;

PROCEDURE GetGroupCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	out_gc_id				OUT group_capability.group_capability_id%TYPE
)
AS
BEGIN
	GetGroupCapabilityId(GetCapabilityId(in_capability_type, in_capability), in_group, out_gc_id);
END;

FUNCTION CheckPermissionByType (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_secondary_company_type		IN  company.company_type_id%TYPE,
	in_tertiary_company_type		IN  company.company_type_id%TYPE,
	in_capability_id				IN  capability.capability_id%TYPE,
	in_permission_set				IN  security_Pkg.T_PERMISSION,
	in_expected_pt					IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_region_sid					security_pkg.T_SID_ID DEFAULT NULL; /* The region we perform the RRM check on */
	v_is_rrm						NUMBER;
	v_supplier_on_purchaser			NUMBER;
	v_primary_company_type_id		company.company_type_id%TYPE;
	v_secondary_company_type_id		company.company_type_id%TYPE;
BEGIN
	IF helper_pkg.IsElevatedAccount THEN
		RETURN TRUE;
	END IF;

	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session - '||security_pkg.GetSid);	
	END IF;

	IF in_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		-- we may want to allow this in the future by I'm not sure the best way to verify the check, so I'm forbidding for now
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company_sid does not match the context company sid');	
	END IF;
	
	-- verify data (indicates malformed capability check)
	IF IsSupplierCapability(in_capability_id) AND in_secondary_company_type IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot check supplier capabilities when the secondary company type is null');	
	ELSIF NOT IsSupplierCapability(in_capability_id) AND in_secondary_company_type IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot check company capabilities and have a secondary company type set');	
	ELSIF IsOnBehalfOfCapability(in_capability_id) AND (in_secondary_company_type IS NULL OR in_tertiary_company_type IS NULL) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot check on-behalf-of capabilities when the secondary or tertiary company types are null');	
	END IF;
	
	-- check that we're checking the correct permission type for the capability
	CheckPermType(in_capability_id, in_expected_pt);

	FillUserGroups;

	SELECT supplier_on_purchaser
	  INTO v_supplier_on_purchaser
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	IF v_supplier_on_purchaser = 0 THEN
		v_primary_company_type_id := company_type_pkg.GetCompanyTypeId(in_company_sid);
		v_secondary_company_type_id := in_secondary_company_type;
	ELSE
		v_primary_company_type_id := in_secondary_company_type;
		v_secondary_company_type_id := company_type_pkg.GetCompanyTypeId(in_company_sid);
	END IF;

	FOR r IN (
		SELECT DISTINCT ctc.permission_set
		  FROM TT_USER_GROUPS ug
		  JOIN company_group cg ON ug.group_sid = cg.group_sid AND ug.company_sid = cg.company_sid
		  JOIN company_type_capability ctc ON cg.app_sid = ctc.app_sid AND cg.company_group_type_id = ctc.primary_company_group_type_id
		  JOIN capability cap ON ctc.capability_id = cap.capability_id
		 WHERE ug.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND cg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctc.capability_id = in_capability_id
		   AND ctc.primary_company_group_type_id IS NOT NULL
		   AND ctc.primary_company_type_id = v_primary_company_type_id
		   AND (
		   		(cap.is_supplier = 1 AND cap.capability_type_id <> chain_pkg.CT_ON_BEHALF_OF AND ctc.secondary_company_type_id IS NOT NULL AND ctc.secondary_company_type_id = v_secondary_company_type_id)
		   		OR
		   		(cap.is_supplier = 0 AND ctc.secondary_company_type_id IS NULL AND v_secondary_company_type_id IS NULL)
		   		OR
		   		(cap.is_supplier = 1 AND cap.capability_type_id = chain_pkg.CT_ON_BEHALF_OF AND ctc.secondary_company_type_id = v_secondary_company_type_id AND ctc.tertiary_company_type_id = in_tertiary_company_type)
		   	  )
	) LOOP
		-- if sufficient permissions, return allowed
		IF security.bitwise_pkg.bitand(in_permission_set, r.permission_set) = in_permission_set THEN
			RETURN TRUE;
		END IF;

	END LOOP;	
	
	
	/* RRM  */
	--Check against our region always
	BEGIN
		v_region_sid := csr.supplier_pkg.GetRegionSid(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; --for chain implementations without a region structure
	END;
	
	IF v_region_sid IS NOT NULL THEN
		FOR r IN (
			SELECT UNIQUE ctc.permission_set, ctc.primary_company_type_role_sid
			  FROM company_type_capability ctc
			  JOIN capability cap ON ctc.capability_id = cap.capability_id
			  JOIN company_type_role ctr ON ctc.app_sid = ctr.app_sid AND ctc.primary_company_type_role_sid = ctr.role_sid
			  JOIN company c ON c.company_type_id = ctr.company_type_id
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND ctc.capability_id = in_capability_id
			   AND ctc.primary_company_type_role_sid IS NOT NULL
			   AND ctc.primary_company_type_id = v_primary_company_type_id
			   AND (
					(cap.is_supplier = 1 AND cap.capability_type_id <> chain_pkg.CT_ON_BEHALF_OF AND ctc.secondary_company_type_id IS NOT NULL AND ctc.secondary_company_type_id = v_secondary_company_type_id)
					OR
					(cap.is_supplier = 0 AND ctc.secondary_company_type_id IS NULL AND v_secondary_company_type_id IS NULL)
					OR
					(cap.is_supplier = 1 AND cap.capability_type_id = chain_pkg.CT_ON_BEHALF_OF AND ctc.secondary_company_type_id = v_secondary_company_type_id AND ctc.tertiary_company_type_id = in_tertiary_company_type)
				  )
		) LOOP
			-- if sufficient permissions, check if the user has this role for the region
			IF security.bitwise_pkg.bitand(in_permission_set, r.permission_set) = in_permission_set THEN
				
				  --todo: cache the region roles per user into a temp table?
				  SELECT DECODE(COUNT(*), 0, 0, 1)
					INTO v_is_rrm 
					FROM chain.chain_user cu
					JOIN csr.region_role_member rrm ON cu.user_sid = rrm.user_sid
				   WHERE rrm.region_sid = v_region_sid
					 AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 AND rrm.role_sid = r.primary_company_type_role_sid;
					 
					IF v_is_rrm = 1 THEN
						RETURN TRUE;
					END IF;
			END IF;

		END LOOP;
	END IF;
	
	RETURN FALSE;
END;

PROCEDURE TryGetFlowCapability(
	in_capability_id		IN capability.capability_id%TYPE,
	in_expected_pt			IN chain_pkg.T_CAPABILITY_PERM_TYPE,
	out_flow_capability_id	OUT csr.customer_flow_capability.flow_capability_id%TYPE,
	out_perm_type			OUT csr.customer_flow_capability.perm_type%TYPE
)
AS
BEGIN
	BEGIN
		SELECT csr_cfc.flow_capability_id, csr_cfc.perm_type
		  INTO out_flow_capability_id, out_perm_type
		  FROM capability_flow_capability ch_cfc
		  JOIN csr.customer_flow_capability csr_cfc ON ch_cfc.flow_capability_id = csr_cfc.flow_capability_id
		 WHERE ch_cfc.capability_id = in_capability_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
		
	IF out_perm_type != in_expected_pt THEN
		RAISE_APPLICATION_ERROR(-20001, 'The permission type of the flow capability with id ' || out_flow_capability_id || ' does not match the permission type of the chain capability with id ' || in_capability_id);
	END IF;
END;

FUNCTION CheckPermissionByFlow (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_capability_id			IN  capability.capability_id%TYPE,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_flow_capability_id		csr.customer_flow_capability.flow_capability_id%TYPE;
	v_perm_type					csr.customer_flow_capability.perm_type%TYPE;
	v_permission_set			security_pkg.T_PERMISSION;
	v_has_flow_relationships	BOOLEAN;
	v_supplier_on_purchaser		NUMBER;
	v_purchaser_company_sid		security_pkg.T_SID_ID DEFAULT in_purchaser_company_sid;
	v_supplier_company_sid		security_pkg.T_SID_ID DEFAULT in_supplier_company_sid;
BEGIN
	IF helper_pkg.IsElevatedAccount THEN
		RETURN TRUE;
	END IF;

	TryGetFlowCapability(in_capability_id, in_expected_pt, v_flow_capability_id, v_perm_type);
	
	IF v_flow_capability_id IS NULL THEN
			RETURN TRUE; -- it's not a flow capability, so just use the type check
	END IF;

	-- Flow capabilities are limited to read and write, but chain capabilities aren't.
	-- So we map read-like capabilities to read, and others (e.g. delete) to write.
	v_permission_set := 0;

	IF bitand(in_permission_set, security_pkg.PERMISSION_STANDARD_READ) != 0 THEN
		v_permission_set := v_permission_set + security_pkg.PERMISSION_READ;
	END IF;
	
	-- Minus works here because PERMISSION_STANDARD_ALL includes all of PERMISSION_STANDARD_READ
	IF bitand(in_permission_set, security_pkg.PERMISSION_STANDARD_ALL - security_pkg.PERMISSION_STANDARD_READ) != 0 THEN
		v_permission_set := v_permission_set + security_pkg.PERMISSION_WRITE;
	END IF;
	SELECT supplier_on_purchaser
	  INTO v_supplier_on_purchaser
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	IF v_supplier_on_purchaser = 1 THEN
		v_purchaser_company_sid := in_supplier_company_sid;
		v_supplier_company_sid := in_purchaser_company_sid;
	END IF;
	
	FOR r IN (
		SELECT flow_item_id, purchaser_company_sid, supplier_company_sid
		  FROM supplier_relationship sr
		 WHERE sr.active = chain_pkg.ACTIVE
		   AND sr.deleted = 0
		   AND sr.purchaser_company_sid = NVL(v_purchaser_company_sid, sr.purchaser_company_sid)
		   AND sr.supplier_company_sid = v_supplier_company_sid
		   AND flow_item_id IS NOT NULL
	) LOOP
		v_has_flow_relationships := TRUE;
		
		FOR rr IN (
			SELECT * FROM dual WHERE EXISTS (
				SELECT NULL
				  FROM csr.flow_item fi 
				  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
				  JOIN csr.supplier s ON s.company_sid = r.supplier_company_sid
				  LEFT JOIN v$purchaser_involvement inv
				    ON inv.supplier_company_sid = r.supplier_company_sid
				   AND inv.flow_involvement_type_id = fsrc.flow_involvement_type_id
				  LEFT JOIN csr.region_role_member rrm
						 ON rrm.region_sid = s.region_sid
						AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
						AND rrm.role_sid = fsrc.role_sid
				 WHERE fi.flow_item_id = r.flow_item_id
				   AND fsrc.flow_capability_id = v_flow_capability_id
				   AND (inv.flow_involvement_type_id IS NOT NULL
					OR (fsrc.flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
						AND r.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
					OR rrm.role_sid IS NOT NULL)
				HAVING BITAND(
							MAX(BITAND(fsrc.permission_set, security_pkg.PERMISSION_READ)) +
							MAX(BITAND(fsrc.permission_set, security_pkg.PERMISSION_WRITE)),
					   v_permission_set) = v_permission_set
			)
		) LOOP
			RETURN TRUE;
		END LOOP;
	END LOOP;

	RETURN NOT NVL(v_has_flow_relationships, FALSE);
END;

--boolean
FUNCTION IsCompanyPermissibleByFlow(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_capability				IN chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS 
	v_purchaser_company_sid		security_pkg.T_SID_ID DEFAULT NULL;
	v_supplier_company_sid		security_pkg.T_SID_ID DEFAULT in_company_sid;
	v_capability_id				capability.capability_id%TYPE;
BEGIN
	
	IF in_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		v_purchaser_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		v_capability_id := GetCapabilityId(in_capability, TRUE); --supplier capability
	ELSE
		--check flow permission against our own company
		v_capability_id := GetCapabilityId(in_capability, FALSE); --company capability
	END IF;
	
	RETURN CheckPermissionByFlow(
		v_purchaser_company_sid,
		v_supplier_company_sid,
		v_capability_id,
		BOOLEAN_PERM_SET,
		chain_pkg.BOOLEAN_PERMISSION
	);
END;

FUNCTION Internal_FilterPermSidsByFlow(
	in_company_sids_t			IN security.T_SID_TABLE,
	in_capability_id			IN capability.capability_id%TYPE,
	in_permission_set			IN security_Pkg.T_PERMISSION,
	in_expected_pt				IN chain_pkg.T_CAPABILITY_PERM_TYPE	
) RETURN security.T_SID_TABLE
AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_flow_capability_id		csr.customer_flow_capability.flow_capability_id%TYPE;
	v_perm_type					csr.customer_flow_capability.perm_type%TYPE;
	v_permission_set			security_pkg.T_PERMISSION;
	v_has_flow_relationships	BOOLEAN;
	v_supplier_on_purchaser		NUMBER;
	v_company_sids_t			security.T_SID_TABLE DEFAULT in_company_sids_t;
	v_sup_rel_t					T_SUPPLIER_RELATIONSHIP_TABLE;
BEGIN
	IF helper_pkg.IsElevatedAccount THEN
		RETURN v_company_sids_t;
	END IF;
	
	TryGetFlowCapability(in_capability_id, in_expected_pt, v_flow_capability_id, v_perm_type);
	
	IF v_flow_capability_id IS NULL THEN
		RETURN v_company_sids_t;
	END IF;	

	SELECT supplier_on_purchaser
	  INTO v_supplier_on_purchaser
	  FROM capability
	 WHERE capability_id = in_capability_id;
		
	-- Flow capabilities are limited to read and write, but chain capabilities aren't.
	-- So we map read-like capabilities to read, and others (e.g. delete) to write.
	v_permission_set := 0;

	IF bitand(in_permission_set, security_pkg.PERMISSION_STANDARD_READ) != 0 THEN
		v_permission_set := v_permission_set + security_pkg.PERMISSION_READ;
	END IF;
	
	-- Minus works here because PERMISSION_STANDARD_ALL includes all of PERMISSION_STANDARD_READ
	IF bitand(in_permission_set, security_pkg.PERMISSION_STANDARD_ALL - security_pkg.PERMISSION_STANDARD_READ) != 0 THEN
		v_permission_set := v_permission_set + security_pkg.PERMISSION_WRITE;
	END IF;
	
	--First collect the supplier (or purchaser) relationships of v_company_sid
	IF v_supplier_on_purchaser = 0 THEN
		SELECT T_SUPPLIER_RELATIONSHIP_ROW (v_company_sid, t.column_value, s.region_sid, sr.flow_item_id)
	  BULK COLLECT INTO v_sup_rel_t
	  FROM TABLE (v_company_sids_t) t
	  JOIN csr.supplier s ON s.company_sid = t.column_value
		  LEFT JOIN supplier_relationship sr 
		    ON sr.purchaser_company_sid = v_company_sid
		   AND sr.supplier_company_sid = t.column_value
			AND sr.active = chain_pkg.ACTIVE 
			AND sr.deleted = 0;
	ELSE
		SELECT T_SUPPLIER_RELATIONSHIP_ROW (t.column_value, v_company_sid, s.region_sid, sr.flow_item_id)
		  BULK COLLECT INTO v_sup_rel_t
		  FROM TABLE (v_company_sids_t) t
		  JOIN csr.supplier s ON s.company_sid = t.column_value
		  LEFT JOIN supplier_relationship sr 
		    ON sr.purchaser_company_sid = t.column_value
		   AND sr.supplier_company_sid = v_company_sid
		   AND sr.active = chain_pkg.ACTIVE 
		   AND sr.deleted = 0;
	END IF;
	
	--Get permissible companies 			
	SELECT company_sid
	  BULK COLLECT INTO v_company_sids_t
	  FROM (
		SELECT CASE v_supplier_on_purchaser WHEN 0 THEN t.supplier_company_sid ELSE t.purchaser_company_sid END company_sid
		  FROM csr.flow_item fi 
		  JOIN TABLE (v_sup_rel_t) t ON fi.flow_item_id = t.flow_item_id
		  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
		  LEFT JOIN csr.region_role_member rrm ON rrm.region_sid = t.supplier_region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') AND rrm.role_sid = fsrc.role_sid
		  LEFT JOIN v$purchaser_involvement inv
			ON inv.supplier_company_sid = t.supplier_company_sid
		   AND inv.flow_involvement_type_id = fsrc.flow_involvement_type_id
		 WHERE fsrc.flow_capability_id = v_flow_capability_id
		   AND (
				inv.flow_involvement_type_id IS NOT NULL
				OR (fsrc.flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
					AND t.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
				OR rrm.role_sid IS NOT NULL
			)
		  GROUP BY CASE v_supplier_on_purchaser WHEN 0 THEN t.supplier_company_sid ELSE t.purchaser_company_sid END
		 HAVING BITAND(MAX(BITAND(fsrc.permission_set, 1)) + MAX(BITAND(fsrc.permission_set, 2)), v_permission_set) = v_permission_set

		 UNION 
		SELECT DISTINCT CASE v_supplier_on_purchaser WHEN 0 THEN t.supplier_company_sid ELSE t.purchaser_company_sid END company_sid
		  FROM TABLE(v_sup_rel_t) t
		 WHERE t.flow_item_id IS NULL
	 );
	
	 RETURN v_company_sids_t;
END;

--boolean
FUNCTION FilterPermissibleSidsByFlow(
	in_company_sids_t			IN security.T_SID_TABLE,
	in_capability				IN chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
	v_capability_id capability.capability_id%TYPE DEFAULT GetCapabilityId(in_capability, TRUE); --always a suppler cap
BEGIN
	RETURN Internal_FilterPermSidsByFlow(in_company_sids_t, v_capability_id, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

--specific
FUNCTION FilterPermissibleSidsByFlow(
	in_company_sids_t			IN security.T_SID_TABLE,
	in_capability				IN chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE
AS
	v_capability_id capability.capability_id%TYPE DEFAULT GetCapabilityId(in_capability, TRUE); --always a suppler cap
BEGIN
	RETURN Internal_FilterPermSidsByFlow(in_company_sids_t, v_capability_id, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

FUNCTION CheckCapabilityByCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_capability_id			capability.capability_id%TYPE := GetCapabilityId(in_capability, FALSE);
BEGIN
	RETURN CheckPermissionByType(
		in_company_sid,
		NULL,
		NULL,
		v_capability_id,
		in_permission_set,
		in_expected_pt
	) AND CheckPermissionByFlow( 
		NULL,
		in_company_sid,
		v_capability_id, 
		in_permission_set, 
		in_expected_pt
	);
END;

FUNCTION CheckCapabilityBySupplier (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_can_see_all_companies		company.can_see_all_companies%TYPE;
	v_capability_id				capability.capability_id%TYPE := GetCapabilityId(in_capability, TRUE);
	v_supplier_on_purchaser		capability.supplier_on_purchaser%TYPE;
BEGIN
	IF in_primary_company_sid = in_secondary_company_sid THEN
		-- i don't think that this should be an issue in reasonable checks
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company_sid and the secondary_company_sid are the same company');	
	END IF;
	
	SELECT NVL(MIN(can_see_all_companies), 0)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_primary_company_sid;

	-- if the secondary company is our supplier or purchaser OR we have NO_RELATIONSHIP permission against it, then we can check the permissions on them
	IF helper_pkg.IsElevatedAccount 
	    OR v_can_see_all_companies = 1 
		OR (company_pkg.IsSupplier(in_primary_company_sid, in_secondary_company_sid) AND (in_tertiary_company_sid IS NULL OR company_pkg.IsSupplier(in_secondary_company_sid, in_tertiary_company_sid))) 
		OR (company_pkg.IsSupplier(in_secondary_company_sid, in_primary_company_sid) AND in_tertiary_company_sid IS NULL)
		OR CheckNoRelationshipPermission(in_primary_company_sid, in_secondary_company_sid, security_pkg.PERMISSION_READ) 
	THEN
		v_capability_id := GetCapabilityId(in_capability, TRUE);

		RETURN CheckPermissionByType(
			in_primary_company_sid, 
			company_type_pkg.GetCompanyTypeId(in_secondary_company_sid), 
			company_type_pkg.GetCompanyTypeId(in_tertiary_company_sid, TRUE), 
			v_capability_id, 
			in_permission_set, 
			in_expected_pt
		) AND CheckPermissionByFlow( 
			in_primary_company_sid,
			in_secondary_company_sid,
			v_capability_id, 
			in_permission_set, 
			in_expected_pt
		);
	END IF;

	RETURN FALSE;	
END;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
BEGIN
	-- let's restrict which capabilities this can use this flow as it bypasses supplier relationship checking 
	-- which is only really valid before the relationship is established
	IF NOT IsOnBehalfOfCapability(in_capability) AND in_capability NOT IN (
		chain_pkg.SEND_QUESTIONNAIRE_INVITE,
		chain_pkg.SEND_COMPANY_INVITE,
		chain_pkg.SEND_INVITE_ON_BEHALF_OF,
		chain_pkg.SUPPLIERS,
		chain_pkg.CREATE_COMPANY_WITHOUT_INVIT,
		chain_pkg.CREATE_USER_WITHOUT_INVITE,
		chain_pkg.ADD_REMOVE_RELATIONSHIPS,
		chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB,
		chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS,
		chain_pkg.SUPPLIER_NO_RELATIONSHIP,
		chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY,
		chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		chain_pkg.CREATE_RELATIONSHIP
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check the '''||in_capability||''' by supplier type only');	
	END IF;
	
	RETURN CheckPermissionByType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, GetCapabilityId(in_capability, TRUE), in_permission_set, in_expected_pt);
END;

FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_can_see_all_companies		company.can_see_all_companies%TYPE;
	v_capability_id				capability.capability_id%TYPE DEFAULT GetCapabilityId(in_capability, TRUE);
BEGIN
	-- let's restrict which capabilities this can use this flow as it bypasses supplier relationship checking 
	-- which is only really valid before the relationship is established
	IF NOT IsOnBehalfOfCapability(in_capability) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check the '''||in_capability||''' by tertiary type');
	END IF;

	IF in_primary_company_sid = in_secondary_company_sid THEN
		-- i don't think that this should be an issue in reasonable checks
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company_sid and the secondary_company_sid are the same company');	
	END IF;
	
	SELECT NVL(MIN(can_see_all_companies), 0)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_primary_company_sid;

	-- if the secondary company is our supplier OR we have NO_RELATIONSHIP permission against it, then we can check the permissions on them
	IF helper_pkg.IsElevatedAccount 
	    OR v_can_see_all_companies = 1 
		OR company_pkg.IsSupplier(in_primary_company_sid, in_secondary_company_sid) 
		OR CheckNoRelationshipPermission(in_primary_company_sid, in_secondary_company_sid, security_pkg.PERMISSION_READ) 
	THEN
		RETURN CheckPermissionByType(in_primary_company_sid, company_type_pkg.GetCompanyTypeId(in_secondary_company_sid), in_tertiary_company_type, v_capability_id, in_permission_set, in_expected_pt)
			AND CheckPermissionByFlow(in_primary_company_sid, in_secondary_company_sid, v_capability_id, in_permission_set, in_expected_pt);
	END IF;
	
	RETURN FALSE;
END;

FUNCTION CheckCapByAnySupplierType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_granted				BOOLEAN DEFAULT FALSE;
BEGIN
	
	FOR r IN (
		SELECT x.primary_company_type_id, x.secondary_company_type_id, x.tertiary_company_type_id
		  FROM (
			SELECT ctr1.primary_company_type_id, ctr1.secondary_company_type_id, null tertiary_company_type_id
			  FROM company c, company_type_relationship ctr1
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.company_sid = in_company_sid
			   AND c.app_sid = ctr1.app_sid
			   AND c.company_type_id = ctr1.primary_company_type_id
			 UNION ALL
			SELECT ctr1.primary_company_type_id, ctr1.secondary_company_type_id, ctr2.secondary_company_type_id tertiary_company_type_id
			  FROM company c, company_type_relationship ctr1, company_type_relationship ctr2
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.company_sid = in_company_sid
			   AND c.app_sid = ctr1.app_sid
			   AND c.company_type_id = ctr1.primary_company_type_id
			   AND ctr1.app_sid = ctr2.app_sid
			   AND ctr1.secondary_company_type_id = ctr2.primary_company_type_id
			) x, capability c
		 WHERE c.capability_name = in_capability
		   AND ((c.capability_type_id = 3 AND x.tertiary_company_type_id IS NOT NULL)
				OR
				(c.capability_type_id <> 3 AND x.tertiary_company_type_id IS NULL))
	) LOOP	
		
		v_granted := v_granted OR CheckPermissionByType(in_company_sid, r.secondary_company_type_id, r.tertiary_company_type_id, GetCapabilityId(in_capability, TRUE), in_permission_set, in_expected_pt);
		IF v_granted THEN
			RETURN TRUE;
		END IF;
	END LOOP;
	
	RETURN FALSE;
END;

FUNCTION CheckCapByAllSupplierType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_granted				BOOLEAN DEFAULT TRUE;
BEGIN
	FOR r IN (
		SELECT ctr.secondary_company_type_id
		  FROM company_type_relationship ctr, company c
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.company_sid = in_company_sid
		   AND c.app_sid = ctr.app_sid
		   AND c.company_type_id = ctr.primary_company_type_id
	) LOOP
		v_granted := v_granted AND CheckPermissionByType(in_company_sid, r.secondary_company_type_id, NULL, in_capability, in_permission_set, in_expected_pt);
		IF NOT v_granted THEN
			RETURN FALSE;
		END IF;
	END LOOP;
	
	RETURN TRUE;
END;

FUNCTION INTERNALCheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
BEGIN
	IF (in_secondary_company_sid IS NULL AND in_tertiary_company_sid IS NULL) OR
	   (in_primary_company_sid = in_secondary_company_sid AND in_tertiary_company_sid IS NULL) THEN
		RETURN CheckCapabilityByCompany(in_primary_company_sid, in_capability, in_permission_set, in_expected_pt);
	ELSIF in_secondary_company_sid IS NOT NULL THEN
		RETURN CheckCapabilityBySupplier(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_sid, in_capability, in_permission_set, in_expected_pt);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Cannot determine check type');
	END IF;
END;

PROCEDURE RefreshChainAdminPermissionSet (
	in_company_type_id			IN  company_type.company_type_id%TYPE,
	in_capability_id			IN  chain_pkg.T_CAPABILITY DEFAULT NULL
)
AS
	v_company_ca_group_type_id 	company_group_type.company_group_type_id%TYPE DEFAULT company_pkg.GetCompanyGroupTypeId(chain_pkg.CHAIN_ADMIN_GROUP);
	v_ca_permission_set			security_pkg.T_PERMISSION DEFAULT 0;
BEGIN
	INSERT INTO company_type_capability
	(primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id)
	SELECT primary_company_type_id, v_company_ca_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
	  FROM (
	  	SELECT UNIQUE primary_company_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
	  	  FROM company_type_capability
	  	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   AND primary_company_type_id = in_company_type_id
	  	   AND capability_id = NVL(in_capability_id, capability_id)
	  	)
	MINUS
	SELECT primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
	  FROM company_type_capability
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND primary_company_type_id = in_company_type_id
	   AND primary_company_group_type_id = v_company_ca_group_type_id
	   AND capability_id = NVL(in_capability_id, capability_id);
	
	FOR r IN (
		SELECT primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM company_type_capability
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND primary_company_type_id = in_company_type_id
		   AND primary_company_group_type_id = v_company_ca_group_type_id
		   AND capability_id = NVL(in_capability_id, capability_id) 
	) LOOP
		v_ca_permission_set := 0;
		
		FOR p IN (
			SELECT ctc.permission_set
			  FROM company_type_capability ctc
			  LEFT JOIN company_group_type cgt ON ctc.primary_company_group_type_id = cgt.company_group_type_id
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
		UPDATE company_type_capability
		   SET permission_set = v_ca_permission_set
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND primary_company_type_id = r.primary_company_type_id
		   AND primary_company_group_type_id = v_company_ca_group_type_id
		   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
		   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
		   AND capability_id = r.capability_id;
	END LOOP;
END;

PROCEDURE SetPermissionNOSEC (
	in_primary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_secondary_company_type_id	IN  company_type.company_type_id%TYPE,
	in_tertiary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_company_group_type_id		IN  company_group_type.company_group_type_id%TYPE,
	in_capability_id				IN  capability.capability_id%TYPE,
	in_permission_set				IN  security_pkg.T_PERMISSION,
	in_expected_pt					IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_role_sid						IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_count							NUMBER(10);
BEGIN	
	CheckPermType(in_capability_id, in_expected_pt);
	
	IF in_secondary_company_type_id IS NULL AND in_tertiary_company_type_id IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'No capability type supports the tertiary company type being set when the secondary company type is not set');
	ELSIF in_secondary_company_type_id IS NULL AND IsSupplierCapability(in_capability_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set a supplier capability when the secondary company type is not set');
	ELSIF in_secondary_company_type_id IS NOT NULL AND in_tertiary_company_type_id IS NULL AND NOT IsSupplierCapability(in_capability_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Secondary company type was set but the capability with id '||in_capability_id||' does not support it');
	ELSIF in_secondary_company_type_id IS NOT NULL AND in_tertiary_company_type_id IS NOT NULL AND NOT IsOnBehalfOfCapability(in_capability_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Secondary and tertiary company types were set but the capability with id '||in_capability_id||' does not support it');
	END IF;
	
	IF in_company_group_type_id IS NOT NULL AND IsGlobalGroup(in_company_group_type_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot explicitly set permissions for global groups');
	END IF;
	
	-- insert or update required permission
	BEGIN
		INSERT INTO company_type_capability
		(primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id, permission_set, primary_company_type_role_sid)
		VALUES
		(in_primary_company_type_id, in_company_group_type_id, in_capability_id, in_secondary_company_type_id, in_tertiary_company_type_id, in_permission_set, in_role_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE company_type_capability
			   SET permission_set = in_permission_set
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND primary_company_type_id = in_primary_company_type_id
			   AND NVL(primary_company_group_type_id, 0) = NVL(in_company_group_type_id, 0)
			   AND NVL(secondary_company_type_id, 0) = NVL(in_secondary_company_type_id, 0)
			   AND NVL(tertiary_company_type_id, 0) = NVL(in_tertiary_company_type_id, 0)
			   AND NVL(primary_company_type_role_sid, 0) = NVL(in_role_sid, 0)
			   AND capability_id = in_capability_id;
	END;
	
	LogTypeCapabilityChange (
		in_permission_set				=> in_permission_set,
		in_capability_id      			=> in_capability_id,
		in_primary_company_type_id		=> in_primary_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> in_tertiary_company_type_id,
		in_company_group_type_id		=> in_company_group_type_id,
		in_company_role_sid				=> in_role_sid
	);
	
	RefreshChainAdminPermissionSet(in_primary_company_type_id, in_capability_id);
END;

PROCEDURE SetPermissionNOSEC (
	in_primary_company_type			IN  company_type.lookup_key%TYPE,
	in_secondary_company_type		IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type		IN  company_type.lookup_key%TYPE,
	in_group						IN  chain_pkg.T_GROUP,
	in_capability_id				IN  capability.capability_id%TYPE,
	in_permission_set				IN  security_pkg.T_PERMISSION,
	in_expected_pt					IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_role_sid						IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_primary_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_primary_company_type);
	v_secondary_company_type_id		company_type.company_type_id%TYPE;
	v_tertiary_company_type_id		company_type.company_type_id%TYPE;
	v_company_group_type_id 		company_group_type.company_group_type_id%TYPE;
BEGIN	
	IF in_secondary_company_type IS NOT NULL THEN
		v_secondary_company_type_id := company_type_pkg.GetCompanyTypeId(in_secondary_company_type);
	END IF;

	IF in_tertiary_company_type IS NOT NULL THEN
		v_tertiary_company_type_id := company_type_pkg.GetCompanyTypeId(in_tertiary_company_type);
	END IF;
	
	IF in_role_sid IS NULL THEN
		v_company_group_type_id := company_pkg.GetCompanyGroupTypeId(in_group);
	END IF;

	SetPermissionNOSEC(
		in_primary_company_type_id		=>	v_primary_company_type_id,
		in_secondary_company_type_id	=>	v_secondary_company_type_id,
		in_tertiary_company_type_id		=>	v_tertiary_company_type_id,
		in_company_group_type_id		=>	v_company_group_type_id,
		in_capability_id				=>	in_capability_id,
		in_permission_set				=>	in_permission_set,
		in_expected_pt					=>	in_expected_pt,
		in_role_sid						=>	in_role_sid
	);
END;

PROCEDURE SetPermission_ (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_id			IN  capability.capability_id%TYPE,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCapabilityPermission can only be run as BuiltIn/Administrator or Superadmin');
	END IF;
  
	SetPermissionNOSEC(
		in_primary_company_type			=>	in_primary_company_type,
		in_secondary_company_type		=>	in_secondary_company_type,
		in_tertiary_company_type		=>	in_tertiary_company_type,
		in_group						=>	in_group,
		in_capability_id				=>	in_capability_id,
		in_permission_set				=>  in_permission_set,
		in_expected_pt					=>	in_expected_pt,
		in_role_sid						=>	in_role_sid
	);
End;

PROCEDURE SetPermission (
	in_capability_id				IN  capability.capability_id%TYPE,
	in_primary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_secondary_company_type_id	IN  company_type.company_type_id%TYPE,
	in_tertiary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_company_group_type_id		IN  company_group_type.company_group_type_id%TYPE,
	in_role_sid						IN  security_pkg.T_SID_ID,
	in_permission_set    			IN  security_pkg.T_PERMISSION
)
AS
	v_expected_pt						chain_pkg.T_CAPABILITY_PERM_TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCapabilityPermission can only be run as BuiltIn/Administrator or Superadmin');
	END IF;

	-- This SP trusts the caller to get the right sort of permission.
	SELECT perm_type
	  INTO v_expected_pt
	  FROM capability
	 WHERE capability_id = in_capability_id;

	SetPermissionNOSEC(
		in_primary_company_type_id	=>	in_primary_company_type_id,
		in_secondary_company_type_id =>	in_secondary_company_type_id,
		in_tertiary_company_type_id	=>	in_tertiary_company_type_id,
		in_company_group_type_id	=>	in_company_group_type_id,
		in_capability_id			=>	in_capability_id,
		in_permission_set			=>	in_permission_set,
		in_expected_pt				=>	v_expected_pt,
		in_role_sid					=>	in_role_sid
	);
END;

/**************************************************************
			SEMI-PRIVATE (PROTECTED) METHODS
**************************************************************/
-- this method is public so that it can be accessed by card_pkg
PROCEDURE CheckPermType (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_perm_type				chain_pkg.T_CAPABILITY_PERM_TYPE;
	v_capability_name		chain_pkg.T_CAPABILITY;
BEGIN
	BEGIN
		SELECT perm_type, capability_name
		  INTO v_perm_type, v_capability_name
		  FROM capability
		 WHERE capability_id = in_capability_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||') not found');
	END;

	IF v_perm_type <> in_expected_pt THEN
		CASE 
			WHEN in_expected_pt = chain_pkg.BOOLEAN_PERMISSION THEN
				RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||' - '||v_capability_name||') permission is not BOOLEAN type');
			WHEN in_expected_pt = chain_pkg.SPECIFIC_PERMISSION THEN
				RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||' - '||v_capability_name||') permission is not SPECIFIC type');
		END CASE;
	END IF;
END;

-- this method is public so that it can be accessed by card_pkg
FUNCTION GetCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN capability.capability_id%TYPE
AS
	v_cap_id				capability.capability_id%TYPE;
BEGIN
	BEGIN
		SELECT capability_id
		  INTO v_cap_id
		  FROM capability
		 WHERE capability_type_id = in_capability_type
		   AND capability_name = in_capability;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability "'||in_capability||'" with type '''||in_capability_type||'''not found');
	END;
	
	RETURN v_cap_id;		
END;

FUNCTION ResolveCapabilityType(
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL
) RETURN chain_pkg.T_CAPABILITY_TYPE
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN	
		RETURN chain_pkg.CT_COMMON;
	ELSIF IsOnBehalfOfCapability(in_capability) THEN
		RETURN chain_pkg.CT_ON_BEHALF_OF;
	ELSIF in_secondary_company_type IS NULL AND IsCapabilityCTCompany(in_capability) THEN
		RETURN chain_pkg.CT_COMPANY;
	ELSIF in_secondary_company_type IS NOT NULL AND IsCapabilityCTSuppliers(in_capability) THEN
		RETURN chain_pkg.CT_SUPPLIERS;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Capability type cannot be resolved for capability:' || in_capability || ' and secondary company type:' || in_secondary_company_type);
END;

-- this method is public so that it can be accessed by card_pkg
FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_capability_type			chain_pkg.T_CAPABILITY_TYPE;
BEGIN
	SELECT MAX(capability_type_id) 
	  INTO v_capability_type
	  FROM capability
	 WHERE capability_name = in_capability;
	
	RETURN v_capability_type = chain_pkg.CT_COMMON;
END;

FUNCTION Internal_GetPermCompanySids (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_secondary_company_type_id	IN  company_group_type.company_group_type_id%TYPE DEFAULT NULL,
	in_tertiary_company_type_id		IN  company_group_type.company_group_type_id%TYPE DEFAULT NULL,
	in_company_sids				IN  security.T_SID_TABLE DEFAULT NULL
) RETURN security.T_SID_TABLE
AS
	v_context_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_temp_company_sids			security.T_SID_TABLE;
	v_table						security.T_SID_TABLE := security.T_SID_TABLE();
	v_perm_cts 					T_PERMISSIBLE_TYPES_TABLE := T_PERMISSIBLE_TYPES_TABLE();	
	v_no_relationship_cts		security.T_SID_TABLE;		
	v_has_no_relationship_count	NUMBER;
	v_primary_company_type_id	company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId;
	v_capability_id				capability.capability_id%TYPE DEFAULT GetCapabilityId(in_capability, TRUE);
	v_non_relat_cap_id			capability.capability_id%TYPE DEFAULT GetCapabilityId(chain_pkg.SUPPLIER_NO_RELATIONSHIP, TRUE);
	v_filter_by_com_list		NUMBER DEFAULT 1;
	v_supplier_on_purchaser		NUMBER;
BEGIN
		
	IF in_company_sids IS NULL THEN
		v_filter_by_com_list := 0;
	END IF;
	
	SELECT supplier_on_purchaser
	  INTO v_supplier_on_purchaser
	  FROM chain.capability
	 WHERE capability_id = v_capability_id;
	
	FillUserGroups;
	
	--get permissible company types based on type capabilities
	FOR r IN (
		SELECT UNIQUE ctc.primary_company_type_id, ctc.secondary_company_type_id, ctc.tertiary_company_type_id
		  FROM company_type_capability ctc
		 WHERE ctc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (
				(
				   v_supplier_on_purchaser = 0
				   AND ctc.primary_company_type_id = v_primary_company_type_id
				   AND COALESCE(ctc.secondary_company_type_id, 0) = COALESCE(in_secondary_company_type_id, ctc.secondary_company_type_id, 0)
				) OR (
				   v_supplier_on_purchaser = 1
				   AND ctc.primary_company_type_id = NVL(in_secondary_company_type_id, ctc.primary_company_type_id)
				   AND ctc.secondary_company_type_id = v_primary_company_type_id
				)
		   )
		   AND COALESCE(ctc.tertiary_company_type_id, 0) = COALESCE(in_tertiary_company_type_id, ctc.tertiary_company_type_id, 0)
		   AND ctc.capability_id = v_capability_id
	) 
	LOOP
		IF CheckPermissionByType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), CASE WHEN v_supplier_on_purchaser = 1 THEN r.primary_company_type_id ELSE r.secondary_company_type_id END, r.tertiary_company_type_id, v_capability_id, in_permission_set, in_expected_pt) THEN
			v_perm_cts.extend;
			v_perm_cts(v_perm_cts.count) := T_PERMISSIBLE_TYPES_ROW(v_capability_id, r.primary_company_type_id, r.secondary_company_type_id, r.tertiary_company_type_id);
		END IF;
	END LOOP;
			
	IF v_supplier_on_purchaser = 0 THEN		
		--collect the secondary company types we have no_relationship permissions on
		SELECT DISTINCT ctc.secondary_company_type_id
		  BULK COLLECT INTO v_no_relationship_cts
		  FROM TT_USER_GROUPS ug
		  JOIN company_group cg ON ug.group_sid = cg.group_sid AND ug.company_sid = cg.company_sid
		  JOIN company_type_capability ctc ON cg.app_sid = ctc.app_sid AND cg.company_group_type_id = ctc.primary_company_group_type_id
		  JOIN capability cap ON ctc.capability_id = cap.capability_id
		 WHERE ug.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND cg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctc.capability_id = v_non_relat_cap_id
		   AND ctc.primary_company_group_type_id IS NOT NULL
		   AND ctc.primary_company_type_id = v_primary_company_type_id
		   AND ctc.secondary_company_type_id = NVL(in_secondary_company_type_id, ctc.secondary_company_type_id)
		   AND security.bitwise_pkg.bitand(ctc.permission_set, security.security_pkg.PERMISSION_READ) = security.security_pkg.PERMISSION_READ;
	   
		--we only need the secondary types that passed the permission check
		FOR r IN(
			SELECT DISTINCT secondary_company_type_id
			  FROM TABLE(v_perm_cts)
		)
		LOOP
			SELECT COUNT(*)
			  INTO v_has_no_relationship_count
			  FROM TABLE(v_no_relationship_cts)
			 WHERE column_value = r.secondary_company_type_id;
			
			--get all secondary suppliers (related)
			IF v_has_no_relationship_count = 0 THEN
				SELECT c.company_sid 
			      BULK COLLECT INTO v_temp_company_sids
				  FROM chain.company c
				  JOIN supplier_relationship sr 
					ON sr.purchaser_company_sid = v_context_company_sid
				   AND sr.supplier_company_sid = c.company_sid
				   AND sr.active = chain_pkg.ACTIVE 
				   AND sr.deleted = 0
				  LEFT JOIN (SELECT column_value FROM TABLE(in_company_sids) ORDER BY column_value) com_list ON com_list.column_value = c.company_sid
				 WHERE c.company_type_id = r.secondary_company_type_id
				   AND (v_filter_by_com_list = 1 AND com_list.column_value IS NOT NULL OR v_filter_by_com_list = 0);
			ELSE -- (not related)
				SELECT c.company_sid 
				  BULK COLLECT INTO v_temp_company_sids
				  FROM chain.company c
				  LEFT JOIN TABLE(in_company_sids) com_list ON com_list.column_value = c.company_sid
				 WHERE c.company_type_id = r.secondary_company_type_id
				   AND (v_filter_by_com_list = 1 AND com_list.column_value IS NOT NULL OR v_filter_by_com_list = 0);
			END IF;
		
			--finally filter supplier list by flow permissions
			v_temp_company_sids := Internal_FilterPermSidsByFlow(
				v_temp_company_sids,
				v_capability_id,
				in_permission_set,
				in_expected_pt
			);
			
			v_table := v_table MULTISET UNION v_temp_company_sids;
		END LOOP;
	ELSIF v_supplier_on_purchaser = 1 THEN
		--we need the primary types that passed the permission check
		FOR r IN(
			SELECT DISTINCT primary_company_type_id
			  FROM TABLE(v_perm_cts)
		)
		LOOP
			--get only related purchasers
			SELECT c.company_sid 
			  BULK COLLECT INTO v_temp_company_sids
			  FROM chain.company c
			  JOIN supplier_relationship sr 
				ON sr.supplier_company_sid = v_context_company_sid
			   AND sr.purchaser_company_sid = c.company_sid
			   AND sr.active = chain_pkg.ACTIVE 
			   AND sr.deleted = 0
			  LEFT JOIN TABLE(in_company_sids) com_list ON com_list.column_value = c.company_sid
			 WHERE c.company_type_id = r.primary_company_type_id
			   AND (v_filter_by_com_list = 1 AND com_list.column_value IS NOT NULL OR v_filter_by_com_list = 0);
			  
			--finally filter purchasers list by flow permissions
			v_temp_company_sids := Internal_FilterPermSidsByFlow(
				v_temp_company_sids,
				v_capability_id,
				in_permission_set,
				in_expected_pt
			);
						
			v_table := v_table MULTISET UNION v_temp_company_sids;
		END LOOP;
		END IF;
	RETURN v_table;
END;

--boolean
FUNCTION GetPermissibleCompanySids (
	in_capability				IN  chain_pkg.T_CAPABILITY
	
) RETURN security.T_SID_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanySids(in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

--specific
FUNCTION GetPermissibleCompanySids (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION	
) RETURN security.T_SID_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanySids(in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

FUNCTION FilterPermissibleCompanySids (
	in_company_sids_t			IN  security.T_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanySids(in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, NULL, NULL, in_company_sids_t);
END;

FUNCTION FilterPermissibleCompanySids (
	in_company_sid_page			IN  security.T_ORDERED_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE
AS
	v_sid_table		security.T_SID_TABLE;
BEGIN
	SELECT sid_id
	  BULK COLLECT INTO v_sid_table
	  FROM TABLE(in_company_sid_page);
	 
	RETURN FilterPermissibleCompanySids(v_sid_table, in_capability, in_permission_set);
END;

FUNCTION FilterPermissibleCompanySids (
	in_company_sid_filter		IN  T_FILTERED_OBJECT_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE
AS
	v_sid_table		security.T_SID_TABLE;
BEGIN
	SELECT object_id
	  BULK COLLECT INTO v_sid_table
	  FROM TABLE(in_company_sid_filter);
	 
	RETURN FilterPermissibleCompanySids(v_sid_table, in_capability, in_permission_set);
END;

FUNCTION FilterPermissibleCompanySids (
	in_company_sids_t			IN  security.T_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
BEGIN	
	RETURN Internal_GetPermCompanySids(in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION, NULL, NULL, in_company_sids_t);
END;

FUNCTION FilterPermissibleCompanySids (
	in_company_sid_page			IN  security.T_ORDERED_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
	v_sid_table		security.T_SID_TABLE;
BEGIN
	SELECT sid_id
	  BULK COLLECT INTO v_sid_table
	  FROM TABLE(in_company_sid_page);
	  
	RETURN FilterPermissibleCompanySids(v_sid_table, in_capability);
END;
	
FUNCTION GetPermCompanySidsByTypes (
	in_capability					IN  chain_pkg.T_CAPABILITY,
	in_secondary_company_type_id	IN  company_type.company_type_id%TYPE DEFAULT NULL,
	in_tertiary_company_type_id		IN  company_type.company_type_id%TYPE DEFAULT NULL
)RETURN security.T_SID_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanySids(in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION, in_secondary_company_type_id, in_tertiary_company_type_id);
END;
	
FUNCTION Internal_GetPermCompanyTypes (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN T_PERMISSIBLE_TYPES_TABLE
AS
	v_table						T_PERMISSIBLE_TYPES_TABLE := T_PERMISSIBLE_TYPES_TABLE();
	v_primary_company_type_id	company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId;
	v_secondary_company_type_id	company_type.company_type_id%TYPE;
	v_capability				chain_pkg.T_CAPABILITY DEFAULT in_capability;
BEGIN

	IF in_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		v_secondary_company_type_id := company_type_pkg.GetCompanyTypeId(in_company_sid);
	END IF;
	
	FOR r IN (
		SELECT UNIQUE ctc.primary_company_type_id, ctc.secondary_company_type_id, ctc.tertiary_company_type_id, ctc.capability_id, cap.supplier_on_purchaser
		  FROM company_type_capability ctc, capability cap
		 WHERE ctc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctc.capability_id = cap.capability_id
		   AND (
				(
				   cap.supplier_on_purchaser = 0
		   AND ctc.primary_company_type_id = v_primary_company_type_id
		   AND COALESCE(ctc.secondary_company_type_id, 0) = COALESCE(v_secondary_company_type_id, ctc.secondary_company_type_id, 0)
				) OR (
				   cap.supplier_on_purchaser = 1
				   AND ctc.primary_company_type_id = NVL(v_secondary_company_type_id, ctc.primary_company_type_id)
				   AND ctc.secondary_company_type_id = v_primary_company_type_id
				)
		   )		  
		   AND cap.capability_name = v_capability
	) LOOP
		IF CheckPermissionByType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), CASE WHEN r.supplier_on_purchaser = 1 THEN r.primary_company_type_id ELSE r.secondary_company_type_id END, r.tertiary_company_type_id, r.capability_id, in_permission_set, in_expected_pt) THEN
			v_table.extend;
			v_table ( v_table.count ) := T_PERMISSIBLE_TYPES_ROW(r.capability_id, r.primary_company_type_id, r.secondary_company_type_id, r.tertiary_company_type_id);
			END IF;
	END LOOP;
		
	RETURN v_table;
END;

--boolean
FUNCTION GetPermissibleCompanyTypes (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN T_PERMISSIBLE_TYPES_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanyTypes(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

--specific
FUNCTION GetPermissibleCompanyTypes (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
) RETURN T_PERMISSIBLE_TYPES_TABLE
AS
BEGIN
	RETURN Internal_GetPermCompanyTypes(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

FUNCTION GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capabilities				IN  T_STRING_LIST
) RETURN T_PERMISSIBLE_TYPES_TABLE
AS 
	v_tmp_table			T_PERMISSIBLE_TYPES_TABLE;
	v_final_table		T_PERMISSIBLE_TYPES_TABLE := chain.T_PERMISSIBLE_TYPES_TABLE();
BEGIN
	
	FOR i IN in_capabilities.FIRST .. in_capabilities.LAST 
	LOOP
		v_tmp_table := Internal_GetPermCompanyTypes(in_company_sid, in_capabilities(i), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
		v_final_table := v_final_table MULTISET UNION v_tmp_table;
	END LOOP;
	
	RETURN v_final_table;
END;

/*-------------*/
--Wrappers for C#
--boolean
PROCEDURE GetPermissibleCompanyTypes (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_table T_PERMISSIBLE_TYPES_TABLE DEFAULT GetPermissibleCompanyTypes(in_company_sid, in_capability);
BEGIN
	OPEN out_cur FOR
		SELECT capability_id, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id  
		  FROM TABLE(v_table);
END;

PROCEDURE GetPermissibleCompanyTypes(
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, out_cur);
END;

--specific
PROCEDURE GetPermissibleCompanyTypes (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_table T_PERMISSIBLE_TYPES_TABLE DEFAULT GetPermissibleCompanyTypes(in_company_sid, in_capability, in_permission_set);
BEGIN
	OPEN out_cur FOR
		SELECT capability_id, primary_company_type_id, secondary_company_type_id, tertiary_company_type_id  
		  FROM TABLE(v_table);
END;
/*-------------*/

/* Checks whether the supplier company type belongs to the secondary permissible company types types against a capability. 
Used in card group card's required capability against a supplier*/
FUNCTION IsSupplierCompTypePermissible (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_supplier_company_type_id	IN  company_type.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS 
	v_count 			NUMBER;
	v_permissible_table		T_PERMISSIBLE_TYPES_TABLE := Internal_GetPermCompanyTypes(in_company_sid, in_capability, in_permission_set, in_expected_pt);
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM TABLE(v_permissible_table)
	 WHERE secondary_company_type_id = in_supplier_company_type_id;
	
	RETURN v_count > 0;
END;
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID DEFAULT NULL
) RETURN BOOLEAN
AS
	v_is_supplier			capability.is_supplier%TYPE;
	v_capability_name		capability.capability_name%TYPE;
	v_expected_permission	chain_pkg.T_CAPABILITY_PERM_TYPE DEFAULT CASE WHEN in_permission_set IS NULL THEN chain_pkg.BOOLEAN_PERMISSION ELSE chain_pkg.SPECIFIC_PERMISSION END;
	v_permission_set 		security_Pkg.T_PERMISSION DEFAULT CASE WHEN in_permission_set IS NULL THEN BOOLEAN_PERM_SET ELSE in_permission_set END;
BEGIN
			
	SELECT is_supplier, capability_name
	  INTO v_is_supplier, v_capability_name
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	IF v_is_supplier = 0 THEN
		RETURN CheckPermissionByType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), NULL, NULL, in_capability_id, v_permission_set, v_expected_permission)
		   AND CheckPermissionByFlow(NULL, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability_id, v_permission_set, v_expected_permission);
	ELSE 
		IF in_supplier_company_sid IS NOT NULL THEN
			RETURN IsSupplierCompTypePermissible(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), company_type_pkg.GetCompanyTypeId(in_supplier_company_sid), v_capability_name, v_permission_set, v_expected_permission)
					AND CheckPermissionByFlow(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, in_capability_id, v_permission_set, v_expected_permission);
		/* otherwise we check whether the capability is enabled against any company */
		ELSE
			RETURN CheckCapByAnySupplierType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_capability_name, v_permission_set, v_expected_permission);
		END IF;
	END IF;
END;

/***********************************************************************************************************************
************************************************************************************************************************
************************************************************************************************************************
		PUBLIC
************************************************************************************************************************
************************************************************************************************************************
***********************************************************************************************************************/

/************************************************************** 
		SETUP AND INITIALIZATION METHODS 
**************************************************************/
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_is_supplier				IN  chain_pkg.T_SUPPLIER_CENTRIC_CAPBILITY DEFAULT chain_pkg.INHERIT_IS_SUP_CAPABILITY,
	in_description				IN	capability.description%TYPE DEFAULT NULL
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_is_supplier = chain_pkg.INHERIT_IS_SUP_CAPABILITY AND in_capability_type = chain_pkg.CT_ROOT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Root capabilities cannot be inherited');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		
		IF in_is_supplier <> chain_pkg.INHERIT_IS_SUP_CAPABILITY THEN
			RAISE_APPLICATION_ERROR(-20001, 'Companies capabilities must be inherited');
		END IF;
		
		RegisterCapability(chain_pkg.CT_COMPANY, in_capability, in_perm_type, chain_pkg.IS_NOT_SUPPLIER_CAPABILITY, in_description);
		RegisterCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_perm_type, chain_pkg.IS_SUPPLIER_CAPABILITY, in_description);
		RETURN;	
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANY AND in_is_supplier <> chain_pkg.IS_NOT_SUPPLIER_CAPABILITY THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type IN (chain_pkg.CT_SUPPLIERS, chain_pkg.CT_ON_BEHALF_OF) AND in_is_supplier <> chain_pkg.IS_SUPPLIER_CAPABILITY THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
	   			(capability_type_id = chain_pkg.CT_COMMON AND (in_capability_type = chain_pkg.CT_COMPANY OR in_capability_type = chain_pkg.CT_SUPPLIERS))
	   		 OR (in_capability_type = chain_pkg.CT_COMMON AND (capability_type_id = chain_pkg.CT_COMPANY OR capability_type_id = chain_pkg.CT_SUPPLIERS))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier, description) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier, in_description);

END;

/******************************************
	GrantCapability
******************************************/
-- boolean
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS	
BEGIN	
	RAISE_APPLICATION_ERROR(-20001, 'All calls to GrantCapability should be replaced by SetPermission');
END;

-- boolean
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS	
BEGIN	
	RAISE_APPLICATION_ERROR(-20001, 'All calls to GrantCapability should be replaced by SetPermission');
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to GrantCapability should be replaced by SetPermission');
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to GrantCapability should be replaced by SetPermission');
END;

/******************************************
	HideCapability
******************************************/
PROCEDURE HideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to HideCapability should be replaced by SetPermission');
END;

PROCEDURE HideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to HideCapability should be replaced by SetPermission');
END;

PROCEDURE UnhideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to UnhideCapability should be replaced by SetPermission');
END;

PROCEDURE UnhideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to UnhideCapability should be replaced by SetPermission');
END;

/******************************************
	OverrideCapability
******************************************/
-- boolean
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to OverrideCapability should be replaced by SetPermission');
END;

-- boolean
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to OverrideCapability should be replaced by SetPermission');
END;

--specific
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to OverrideCapability should be replaced by SetPermission');
END;

--specific
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to OverrideCapability should be replaced by SetPermission');
END;

/******************************************
	SetCapabilityPermission
******************************************/
-- boolean
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to SetCapabilityPermission should be replaced by SetPermission');
END;

-- boolean
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to SetCapabilityPermission should be replaced by SetPermission');
END;

--specific
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to SetCapabilityPermission should be replaced by SetPermission');
END;

--specific
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'All calls to SetCapabilityPermission should be replaced by SetPermission');
END;

/******************************************
	SetPermission
******************************************/
-- boolean
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
)
AS
BEGIN
	SetPermission(in_company_type, NULL, NULL, in_group, in_capability, in_state);
END;

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
)
AS
	v_state					security_pkg.T_PERMISSION DEFAULT CASE WHEN in_state THEN BOOLEAN_PERM_SET ELSE 0 END;
BEGIN
	SetPermission(in_primary_company_type, in_secondary_company_type, NULL, in_group, in_capability, in_state);
END;

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
)
AS
	v_state					security_pkg.T_PERMISSION DEFAULT CASE WHEN in_state THEN BOOLEAN_PERM_SET ELSE 0 END;
	v_capability_type		chain_pkg.T_CAPABILITY_TYPE DEFAULT ResolveCapabilityType(in_capability, in_secondary_company_type);
BEGIN
	SetPermission_(in_primary_company_type, in_secondary_company_type, in_tertiary_company_type, in_group, GetCapabilityId(v_capability_type, in_capability), v_state, chain_pkg.BOOLEAN_PERMISSION);
END;

-- boolean
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
)
AS
BEGIN
	SetPermission(in_company_type, NULL, NULL, in_group, in_capability_type, in_capability, in_state);
END;

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
)
AS
	v_state					security_pkg.T_PERMISSION DEFAULT CASE WHEN in_state THEN BOOLEAN_PERM_SET ELSE 0 END;
BEGIN
	SetPermission(in_primary_company_type, in_secondary_company_type, NULL, in_group, in_capability_type, in_capability, in_state);
END;

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE,
	in_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_state					security_pkg.T_PERMISSION DEFAULT CASE WHEN in_state THEN BOOLEAN_PERM_SET ELSE 0 END;
BEGIN
	SetPermission_(in_primary_company_type, in_secondary_company_type, in_tertiary_company_type, in_group, GetCapabilityId(in_capability_type, in_capability), v_state, chain_pkg.BOOLEAN_PERMISSION, in_role_sid);
END;

-- boolean
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE,
	in_role_name				IN  csr.role.name%TYPE
)
AS
	v_capability_type	chain_pkg.T_CAPABILITY_TYPE DEFAULT ResolveCapabilityType(in_capability, in_secondary_company_type);
BEGIN

	SetPermissionToRole (
		in_primary_company_type		=> in_primary_company_type,
		in_secondary_company_type	=> in_secondary_company_type,
		in_tertiary_company_type	=> in_tertiary_company_type,
		in_capability_type			=> v_capability_type, 
		in_capability				=> in_capability,
		in_state					=> in_state,
		in_role_name				=> in_role_name
	);
END;

-- boolean
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE,
	in_role_name				IN  csr.role.name%TYPE
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_role_sid		 	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups'), in_role_name);
BEGIN

	SetPermission(
		in_primary_company_type		=> in_primary_company_type, 
		in_secondary_company_type	=> in_secondary_company_type, 
		in_tertiary_company_type	=> in_tertiary_company_type, 
		in_group					=> NULL, 
		in_capability_type			=> in_capability_type, 
		in_capability				=> in_capability,
		in_state					=> in_state, 
		in_role_sid					=> v_role_sid
	);
END;

--specific
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetPermission(in_company_type, NULL, NULL, in_group, in_capability, in_permission_set);
END;

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetPermission(in_primary_company_type, in_secondary_company_type, NULL, in_group, in_capability, in_permission_set);
END;

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
	v_capability_type	chain_pkg.T_CAPABILITY_TYPE DEFAULT ResolveCapabilityType(in_capability, in_secondary_company_type);
BEGIN
	SetPermission_(in_primary_company_type, in_secondary_company_type, in_tertiary_company_type, in_group, GetCapabilityId(v_capability_type, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

--specific
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetPermission(in_company_type, NULL, NULL, in_group, in_capability_type, in_capability, in_permission_set);
END;

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetPermission(in_primary_company_type, in_secondary_company_type, NULL, in_group, in_capability_type, in_capability, in_permission_set);
END;

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetPermission_(in_primary_company_type, in_secondary_company_type, in_tertiary_company_type, in_group, GetCapabilityId(in_capability_type, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

--specific
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_role_name				IN  csr.role.name%TYPE
)
AS
	v_capability_type	chain_pkg.T_CAPABILITY_TYPE DEFAULT ResolveCapabilityType(in_capability, in_secondary_company_type);
BEGIN

	SetPermissionToRole (
		in_primary_company_type		=> in_primary_company_type,
		in_secondary_company_type	=> in_secondary_company_type,
		in_tertiary_company_type	=> in_tertiary_company_type,
		in_capability_type			=> v_capability_type, 
		in_capability				=> in_capability,
		in_permission_set			=> in_permission_set,
		in_role_name				=> in_role_name
	);
END;

--specific
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_role_name				IN  csr.role.name%TYPE
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_role_sid		 	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups'), in_role_name);
BEGIN
	SetPermission (
		in_primary_company_type		=> in_primary_company_type,
		in_secondary_company_type	=> in_secondary_company_type,
		in_tertiary_company_type	=> in_tertiary_company_type,
		in_group					=> NULL, 
		in_capability_id			=> capability_pkg.GetCapabilityId(in_capability_type, in_capability),
		in_permission_set			=> in_permission_set,
		in_expected_pt				=> chain_pkg.SPECIFIC_PERMISSION,
		in_role_sid					=> v_role_sid
	);
END;

PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%Type,	
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_id			IN  capability.capability_id%TYPE,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND NOT csr.csr_data_pkg.CheckCapability('Manage chain capabilities') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to Manage chain capabilities');
	END IF;
 
	SetPermissionNOSEC(
		in_primary_company_type			=>	in_primary_company_type,
		in_secondary_company_type		=>	in_secondary_company_type,
		in_tertiary_company_type		=>	in_tertiary_company_type,
		in_group						=>	in_group,
		in_capability_id				=>	in_capability_id,
		in_permission_set				=>  in_permission_set,
		in_expected_pt					=>	in_expected_pt,
		in_role_sid						=>	in_role_sid
	);
END;

/******************************************
	RefreshCompanyCapabilities
******************************************/
PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS	
BEGIN
	-- no longer needed
	NULL;
END;

PROCEDURE RefreshCompanyTypeCapabilities (
	in_company_type			IN  company_type.lookup_key%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RefreshCompanyTypeCapabilities can only be run as a CSR Super Admin or Bultin Admin');
	END IF;

	FOR r IN (
		SELECT company_type_id 
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = UPPER(NVL(in_company_type, lookup_key))
	) LOOP
		INSERT INTO company_type_capability
		(primary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM group_capability gc, capability c, company_type ct
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.company_type_id = r.company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.is_supplier = 0
		   AND (ct.company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT primary_company_type_id, primary_company_group_type_id, capability_id
				  FROM company_type_capability
		   );

		INSERT INTO company_type_capability
		(primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM group_capability gc, capability c, company_type_relationship ctr, company_type ct
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.app_sid = ctr.app_sid
		   AND ct.company_type_id = r.company_type_id
		   AND ct.company_type_id = ctr.primary_company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.is_supplier = 1
		   AND c.capability_type_id <> chain_pkg.CT_ON_BEHALF_OF
		   AND (ctr.primary_company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id
				  FROM company_type_capability
		   );

		INSERT INTO company_type_capability
		(primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.company_type_id, ctrs.secondary_company_type_id, ctrt.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM group_capability gc, capability c, company_type_relationship ctrs, company_type_relationship ctrt, company_type ct
		 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.app_sid = ctrs.app_sid
		   AND ct.app_sid = ctrt.app_sid
		   AND ct.company_type_id = r.company_type_id
		   AND ct.company_type_id = ctrs.primary_company_type_id
		   AND ctrs.secondary_company_type_id = ctrt.primary_company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.is_supplier = 1
		   AND c.capability_type_id = chain_pkg.CT_ON_BEHALF_OF
		   AND (ct.company_type_id, ctrs.secondary_company_type_id, ctrt.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id
				  FROM company_type_capability
		   );
		   
		RefreshChainAdminPermissionSet(r.company_type_id);
		
		LogTypeCapabilityChange (
			in_description		=> 'Company capabilities refreshed for company type "{0}"',
			in_param_1			=> company_type_pkg.GetCompanyTypeDescription(r.company_type_id),
			in_sub_object_id	=> r.company_type_id
		);
	END LOOP;
END;

/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/

-- boolean
PROCEDURE CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_capability) THEN
		out_result := 1;
	END IF;
END;

-- boolean
PROCEDURE CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_company_sid, in_capability) THEN
		out_result := 1;
	END IF;
END;

-- boolean
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_primary_company_sid, in_secondary_company_sid, in_capability) THEN
		out_result := 1;
	END IF;
END;

-- boolean
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_sid, in_capability) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_company_sid, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_primary_company_sid, in_secondary_company_sid, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapability(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_sid, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/

-- boolean
FUNCTION CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), NULL, NULL, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

-- boolean
FUNCTION CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) THEN
		RETURN INTERNALCheckCapability(in_company_sid, NULL, NULL, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	ELSE
		RETURN INTERNALCheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_sid, NULL, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	END IF;
END;

-- boolean
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(in_primary_company_sid, in_secondary_company_sid, NULL, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

-- boolean
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

-- specific
FUNCTION CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), NULL, NULL, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

-- specific
FUNCTION CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) THEN
		RETURN INTERNALCheckCapability(in_company_sid, NULL, NULL, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	ELSE 		
		RETURN INTERNALCheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_sid, NULL, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	END IF;
END;

-- specific
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(in_primary_company_sid, in_secondary_company_sid, NULL, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

-- specific
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN INTERNALCheckCapability(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

/************************************************************** 
		POTENTIAL CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- These are used to check if you have the specified capability against ANY related company type.
-- This is handy when you want to decide if you should show a button (e.g. invite supplier)

-- boolean
PROCEDURE CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckPotentialCapability(in_capability) THEN
		out_result := 1;
	END IF;
END;

-- boolean
PROCEDURE CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckPotentialCapability(in_company_sid, in_capability) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckPotentialCapability(in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

-- specific
PROCEDURE CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckPotentialCapability(in_company_sid, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

/************************************************************** 
		POTENTIAL CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
-- These are used to check if you have the specified capability against ANY related company type.
-- This is handy when you want to decide if you should show a button (e.g. invite supplier)

FUNCTION CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapByAnySupplierType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapByAnySupplierType(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapByAnySupplierType(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

FUNCTION CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapByAnySupplierType(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE (PLSQL COMPATIBLE)
**************************************************************/

-- boolean
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, NULL, in_capability);
END;

-- boolean
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

-- specific
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, NULL, in_capability, in_permission_set);
END;

-- specific
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE (C# COMPATIBLE)
**************************************************************/

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
	v_tertiary_company_type		company.company_type_id%TYPE;
BEGIN
	out_result := 0;
	IF CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, v_tertiary_company_type, in_capability) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
	v_tertiary_company_type		company.company_type_id%TYPE;
BEGIN
	out_result := 0;
	IF CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, v_tertiary_company_type, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

/************************************************************** 
		CHECK CAPABILITY BY TERTIARY TYPE (PLSQL COMPATIBLE)
**************************************************************/

-- boolean
FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

-- specific
FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

/************************************************************** 
		CHECK CAPABILITY BY TERTIARY TYPE (C# COMPATIBLE)
**************************************************************/

PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, in_permission_set) THEN
		out_result := 1;
	END IF;
END;

/* Check tertiary potential  boolean capability*/
FUNCTION CheckPotentialTertiaryCap(
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_check_as_tertiary_type	IN  NUMBER DEFAULT 0
)RETURN NUMBER
AS
	v_primary_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_supplier_company_type_id 		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
	v_has_perm						BOOLEAN;
	v_permissible_companies			security.T_SID_TABLE;
BEGIN
	IF in_check_as_tertiary_type = 0 THEN
		FOR r IN(
			SELECT tertiary_company_type_id
			  FROM tertiary_relationships
			 WHERE primary_company_type_id = v_primary_company_type_id
			   AND secondary_company_type_id = v_supplier_company_type_id
		)
		LOOP
			--this check flow permissions (against the secondary company) as well
			v_has_perm := CheckCapabilityByTertiaryType(
					in_primary_company_sid 	=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
					in_secondary_company_sid => in_supplier_company_sid,
					in_tertiary_company_type => r.tertiary_company_type_id,
					in_capability => in_capability
				);			
			IF v_has_perm THEN
				RETURN 1;
			END IF;
			
		END LOOP;
	ELSE
		FOR r IN(
			SELECT secondary_company_type_id
			  FROM tertiary_relationships
			 WHERE primary_company_type_id = v_primary_company_type_id
			   AND tertiary_company_type_id = v_supplier_company_type_id --in that case we check against tertiary
		)
		LOOP
			--we only care about the permissible secondary_companies when v_supplier_company_type_id is the tertiary
			v_permissible_companies := GetPermCompanySidsByTypes(
				in_capability=> in_capability,
				in_secondary_company_type_id=> r.secondary_company_type_id,
				in_tertiary_company_type_id	=> v_supplier_company_type_id --tertiary in that case
			);

			IF v_permissible_companies.count > 0 THEN
				RETURN 1;
			END IF;
			
		END LOOP;
	END IF;

	RETURN 0;
END;

/************************************************************** 
		DELETE
**************************************************************/

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		DeleteCapability(chain_pkg.CT_COMPANY, in_capability);
		DeleteCapability(chain_pkg.CT_SUPPLIERS, in_capability);
		RETURN;
	END IF;
	
	DELETE FROM applied_company_capability
	 WHERE group_capability_id IN (
		SELECT group_capability_id
		  FROM group_capability
		 WHERE capability_id IN (
			SELECT capability_id
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type));
			   
	DELETE FROM group_capability_override
	 WHERE group_capability_id IN (
		SELECT group_capability_id
		  FROM group_capability
		 WHERE capability_id IN (
			SELECT capability_id
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type));
			      
	DELETE FROM group_capability
	 WHERE capability_id IN (
		SELECT capability_id
		  FROM capability
		 WHERE capability_name LIKE in_capability
		   AND capability_type_id = in_capability_type);
		   
	DELETE FROM company_type_capability
	 WHERE capability_id IN (
		SELECT capability_id
		  FROM capability
		 WHERE capability_name LIKE in_capability
		   AND capability_type_id = in_capability_type);
		   
	UPDATE card_group_card
	   SET required_capability_id = NULL
	 WHERE required_capability_id IN (
		SELECT capability_id
		  FROM capability
		 WHERE capability_name LIKE in_capability
		   AND capability_type_id = in_capability_type);
		   
	DELETE FROM capability
	 WHERE capability_name LIKE in_capability
	   AND capability_type_id = in_capability_type;
END;

/************************************************************** 
		UTILITIES
**************************************************************/

PROCEDURE EnableSite
AS
	v_dummy_cur		security_pkg.T_OUTPUT_CUR;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'EnableSite can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE customer_options 
	   SET use_type_capabilities = 1 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	LinkCapability(chain_pkg.COMPANYorSUPPLIER, 0, v_dummy_cur);
END;

PROCEDURE GetSiteMatrix (
	out_company_types						OUT security_pkg.T_OUTPUT_CUR,
	out_company_type_relationships	OUT security_pkg.T_OUTPUT_CUR,
	out_on_behalf_of_relationships		OUT security_pkg.T_OUTPUT_CUR,
	out_group_types							OUT security_pkg.T_OUTPUT_CUR,
	out_company_type_roles							OUT security_pkg.T_OUTPUT_CUR,
	out_capabilities								OUT security_pkg.T_OUTPUT_CUR,
	out_matrix										OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage chain capabilities') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to Manage chain capabilities');
	END IF;
	
	OPEN out_company_types FOR
		SELECT company_type_id, lookup_key, singular, plural, allow_lower_case, is_default, 
		       is_top_company, use_user_role, default_region_type, css_class, 
			   CASE WHEN region_root_sid IS NOT NULL THEN 
					SUBSTR(security.securableobject_pkg.getPathFromSid(security_pkg.getAct, region_root_sid), 
							LENGTH(security.securableobject_pkg.getPathFromSid(security_pkg.getAct, csr.region_tree_pkg.GetPrimaryRegionTreeRootSid))+ 1
						) 
				ELSE NULL END region_root_path,
			   default_region_layout, create_subsids_under_parent, create_doc_library_folder
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY position;
	
	OPEN out_company_type_relationships FOR
		SELECT ctr.primary_company_type_id, ctr.secondary_company_type_id, use_user_roles
		  FROM company_type_relationship ctr, company_type p, company_type s
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctr.app_sid = p.app_sid
		   AND ctr.app_sid = s.app_sid
		   AND ctr.primary_company_type_id = p.company_type_id
		   AND ctr.secondary_company_type_id = s.company_type_id
		 ORDER BY p.position, s.position;
	
	OPEN out_on_behalf_of_relationships FOR
		SELECT primary_company_type_id, secondary_company_type_id, tertiary_company_type_id
		  FROM tertiary_relationships tr, company_type ct1, company_type ct2, company_type ct3
         WHERE tr.primary_company_type_id = ct1.company_type_id
           AND tr.secondary_company_type_id = ct2.company_type_id
           AND tr.tertiary_company_type_id = ct3.company_type_id
         ORDER BY ct1.position, ct2.position, ct3.position;
         
         
	OPEN out_group_types FOR
		SELECT company_group_type_id, name, is_global
		  FROM (
			SELECT company_group_type_id, name, is_global,
			       CASE WHEN name = 'Administrators' THEN 0
			       		WHEN name = 'Users' THEN 1
			       		ELSE 2 END list_order
			  FROM company_group_type
			 WHERE is_global = 0
			)
		 ORDER BY list_order, is_global, LOWER(name);
	
	OPEN out_company_type_roles FOR
		SELECT ctr.company_type_id, ctr.pos, ctr.role_sid, r.name role_name, ctr.mandatory, ctr.cascade_to_supplier
		  FROM company_type_role ctr
		  JOIN csr.role r ON ctr.role_sid = r.role_sid
		 WHERE ctr.app_sid = security_pkg.GetApp
		 ORDER BY ctr.pos;
		
	OPEN out_capabilities FOR
		SELECT capability_id, capability_name, perm_type, capability_type_id, is_supplier
		  FROM (
			SELECT capability_id, capability_name, perm_type, capability_type_id, is_supplier,
					CASE WHEN capability_name = chain_pkg.COMPANY THEN 1
						 WHEN capability_name = chain_pkg.SUPPLIERS THEN 3
						 WHEN capability_type_id = 0 THEN 0
						 WHEN capability_type_id = 1 THEN 2
						 WHEN capability_type_id = 2 THEN 4
						 WHEN capability_type_id = 3 THEN 5
					END list_order
			  FROM capability
			 )
		 ORDER BY is_supplier, list_order, LOWER(capability_name);
	
	GetPermissionMatrix(out_matrix);
END;

PROCEDURE GetPermissionMatrix (
	out_matrix						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage chain capabilities') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to Manage chain capabilities');
	END IF;
	
	OPEN out_matrix FOR
		SELECT primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, primary_company_group_type_id, capability_id, permission_set, primary_company_type_role_sid
		  FROM company_type_capability
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY primary_company_type_id, secondary_company_type_id, tertiary_company_type_id, capability_id, primary_company_group_type_id;

END;

PROCEDURE GetPermissionMatrixByTypes (
	in_capability_ids				IN security_pkg.T_SID_IDS,
	in_primary_company_type_id		IN company_type_capability.primary_company_type_id%TYPE,
	in_secondary_company_type_id	IN company_type_capability.secondary_company_type_id%TYPE,
	in_tertiary_company_type_id		IN company_type_capability.tertiary_company_type_id%TYPE,
	out_matrix						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_capability_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_capability_ids);
	v_matrix						T_PERMISSION_MATRIX_TABLE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage chain capabilities') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to manage chain capabilities');
	END IF;

	SELECT T_PERMISSION_MATRIX_ROW(c.column_value, t.primary_company_group_type_id, t.primary_company_type_role_sid)
	  BULK COLLECT into v_matrix
	  FROM TABLE(v_capability_ids) c
	  CROSS JOIN (
			SELECT company_group_type_id primary_company_group_type_id, NULL primary_company_type_role_sid
			  FROM company_group_type
			 WHERE is_global = 0
			 UNION
			SELECT NULL primary_company_group_type_id, role_sid primary_company_type_role_sid
			  FROM company_type_role
			 WHERE company_type_id = in_primary_company_type_id
	  ) t;
	
	IF NVL(in_tertiary_company_type_id, 0) != 0 THEN
		OPEN out_matrix FOR
			SELECT in_primary_company_type_id primary_company_type_id,
				   in_secondary_company_type_id secondary_company_type_id,
				   in_tertiary_company_type_id tertiary_company_type_id,
				   m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid,
				   CASE WHEN MAX(NVL(ctc.permission_set, 0)) = MIN(NVL(ctc.permission_set, 0)) 
						THEN MAX(NVL(ctc.permission_set, 0)) ELSE -1 END permission_set
			  FROM tertiary_relationships tr
			  CROSS JOIN TABLE(v_matrix) m
			  LEFT JOIN company_type_capability ctc
					 ON ctc.capability_id = m.capability_id
					AND NVL(ctc.primary_company_group_type_id, 0) = NVL(m.primary_company_group_type_id, 0)
					AND NVL(ctc.primary_company_type_role_sid, 0) = NVL(m.primary_company_type_role_sid, 0)
					AND ctc.primary_company_type_id = tr.primary_company_type_id
					AND ctc.secondary_company_type_id = tr.secondary_company_type_id
					AND ctc.tertiary_company_type_id = tr.tertiary_company_type_id
			 WHERE (in_primary_company_type_id = -1 OR in_primary_company_type_id = tr.primary_company_type_id)
			   AND (in_secondary_company_type_id = -1 OR in_secondary_company_type_id = tr.secondary_company_type_id)
			   AND (in_tertiary_company_type_id = -1 OR in_tertiary_company_type_id = tr.tertiary_company_type_id)
		  GROUP BY m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid;
	ELSIF NVL(in_secondary_company_type_id, 0) != 0 THEN
		OPEN out_matrix FOR
			SELECT in_primary_company_type_id primary_company_type_id,
				   in_secondary_company_type_id secondary_company_type_id,
				   NULL tertiary_company_type_id,
				   m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid,
				   CASE WHEN MAX(NVL(ctc.permission_set, 0)) = MIN(NVL(ctc.permission_set, 0))
						THEN MAX(NVL(ctc.permission_set, 0)) ELSE -1 END permission_set
			  FROM company_type_relationship ctr
			 CROSS JOIN TABLE(v_matrix) m
			  LEFT JOIN company_type_capability ctc
					 ON ctc.capability_id = m.capability_id
					AND NVL(ctc.primary_company_group_type_id, 0) = NVL(m.primary_company_group_type_id, 0)
					AND NVL(ctc.primary_company_type_role_sid, 0) = NVL(m.primary_company_type_role_sid, 0)
					AND ctc.primary_company_type_id = ctr.primary_company_type_id
					AND ctc.secondary_company_type_id = ctr.secondary_company_type_id
					AND ctc.tertiary_company_type_id IS NULL
			 WHERE (in_primary_company_type_id = -1 OR in_primary_company_type_id = ctr.primary_company_type_id)
			   AND (in_secondary_company_type_id = -1 OR in_secondary_company_type_id = ctr.secondary_company_type_id)
		  GROUP BY m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid;
	ELSE
		OPEN out_matrix FOR
			SELECT in_primary_company_type_id primary_company_type_id,
				   NULL secondary_company_type_id,
				   NULL tertiary_company_type_id,
				   m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid,
				   CASE WHEN MAX(NVL(ctc.permission_set, 0)) = MIN(NVL(ctc.permission_set, 0))
						THEN MAX(NVL(ctc.permission_set, 0)) ELSE -1 END permission_set
			  FROM company_type ct
			  CROSS JOIN TABLE(v_matrix) m
			  LEFT JOIN company_type_capability ctc 
					 ON ctc.capability_id = m.capability_id
					AND NVL(ctc.primary_company_group_type_id, 0) = NVL(m.primary_company_group_type_id, 0)
					AND NVL(ctc.primary_company_type_role_sid, 0) = NVL(m.primary_company_type_role_sid, 0)
					AND ctc.primary_company_type_id = ct.company_type_id
					AND ctc.secondary_company_type_id IS NULL
					AND ctc.tertiary_company_type_id IS NULL
			 WHERE (in_primary_company_type_id = -1 OR in_primary_company_type_id = ct.company_type_id)
		  GROUP BY m.capability_id, m.primary_company_group_type_id, m.primary_company_type_role_sid;
	END IF;
END;

/* (C# COMPATIBLE) */
PROCEDURE CheckNoRelationshipPermission(
	in_primary_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_permission_set		IN security_Pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckNoRelationshipPermission(in_primary_company_sid, in_supplier_company_sid, in_permission_set) THEN
		out_result :=1;
	END IF;
END; 

/* Checks the permission against no related supplier */
FUNCTION CheckNoRelationshipPermission(
	in_primary_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_permission_set		IN security_Pkg.T_PERMISSION
)RETURN BOOLEAN 
AS
	v_supplier_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
	v_capability					chain_pkg.T_CAPABILITY DEFAULT chain_pkg.SUPPLIER_NO_RELATIONSHIP;
BEGIN
	/* CheckCapabilityBySupplierType does not require a relationship*/
	RETURN type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, v_supplier_company_type_id, v_capability, in_permission_set);
	
END;

PROCEDURE GetUnlinkedCapabilities(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.capability_name, c.perm_type
		  FROM capability c
		  JOIN capability_type ct ON ct.capability_type_id = c.capability_type_id
		  LEFT JOIN capability_flow_capability cfc ON cfc.capability_id = c.capability_id
		 WHERE cfc.capability_id IS NULL
		   AND c.capability_name NOT IN (
				chain_pkg.IS_TOP_COMPANY,
				chain_pkg.CREATE_RELATIONSHIP, --no supplier relationship exists when the action happens
				chain_pkg.SEND_COMPANY_INVITE, 
				chain_pkg.SEND_QUESTIONNAIRE_INVITE,
				chain_pkg.CREATE_COMPANY_WITHOUT_INVIT,
				chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY,
				chain_pkg.SUPPLIER_NO_RELATIONSHIP,
				chain_pkg.SEND_INVITE_ON_BEHALF_OF, --we use the tertiary instead
				chain_pkg.SEND_QUEST_INV_TO_NEW_COMPANY, --not used
				chain_pkg.SEND_QUEST_INV_TO_EXIST_COMPAN, --not used
				chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB,
				chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS,
				chain_pkg.CREATE_USER_WITHOUT_INVITE, --we need to clear this anyway
				chain_pkg.CREATE_USER_WITH_INVITE --we need to clear this anyway
			)
		 GROUP BY c.capability_name, c.perm_type
		 ORDER BY c.capability_name;
END;

PROCEDURE LinkCapability(
	in_capability				IN	chain_pkg.T_CAPABILITY,
	in_default_permission_set	IN	csr.customer_flow_capability.default_permission_set%TYPE DEFAULT NULL,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_flow_capability_id		csr.customer_flow_capability.flow_capability_id%TYPE;
	v_description				csr.customer_flow_capability.description%TYPE;
	v_perm_type					csr.customer_flow_capability.perm_type%TYPE;
	v_capability_type_id		capability.capability_type_id%TYPE;
	v_is_system_managed			csr.customer_flow_capability.is_system_managed%TYPE DEFAULT 0;
BEGIN
	IF NOT (security.security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage customer flow capabilities');
	END IF;

	IF in_capability = chain_pkg.COMPANYorSUPPLIER THEN
		v_description := 'Chain: Company / Supplier';
		v_perm_type := chain_pkg.SPECIFIC_PERMISSION;
		v_is_system_managed := 1;
	ELSE
		v_description := 'Chain: ' || in_capability;
		SELECT perm_type
		  INTO v_perm_type
		  FROM capability
		 WHERE capability_name = in_capability
		 GROUP BY perm_type;
	END IF;

	BEGIN
		SELECT csr_cfc.flow_capability_id
		  INTO v_flow_capability_id
		  FROM csr.customer_flow_capability csr_cfc
		  JOIN capability_flow_capability ch_cfc ON ch_cfc.flow_capability_id = csr_cfc.flow_capability_id
		  JOIN capability cap ON cap.capability_id = ch_cfc.capability_id
		 WHERE (
				(cap.capability_name = in_capability AND in_capability != chain_pkg.COMPANYorSUPPLIER)
		     OR (in_capability = chain_pkg.COMPANYorSUPPLIER AND cap.capability_name IN (chain_pkg.COMPANY, chain_pkg.SUPPLIERS))
		 )
		 GROUP BY csr_cfc.flow_capability_id;
	EXCEPTION
		WHEN no_data_found THEN
			csr.flow_pkg.SaveCustomerFlowCapability(
				in_flow_capability_id		=> NULL,
				in_flow_alert_class			=> 'supplier',
				in_description				=> v_description,
				in_perm_type				=> v_perm_type,
				in_default_permission_set	=> in_default_permission_set,
				in_is_system_managed		=> v_is_system_managed,
				out_flow_capability_id		=> v_flow_capability_id
			);
	END;

	INSERT INTO capability_flow_capability (capability_id, flow_capability_id)
		 SELECT cap.capability_id, v_flow_capability_id
		   FROM capability cap
		   LEFT JOIN capability_flow_capability ch_cfc ON ch_cfc.capability_id = cap.capability_id AND ch_cfc.flow_capability_id = v_flow_capability_id
		  WHERE (
				(cap.capability_name = in_capability AND in_capability != chain_pkg.COMPANYorSUPPLIER)
		     OR (in_capability = chain_pkg.COMPANYorSUPPLIER AND cap.capability_name IN (chain_pkg.COMPANY, chain_pkg.SUPPLIERS))
		  ) AND ch_cfc.capability_id IS NULL;
	
	OPEN out_cur FOR
		SELECT flow_capability_id, description, perm_type
		  FROM csr.customer_flow_capability
		 WHERE flow_capability_id = v_flow_capability_id;
END;

FUNCTION GetCapableCompanyTypeIds(
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_reversed_capability			IN	chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_type_id			security_pkg.T_SID_ID := company_type_pkg.GetCompanyTypeId(v_company_sid);
	v_forward_types				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, in_capability);
	v_reverse_types				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, in_reversed_capability);
	v_company_type_ids			security.T_SID_TABLE;
BEGIN

	SELECT ct.company_type_id
	  BULK COLLECT INTO v_company_type_ids
	  FROM company_type ct
	  LEFT JOIN TABLE(v_forward_types) t_self ON t_self.primary_company_type_id = ct.company_type_id
											 AND t_self.primary_company_type_id = v_company_type_id
											 AND t_self.secondary_company_type_id IS NULL
	  LEFT JOIN TABLE(v_forward_types) t_supp ON t_supp.primary_company_type_id = v_company_type_id
											 AND t_supp.secondary_company_type_id = ct.company_type_id
	  LEFT JOIN TABLE(v_reverse_types) t_purc ON t_purc.primary_company_type_id = ct.company_type_id
											 AND t_purc.secondary_company_type_id = v_company_type_id
	  WHERE t_self.capability_id IS NOT NULL
		 OR t_supp.capability_id IS NOT NULL
		 OR t_purc.capability_id IS NOT NULL
	  GROUP BY ct.company_type_id;

	RETURN v_company_type_ids;
END;

FUNCTION GetCapableCompanySids(
	in_company_sids					IN	security.T_SID_TABLE,
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_reversed_capability			IN	chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE
AS
	v_forward_company_sids		security.T_SID_TABLE;
	v_reverse_company_sids		security.T_SID_TABLE;
	v_tmp_company_sids			security.T_SID_TABLE;
	v_capable_company_sids		security.T_SID_TABLE;
BEGIN
	
	IF in_company_sids IS NOT NULL THEN		
		v_forward_company_sids	:= type_capability_pkg.FilterPermissibleCompanySids(in_company_sids, in_capability);
		v_reverse_company_sids	:= type_capability_pkg.FilterPermissibleCompanySids(in_company_sids, in_reversed_capability);
	ELSE	
		v_forward_company_sids	:= type_capability_pkg.GetPermissibleCompanySids(in_capability);
		v_reverse_company_sids	:= type_capability_pkg.GetPermissibleCompanySids(in_reversed_capability);
	END IF;
	
	SELECT company_sid
	  BULK COLLECT INTO v_tmp_company_sids
	  FROM (
		SELECT company_sid FROM (SELECT column_value company_sid FROM TABLE(v_forward_company_sids) order by company_sid)
		 UNION
		SELECT company_sid FROM (SELECT column_value company_sid FROM TABLE(v_reverse_company_sids) order by company_sid ) 
	);
	
	IF (in_company_sids IS NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') MEMBER OF in_company_sids) AND type_capability_pkg.CheckCapability(in_capability) THEN
		v_tmp_company_sids.extend;
		v_tmp_company_sids(v_tmp_company_sids.COUNT) := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;
	
	SELECT c.company_sid
	  BULK COLLECT INTO v_capable_company_sids
	  FROM company c
	  JOIN (SELECT column_value FROM TABLE (v_tmp_company_sids) order by column_value) ct ON ct.column_value = c.company_sid
	 WHERE c.deleted = 0
	   AND c.pending = 0;
	 
	RETURN v_capable_company_sids;
END;

END type_capability_pkg;
/
