CREATE OR REPLACE PACKAGE BODY CHAIN.capability_pkg
IS

BOOLEAN_PERM_SET				CONSTANT security_Pkg.T_PERMISSION := security_pkg.PERMISSION_WRITE;

/************************************************************** 
			PRIVATE UTILITY METHODS 
**************************************************************/
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

-- Returns a theoretical path for a capability (i.e. - no input validatation)
FUNCTION GetCapabilityPath (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN VARCHAR2
AS
	v_path				capability_type.container%TYPE;
BEGIN	
	SELECT CASE WHEN container IS NULL THEN NULL ELSE container || '/' END CASE
	  INTO v_path
	  FROM capability_type
	 WHERE capability_type_id = in_capability_type;
	
	RETURN chain_pkg.CAPABILITIES||'/'||v_path||in_capability;
END;

FUNCTION GetCapabilityPath (
	in_capability_id			IN  capability.capability_id%TYPE
) RETURN VARCHAR2
AS
	v_capability_type		chain_pkg.T_CAPABILITY_TYPE;
	v_capability			chain_pkg.T_CAPABILITY;
BEGIN	
	SELECT capability_type_id, capability_name
	  INTO v_capability_type, v_capability
	  FROM capability
	 WHERE capability_id = in_capability_id;
	
	RETURN GetCapabilityPath(v_capability_type, v_capability);
END;

/************************************************************** 
			PRIVATE WORKER METHODS 
**************************************************************/
FUNCTION CheckCapabilityById (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_capability_sid		security_pkg.T_SID_ID;
BEGIN
	
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;

	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session');	
	END IF;

	-- check that we're checking the correct permission type for the capability
	CheckPermType(in_capability_id, in_expected_pt);
	
	BEGIN
		v_capability_sid := securableobject_pkg.GetSidFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), GetCapabilityPath(in_capability_id));
	EXCEPTION 
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN FALSE; -- TODO: Lookup default from capability table?
	END;
	
	RETURN security_pkg.IsAccessAllowedSID(v_act_id, v_capability_sid, in_permission_set);
END;

FUNCTION CheckCapabilityByName (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_capability			chain_pkg.T_CAPABILITY DEFAULT in_capability;
	v_capability_id			capability.capability_id%TYPE;
	v_capability_type_id	capability_type.capability_type_id%TYPE;
	v_can_see_all_companies	company.can_see_all_companies%TYPE;
BEGIN
	IF helper_pkg.IsElevatedAccount THEN
		RETURN TRUE;
	END IF;
	
	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session - '||security_pkg.GetSid);	
	END IF;
	
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF in_capability = chain_pkg.COMPANYorSUPPLIER THEN
		IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
			v_capability := chain_pkg.COMPANY;
		ELSE 
			v_capability := chain_pkg.SUPPLIERS;
		END IF;
	END IF;
	
	SELECT c.capability_id, c.capability_type_id
	  INTO v_capability_id, v_capability_type_id
	  FROM capability c, capability_type ct
	 WHERE c.capability_type_id = ct.capability_type_id
	   AND c.capability_name = v_capability
	   AND ((
				-- the capability is a company based one, and we're looking at our own company
				c.capability_type_id = chain_pkg.CT_COMPANY AND v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			) OR (
				-- the capability is a company based one, and we're looking at a supplier
				c.capability_type_id = chain_pkg.CT_SUPPLIERS AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			) OR (
				c.capability_type_id = chain_pkg.CT_COMMON
		    ) OR (
				c.capability_type_id = chain_pkg.CT_ON_BEHALF_OF
		   ));

	IF v_capability_type_id = chain_pkg.CT_ON_BEHALF_OF THEN
		-- traditional capabilities never support on behalf of functionality
		RETURN FALSE;
	END IF;

	-- blow up if we're trying to check common capabilities of another company
	  IF v_capability_type_id = chain_pkg.CT_COMMON 
	 AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	 AND v_capability <> chain_pkg.COMPANY
	 AND v_capability <> chain_pkg.SUPPLIERS
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check common capabilities of a company that is not the company set in session');
	END IF;
	
	-- if we're checking a supplier company, ensure that they're actually a supplier
	  IF (v_capability_type_id = chain_pkg.CT_SUPPLIERS OR v_capability = chain_pkg.SUPPLIERS) 
	 AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	 AND NOT company_pkg.IsSupplier(v_company_sid) 
	 AND NVL(v_can_see_all_companies, 0) != 1
	THEN
		RETURN FALSE;
	END IF;
	
	RETURN CheckCapabilityById(in_company_sid, v_capability_id, in_permission_set, in_expected_pt);
END;

PROCEDURE SetCapabilityPermission_ (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_id		IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_gc_id					group_capability.group_capability_id%TYPE;
	v_capability_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, GetCapabilityPath(in_capability_id));
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, in_group);
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.GetApp, 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
BEGIN

	CheckPermType(in_capability_id, in_expected_pt);
	
	-- This is a set permission operation, not an add, so remove any existing ACEs for the group in question
	acl_pkg.RemoveACEsForSid(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(v_capability_sid),
		v_group_sid
	);
	
	-- add the requested permission
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(v_capability_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0, 
		v_group_sid, 
		in_permission_set
	);
	
	-- we want chain admins to mirror all other permissions so that they get a complete view of the system configuration, 
	-- but not one that is beyond the scope of the intended configuration
	-- TODO: This ought to clean up after itself when called multiple times, remove the old ACE and combine with the new ACE
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(v_capability_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0, 
		v_chain_admins_sid, 
		in_permission_set
	);
	
	
	GetGroupCapabilityId(in_capability_id, in_group, v_gc_id);
	
	BEGIN
		INSERT INTO APPLIED_COMPANY_CAPABILITY
		(company_sid, group_capability_id, permission_set)
		VALUES
		(in_company_sid, v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
END;

PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GrantCapability can only be run as BuiltIn/Administrator');
	END IF;

	CheckPermType(in_capability_type, in_capability, in_expected_pt);
	
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	UPDATE group_capability
	   SET permission_set = in_permission_set
	 WHERE group_capability_id = v_gc_id;
END;

PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION	
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	CheckPermType(in_capability_type, in_capability, in_expected_pt);

	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, permission_set_override)
        VALUES
        (v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_override
			   SET	permission_set_override = in_permission_set
			 WHERE group_capability_id = v_gc_id;
	END;
END;

PROCEDURE SetCapabilityHidden (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_hide					IN  BOOLEAN
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
	v_state					group_capability_override.hide_group_capability%TYPE;
	v_perm_set_override		group_capability_override.permission_set_override%TYPE;
BEGIN
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
		SELECT permission_set_override
		  INTO v_perm_set_override
		  FROM group_capability_override
		 WHERE group_capability_id = v_gc_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_perm_set_override := NULL;
	END;
	
	IF NOT in_hide AND v_perm_set_override IS NULL THEN
		-- just delete the entry
		DELETE FROM group_capability_override
		 WHERE group_capability_id = v_gc_id;
		
		RETURN;
	END IF;
	
	IF in_hide THEN
		v_state := chain_pkg.ACTIVE;
	ELSE
		v_state := chain_pkg.INACTIVE;
	END IF;
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, hide_group_capability)
        VALUES
        (v_gc_id, v_state);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_override
			   SET hide_group_capability = v_state
			 WHERE group_capability_id = v_gc_id;
	END;
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckPermType(in_capability_id, in_expected_pt);
		RETURN;
	END IF;
	
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
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.GetCapabilityId(in_capability_type, in_capability);
	END IF;
	
	BEGIN
		SELECT capability_id
		  INTO v_cap_id
		  FROM capability
		 WHERE capability_type_id = in_capability_type
		   AND capability_name = in_capability;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability||') with type '''||in_capability_type||'''not found');
	END;
	
	RETURN v_cap_id;		
END;

-- this method is public so that it can be accessed by card_pkg
FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_capability_type			chain_pkg.T_CAPABILITY_TYPE;
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.IsCommonCapability(in_capability);
	END IF;

	SELECT MAX(capability_type_id) 
	  INTO v_capability_type
	  FROM capability
	 WHERE capability_name = in_capability;
	
	RETURN v_capability_type = chain_pkg.CT_COMMON;
END;

-- It is preferred that one of the standard check capability methods be used (i.e. not by name)
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityById(in_capability_id, in_permission_set);
	END IF;
	
	-- we've got this funny check in place to help card_pkg check it's required capabilities
	IF in_permission_set IS NULL THEN
		RETURN CheckCapabilityById(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability_id, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	ELSE
		RETURN CheckCapabilityById(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability_id, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.RegisterCapability(in_capability_type, in_capability, in_perm_type, in_is_supplier, in_description);
		RETURN;
	END IF;
	
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
	ELSIF in_capability_type = chain_pkg.CT_SUPPLIERS AND in_is_supplier <> chain_pkg.IS_SUPPLIER_CAPABILITY THEN
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
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN	
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.GrantCapability(in_capability, in_group);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		GrantCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	ELSE
		GrantCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
		GrantCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	END IF;
END;

-- boolean
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS	
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN	
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.GrantCapability(in_capability_type, in_capability, in_group);
		RETURN;
	END IF;
	
	GrantCapability(in_capability_type, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.GrantCapability(in_capability, in_group, in_permission_set);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		GrantCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	ELSE
		GrantCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
		GrantCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	END IF;
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.GrantCapability(in_capability_type, in_capability, in_group, in_permission_set);
		RETURN;
	END IF;
	
	GrantCapability(in_capability_type, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.HideCapability(in_capability, in_group);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		HideCapability(chain_pkg.CT_COMMON, in_capability, in_group);
	ELSE
		HideCapability(chain_pkg.CT_COMPANY, in_capability, in_group);
		HideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group);
	END IF;
END;

PROCEDURE HideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.HideCapability(in_capability_type, in_capability, in_group);
		RETURN;
	END IF;
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	SetCapabilityHidden(in_capability_type, in_capability, in_group, TRUE);
END;

PROCEDURE UnhideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.UnhideCapability(in_capability, in_group);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		UnhideCapability(chain_pkg.CT_COMMON, in_capability, in_group);
	ELSE
		UnhideCapability(chain_pkg.CT_COMPANY, in_capability, in_group);
		UnhideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group);
	END IF;
END;

PROCEDURE UnhideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.UnhideCapability(in_capability_type, in_capability, in_group);
		RETURN;
	END IF;
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'UnhideCapability can only be run as BuiltIn/Administrator');
	END IF;	

	SetCapabilityHidden(in_capability_type, in_capability, in_group, FALSE);
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.OverrideCapability(in_capability, in_group);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		OverrideCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	ELSE
		OverrideCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
		OverrideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	END IF;
END;

-- boolean
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.OverrideCapability(in_capability_type, in_capability, in_group);
		RETURN;
	END IF;
	
	OverrideCapability(in_capability_type, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
END;

--specific
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.OverrideCapability(in_capability, in_group, in_permission_set);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		OverrideCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	ELSE
		OverrideCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
		OverrideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	END IF;
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.OverrideCapability(in_capability_type, in_capability, in_group, in_permission_set);
		RETURN;
	END IF;
	
	OverrideCapability(in_capability_type, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.SetCapabilityPermission(in_company_sid, in_group, in_capability);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMMON, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	ELSE
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMPANY, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_SUPPLIERS, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	END IF;
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.SetCapabilityPermission(in_company_sid, in_group, in_capability_type, in_capability);
		RETURN;
	END IF;
	
	SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(in_capability_type, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.SetCapabilityPermission(in_company_sid, in_group, in_capability, in_permission_set);
		RETURN;
	END IF;
	
	IF IsCommonCapability(in_capability) THEN
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMMON, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	ELSE
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMPANY, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_SUPPLIERS, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	END IF;
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.SetCapabilityPermission(in_company_sid, in_group, in_capability_type, in_capability, in_permission_set);
		RETURN;
	END IF;
	
	SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(in_capability_type, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;




/******************************************
	RefreshCompanyCapabilities
******************************************/
PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS	
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_capability_sid		security_pkg.T_SID_ID;
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Everyone');
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.RefreshCompanyCapabilities(in_company_sid);
		RETURN;
	END IF;

	
	-- ensure that all capabilities have been created
	FOR r IN (
		SELECT *
		  FROM capability
		 WHERE capability_type_id <> chain_pkg.CT_ON_BEHALF_OF
		 ORDER BY capability_id
	) LOOP		
		BEGIN
			securableobject_pkg.CreateSO(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, GetCapabilityPath(r.capability_type_id, NULL)), security_pkg.SO_CONTAINER, r.capability_name, v_capability_sid);
			
			-- don't inherit dacls
			securableobject_pkg.SetFlags(v_act_id, v_capability_sid, 0);
			-- clean existing ACE's
			acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capability_sid));
			
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_capability_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				0, v_everyone_sid, security_pkg.PERMISSION_ADD_CONTENTS);	
		EXCEPTION 
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;	
	END LOOP;

	-- Apply any capability permissions that have not already been applied to the this company
	FOR r IN (
		SELECT gcp.*, c.perm_type, c.capability_type_id, c.capability_name
		  FROM v$group_capability_permission gcp, capability c
		 WHERE gcp.capability_id = c.capability_id
		   AND gcp.group_capability_id NOT IN (
				SELECT group_capability_id
				  FROM applied_company_capability
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND company_sid = in_company_sid
			)
	) LOOP		
		SetCapabilityPermission_(in_company_sid, r.company_group_name, r.capability_id, r.permission_set, r.perm_type);
	END LOOP;


END;


/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapability(in_capability, out_result);
		RETURN;
	END IF;
	
	out_result := 0;
	IF CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapability(in_company_sid, in_capability, out_result);
		RETURN;
	END IF;

	out_result := 0;
	IF CheckCapabilityByName(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapability(in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	out_result := 0;
	IF CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set, out_result) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapability(in_company_sid, in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	out_result := 0;
	IF CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION) THEN
		out_result := 1;
	END IF;
END;

/************************************************************** 
		POTENTIAL CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- These are provided for forward compatibility with type_capability_pkg

-- boolean
PROCEDURE CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckPotentialCapability(in_capability, out_result);
		RETURN;
	END IF;
	
	CheckCapability(in_capability, out_result);
END;

-- boolean
PROCEDURE CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckPotentialCapability(in_company_sid, in_capability, out_result);
		RETURN;
	END IF;
	
	CheckCapability(in_company_sid, in_capability, out_result);
END;

-- specific
PROCEDURE CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckPotentialCapability(in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	CheckCapability(in_capability, in_permission_set, out_result);
END;

-- specific
PROCEDURE CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckPotentialCapability(in_company_sid, in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	CheckCapability(in_company_sid, in_capability, in_permission_set, out_result);
END;



/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapability(in_capability);
	END IF;
	
	RETURN CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapability(in_company_sid, in_capability);
	END IF;
	
	RETURN CheckCapabilityByName(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapability(in_capability, in_permission_set);
	END IF;
	
	RETURN CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapability(in_company_sid, in_capability, in_permission_set);
	END IF;
	
	RETURN CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

/************************************************************** 
		POTENTIAL CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
-- These are provided for forward compatibility with type_capability_pkg

-- boolean
FUNCTION CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckPotentialCapability(in_capability);
	END IF;
	
	RETURN CheckCapability(in_capability);
END;

-- boolean
FUNCTION CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckPotentialCapability(in_company_sid, in_capability);
	END IF;
	
	RETURN CheckCapability(in_company_sid, in_capability);
END;

-- specific
FUNCTION CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckPotentialCapability(in_capability, in_permission_set);
	END IF;
	
	RETURN CheckCapability(in_capability, in_permission_set);
END;

-- specific
FUNCTION CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckPotentialCapability(in_company_sid, in_capability, in_permission_set);
	END IF;
	
	RETURN CheckCapability(in_company_sid, in_capability, in_permission_set);
END;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE
**************************************************************/

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_capability);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_capability, in_permission_set);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, in_permission_set);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_capability, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityBySupplierType(in_primary_company_sid, in_secondary_company_type, in_tertiary_company_type, in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

/************************************************************** 
		CHECK CAPABILITY BY TERTIARY TYPE
**************************************************************/

FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		RETURN type_capability_pkg.CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, in_permission_set);
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;


PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
)
AS
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
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
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.CheckCapabilityByTertiaryType(in_primary_company_sid, in_secondary_company_sid, in_tertiary_company_type, in_capability, in_permission_set, out_result);
		RETURN;
	END IF;
	
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

/**************************************************************/


PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	IF helper_pkg.UseTypeCapabilities THEN
		type_capability_pkg.DeleteCapability(in_capability_type, in_capability);
		RETURN;
	END IF;
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		DeleteCapability(chain_pkg.CT_COMPANY, in_capability);
		DeleteCapability(chain_pkg.CT_SUPPLIERS, in_capability);
		RETURN;
	END IF;
	
	FOR com IN (
		SELECT company_sid
		  FROM company
	) LOOP
		FOR cap IN (
			SELECT capability_type_id, capability_name
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type
		) LOOP
			BEGIN
				securableobject_pkg.DeleteSO(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, com.company_sid, GetCapabilityPath(cap.capability_type_id, cap.capability_name)));
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;
		END LOOP;
	END LOOP;
	
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


PROCEDURE GetCapabilities(
	out_curs	OUT security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_curs FOR
		SELECT perm_type, capability_id, capability_name, capability_type_id, capability_group_id, is_supplier, supplier_on_purchaser, description
		  FROM (
			SELECT capability_id, capability_name, perm_type, capability_type_id, capability_group_id, is_supplier, supplier_on_purchaser, description,
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
END;

PROCEDURE GetCapabilityGroups(
	out_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT capability_group_id, group_name, group_position, is_visible
		FROM capability_group
		WHERE is_visible = 1
		 ORDER BY group_position;
END;


END capability_pkg;
/
