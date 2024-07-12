define version=55
@update_header

CONNECT csr/csr@&_CONNECT_IDENTIFIER;
grant select on customer to chain with grant option;
CONNECT chain/chain@&_CONNECT_IDENTIFIER;

CREATE OR REPLACE VIEW v$chain_host AS
	SELECT c.app_sid, c.host, co.chain_implementation
	  FROM csr.customer c, customer_options co
	 WHERE c.app_sid = co.app_sid
;

grant select on v$chain_host to public;

CREATE OR REPLACE PACKAGE  capability_pkg
IS

/************************************************************************ 
			README
*************************************************************************
- Capabilities are described by types (COMMON, COMPANY, SUPPLIER).

- There are two virtual types as well (ROOT, COMPANIES)

- ROOT is (currently) effectively the same as COMMON, and can be used interchangably.

- COMPANIES is currently only used during capability registration, and effectively
	just splits the call into two calls, one for COMPANY and one for SUPPLIER, making
	it convenient for setting up the same capability under both containers.

- Grant, Hide, Override and SetPermission all have multiple declarations that
	allow you to either pass in the TYPE, or not - these are commented 
	as "auto type" or "type specified" in this header file.

- "auto type" means that the system will try to determine the type you're referring 
	to - for COMMON types, it's simple - for COMPANY or SUPPLIER types, the method
	will be run for BOTH, which may or may not be the intention.

- "type specified" allows you to be explict and control exactly which capability / type
	combination you want to
*/

/************************************************************** 
			SEMI-PRIVATE (PROTECTED) METHODS 
**************************************************************/
-- this method is public so that it can be accessed by card_pkg
PROCEDURE CheckPermType (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

-- this method is public so that it can be accessed by card_pkg
FUNCTION GetCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN capability.capability_id%TYPE;

FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- It is preferred that one of the standard check capability methods be used (i.e. by name)
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;


/************************************************************** 
		SETUP AND INITIALIZATION METHODS 
**************************************************************/
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

/******************************************
	GrantCapability
******************************************/
-- boolean, auto type
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

/******************************************
	HideCapability
******************************************/
-- auto type
PROCEDURE HideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE HideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

/******************************************
	OverrideCapability
******************************************/
-- boolean, auto type
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

/******************************************
	SetCapabilityPermission
******************************************/
-- boolean, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- specific, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
);



PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
);

/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- boolean
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- boolean
PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/

-- boolean
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;


/*************
For those of you who are master capability checkers, you may want to specify the type of 
capability that you're checking in your code. The advantage of this method of calling is
that you can check a users's permission on their company's supplier node without needing
to provide a supplier company sid (which must be a sid of an ACTIVE supplier)
*************
-- boolean
FUNCTION CheckCapabilityByType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapabilityByType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;
*/

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

END capability_pkg;
/

CREATE OR REPLACE PACKAGE BODY capability_pkg
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
		(group_capability_id, company_group_name, capability_id)
		VALUES
		(group_capability_id_seq.NEXTVAL, in_group, in_capability_id)
		RETURNING group_capability_id INTO out_gc_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT group_capability_id
			  INTO out_gc_id
			  FROM group_capability
			 WHERE company_group_name = in_group
			   AND capability_id = in_capability_id;
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
	  FROM v$capability
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
BEGIN
	IF chain_pkg.IsElevatedAccount THEN
		RETURN TRUE;
	END IF;
	
	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session - '||security_pkg.GetSid);	
	END IF;
	
	IF in_capability = chain_pkg.COMPANYorSUPPLIER THEN
		IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
			v_capability := chain_pkg.COMPANY;
		ELSE 
			v_capability := chain_pkg.SUPPLIERS;
		END IF;
	END IF;
	
	SELECT c.capability_id, c.capability_type_id
	  INTO v_capability_id, v_capability_type_id
	  FROM v$capability c, capability_type ct
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
		   ));

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
	
	BEGIN
		INSERT INTO group_capability_perm
		(group_capability_id, permission_set)
		VALUES
		(v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_perm
			   SET permission_set = in_permission_set
			 WHERE group_capability_id = v_gc_id;
	END;
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
		  FROM v$capability
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
		  FROM v$capability
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
	SELECT MAX(capability_type_id) 
	  INTO v_capability_type
	  FROM v$capability
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
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_count						NUMBER(10);
	v_ct						chain_pkg.T_CAPABILITY_TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		RegisterCapability(chain_pkg.CT_COMPANY, in_capability, in_perm_type);
		RegisterCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_perm_type);
		RETURN;	
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND (
	   			(capability_type_id = chain_pkg.CT_COMMON AND (in_capability_type = chain_pkg.CT_COMPANY OR in_capability_type = chain_pkg.CT_SUPPLIERS))
	   		 OR (in_capability_type = chain_pkg.CT_COMMON AND (capability_type_id = chain_pkg.CT_COMPANY OR capability_type_id = chain_pkg.CT_SUPPLIERS))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type) 
	VALUES 
	(capability_id_seq.nextval, in_capability, in_capability_type, in_perm_type);

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
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, hide_group_capability)
        VALUES
        (v_gc_id, chain_pkg.ACTIVE);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE group_capability_override
			   SET	hide_group_capability=chain_pkg.ACTIVE
			 WHERE group_capability_id=v_gc_id;
	END;
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
	
	-- ensure that all capabilities have been created
	FOR r IN (
		SELECT *
		  FROM v$capability
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
		  FROM v$group_capability_permission gcp, v$capability c
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
	out_result := 0;
	IF CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION) THEN
		out_result := 1;
	END IF;
END;



/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
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
			   
	DELETE FROM group_capability_perm
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

END capability_pkg;
/

CREATE OR REPLACE PACKAGE  chain_pkg
IS

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;

-- a general use code
UNDEFINED							CONSTANT NUMBER := 0;

SUBTYPE T_ACTIVE					IS NUMBER;
ACTIVE 								CONSTANT T_ACTIVE := 1;
INACTIVE 							CONSTANT T_ACTIVE := 0;

SUBTYPE T_GROUP						IS VARCHAR2(100);
ADMIN_GROUP							CONSTANT T_GROUP := 'Administrators';
USER_GROUP							CONSTANT T_GROUP := 'Users';
PENDING_GROUP						CONSTANT T_GROUP := 'Pending Users';
CHAIN_ADMIN_GROUP					CONSTANT T_GROUP := 'Chain '||ADMIN_GROUP;
CHAIN_USER_GROUP					CONSTANT T_GROUP := 'Chain '||USER_GROUP;

SUBTYPE T_CAPABILITY_PERM_TYPE		IS NUMBER(10);
SPECIFIC_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 0;
BOOLEAN_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 1;

SUBTYPE T_CAPABILITY_TYPE			IS NUMBER(10);
CT_ROOT								CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMMON							CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMPANY							CONSTANT T_CAPABILITY_TYPE := 1; 
CT_SUPPLIERS						CONSTANT T_CAPABILITY_TYPE := 2; 
CT_COMPANIES						CONSTANT T_CAPABILITY_TYPE := 3; -- both the CT_COMPANY and CT_SUPPLIERS nodes

/****************************************************************************************************/
SUBTYPE T_CAPABILITY				IS VARCHAR2(100);

-- treated as a either a COMPANY or SUPPLIER capability check depending on sid 
-- that is passed in with it compared with the company sid set in session
COMPANYorSUPPLIER					CONSTANT T_CAPABILITY := 'VIRTUAL.COMPANYorSUPPLIER';

/**** Root capabilities ****/
CAPABILITIES						CONSTANT T_CAPABILITY := 'Capabilities';
COMPANY								CONSTANT T_CAPABILITY := 'Company';
SUPPLIERS							CONSTANT T_CAPABILITY := 'Suppliers';

/**** Company/Suppliers nodes capabilities ****/
SPECIFY_USER_NAME					CONSTANT T_CAPABILITY := 'Specify user name';
QUESTIONNAIRE						CONSTANT T_CAPABILITY := 'Questionnaire';
SUBMIT_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Submit questionnaire';
SETUP_STUB_REGISTRATION				CONSTANT T_CAPABILITY := 'Setup stub registration';
RESET_PASSWORD						CONSTANT T_CAPABILITY := 'Reset password';
CREATE_USER							CONSTANT T_CAPABILITY := 'Create user';
EVENTS								CONSTANT T_CAPABILITY := 'Events';
ACTIONS								CONSTANT T_CAPABILITY := 'Actions';
TASKS								CONSTANT T_CAPABILITY := 'Tasks';
METRICS								CONSTANT T_CAPABILITY := 'Metrics';
PRODUCTS							CONSTANT T_CAPABILITY := 'Products';
COMPONENTS							CONSTANT T_CAPABILITY := 'Components';
PROMOTE_USER						CONSTANT T_CAPABILITY := 'Promote user';
PRODUCT_CODE_TYPES					CONSTANT T_CAPABILITY := 'Product code types';

/**** Common capabilities ****/
IS_TOP_COMPANY						CONSTANT T_CAPABILITY := 'Is top company';
SEND_QUESTIONNAIRE_INVITE			CONSTANT T_CAPABILITY := 'Send questionnaire invitation';
SEND_NEWSFLASH						CONSTANT T_CAPABILITY := 'Send newsflash';
RECEIVE_USER_TARGETED_NEWS			CONSTANT T_CAPABILITY := 'Receive user-targeted newsflash';
APPROVE_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Approve questionnaire';

/****************************************************************************************************/

SUBTYPE T_VISIBILITY				IS NUMBER;
HIDDEN 								CONSTANT T_VISIBILITY := 0;
JOBTITLE 							CONSTANT T_VISIBILITY := 1;
NAMEJOBTITLE						CONSTANT T_VISIBILITY := 2;
FULL 								CONSTANT T_VISIBILITY := 3;

SUBTYPE T_REGISTRATION_STATUS		IS NUMBER;
PENDING								CONSTANT T_REGISTRATION_STATUS := 0;
REGISTERED 							CONSTANT T_REGISTRATION_STATUS := 1;
REJECTED							CONSTANT T_REGISTRATION_STATUS := 2;
MERGED								CONSTANT T_REGISTRATION_STATUS := 3;

SUBTYPE T_INVITATION_TYPE			IS NUMBER;
QUESTIONNAIRE_INVITATION			CONSTANT T_INVITATION_TYPE := 1;
STUB_INVITATION						CONSTANT T_INVITATION_TYPE := 2;

SUBTYPE T_INVITATION_STATUS			IS NUMBER;
-- ACTIVE = 1 (defined above)
EXPIRED								CONSTANT T_INVITATION_STATUS := 2;
CANCELLED							CONSTANT T_INVITATION_STATUS := 3;
PROVISIONALLY_ACCEPTED				CONSTANT T_INVITATION_STATUS := 4;
ACCEPTED							CONSTANT T_INVITATION_STATUS := 5;
REJECTED_NOT_EMPLOYEE				CONSTANT T_INVITATION_STATUS := 6;
REJECTED_NOT_SUPPLIER				CONSTANT T_INVITATION_STATUS := 7;

SUBTYPE T_GUID_STATE				IS NUMBER;
GUID_OK 							CONSTANT T_GUID_STATE := 0;
--GUID_INVALID						CONSTANT T_GUID_STATE := 1; -- probably only used in cs class
GUID_NOTFOUND						CONSTANT T_GUID_STATE := 2;
GUID_EXPIRED						CONSTANT T_GUID_STATE := 3;
GUID_ALREADY_USED					CONSTANT T_GUID_STATE := 4;

SUBTYPE T_ALERT_ENTRY_TYPE			IS NUMBER;
EVENT_ALERT							CONSTANT T_ALERT_ENTRY_TYPE := 1;
ACTION_ALERT						CONSTANT T_ALERT_ENTRY_TYPE := 2;

SUBTYPE T_ALERT_ENTRY_PARAM_TYPE	IS NUMBER;
ORDERED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 1;
NAMED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 2;

/****************************************************************************************************/

SUBTYPE T_SHARE_STATUS				IS NUMBER;
NOT_SHARED 							CONSTANT T_SHARE_STATUS := 11;
SHARING_DATA 						CONSTANT T_SHARE_STATUS := 12;
SHARED_DATA_RETURNED 				CONSTANT T_SHARE_STATUS := 13;
SHARED_DATA_ACCEPTED 				CONSTANT T_SHARE_STATUS := 14;
SHARED_DATA_REJECTED 				CONSTANT T_SHARE_STATUS := 15;

SUBTYPE T_QUESTIONNAIRE_STATUS		IS NUMBER;
ENTERING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 1;
REVIEWING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 2;
READY_TO_SHARE 						CONSTANT T_QUESTIONNAIRE_STATUS := 3;




ERR_QNR_NOT_FOUND	CONSTANT NUMBER := -20500;
QNR_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_FOUND, -20500);

ERR_QNR_ALREADY_EXISTS	CONSTANT NUMBER := -20501;
QNR_ALREADY_EXISTS EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_EXISTS, -20501);

ERR_QNR_NOT_SHARED CONSTANT NUMBER := -20502;
QNR_NOT_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_SHARED, -20502);

ERR_QNR_ALREADY_SHARED CONSTANT NUMBER := -20503;
QNR_ALREADY_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_SHARED, -20503);



PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
);

PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE;


PROCEDURE IsChainAdmin(
	out_result				OUT  NUMBER
);

FUNCTION IsChainAdmin
RETURN BOOLEAN;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

FUNCTION IsElevatedAccount
RETURN BOOLEAN;

FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID;

END chain_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain_pkg
IS

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO chain_user
		(user_sid, registration_status_id)
		VALUES
		(in_user_sid, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
)
AS
BEGIN
	-- NO SEC CHECKS - you can only set default settings for the user that you're logged in as in the current application
	
	BEGIN
		INSERT INTO user_setting
		(name, number_value, string_value)
		VALUES
		(LOWER(TRIM(in_name)), in_number_value, in_string_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting
			   SET number_value = in_number_value,
			   	   string_value = in_string_value
			 WHERE name = LOWER(TRIM(in_name))
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END;

END;

-- we need to pass in dummy because for some very very strange reason, we get an exception if we pass in a string array as the first param 
PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_t_names				security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_names);
BEGIN
	-- NO SEC CHECKS - you can only get default settings for the user that you're logged in as in the current application
	OPEN out_cur FOR
		SELECT name, number_value, string_value
		  FROM user_setting
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND name IN (SELECT LOWER(TRIM(value)) FROM TABLE(v_t_names));
END;


PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	INVITATION_EXPIRATION_DAYS,
				SITE_NAME,
				ADMIN_HAS_DEV_ACCESS,
				SUPPORT_EMAIL,
				NEWSFLASH_SUMMARY_SP,
				QUESTIONNAIRE_FILTER_CLASS,
				LAST_GENERATE_ALERT_DTM,
				SCHEDULED_ALERT_INTVL_MINUTES,
				CHAIN_IMPLEMENTATION,
				COMPANY_HELPER_SP,
				DEFAULT_RECEIVE_SCHED_ALERTS,
				OVERRIDE_SEND_QI_PATH,
				LOGIN_PAGE_MESSAGE,
				INVITE_FROM_NAME_ADDENDUM,
				SCHED_ALERTS_ENABLED,
				LINK_HOST,
				NVL(TOP_COMPANY_SID, 0) TOP_COMPANY_SID
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 				security_pkg.T_SID_ID;
BEGIN
	v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');
	RETURN v_sid_id;
END;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM v$country
		 ORDER BY LOWER(name);
END;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE
AS
BEGIN
	RETURN TO_DATE(in_str_val, 'DD/MM/YY HH24:MI:SS');
END;

PROCEDURE IsChainAdmin  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainAdmin THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainAdmin 
RETURN BOOLEAN
AS
BEGIN
	RETURN IsChainAdmin(security_pkg.GetSid);
END;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, in_user_sid)) T
		 WHERE T.sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;			 
	END IF;	
	
	RETURN FALSE;
END;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN in_sid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Chain/BuiltIn/Invitation Respondent');
END;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsInvitationRespondant(in_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

FUNCTION IsElevatedAccount
RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;
	
	IF IsInvitationRespondant(security_pkg.GetSid) THEN
		RETURN TRUE;
	END IF;
	
	IF security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon') THEN
		RETURN TRUE;
	END IF;
	
	RETURN FALSE;
END;

-- use with care!
-- just issues the ACT, i.e. doesn't stick it into SYS_CONTEXT
FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID
AS
	v_act		security_pkg.T_ACT_ID;
BEGIN
	-- we don't want to set the security context
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(security_pkg.SID_BUILTIN_ADMINISTRATOR, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	RETURN v_act;
END;

END chain_pkg;
/

DECLARE
	v_admins_sid		security_pkg.T_SID_ID;
	v_users_sid			security_pkg.T_SID_ID;
	v_chain_admins_sid	security_pkg.T_SID_ID;
	v_cap_sid			security_pkg.T_SID_ID;
	v_dacl_id			security_Pkg.T_ACL_ID;
	v_new_dacl_id		security_Pkg.T_ACL_ID;
	v_acl_index			security_Pkg.T_ACL_INDEX;
	v_act_id			security_pkg.T_ACT_ID;
	v_capabilities		T_STRING_LIST := T_STRING_LIST(chain_pkg.TASKS, chain_pkg.METRICS);	
BEGIN
	user_pkg.logonadmin;
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.TASKS, chain_pkg.SPECIFIC_PERMISSION);
  capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.TASKS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.TASKS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.METRICS, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.METRICS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.METRICS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	
	FOR r IN (
		SELECT host FROM v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		v_act_id := security_pkg.GetAct;
		v_chain_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/' || chain_pkg.CHAIN_ADMIN_GROUP);
		
		FOR c IN (
			SELECT company_sid FROM company
		) LOOP
			v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.company_sid, chain_pkg.ADMIN_GROUP);
			v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.company_sid, chain_pkg.USER_GROUP);
			
			FOR i IN v_capabilities.FIRST .. v_capabilities.LAST
			LOOP
				v_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.company_sid, chain_pkg.CAPABILITIES || '/' || chain_pkg.COMPANY || '/' || v_capabilities(i));
				v_dacl_id := acl_pkg.GetDACLIDForSID(v_cap_sid);
				v_acl_index := 1;
				
				security.ACL_Pkg.GetNewID(v_new_dacl_id);
				
				FOR acls IN (
					SELECT ace_type, ace_flags, sid_id, permission_set 
					  FROM (
							-- get acls that we're not replacing
							SELECT ace_type, ace_flags, sid_id, permission_set
							  FROM security.acl
							 WHERE acl_id = v_dacl_id
							   AND (acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set) NOT IN (
									-- get acls that we ARE replacing
									SELECT acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set
									  FROM security.acl
									 WHERE acl_id = v_dacl_id
									   AND sid_id IN (v_admins_sid, v_users_sid, v_chain_admins_sid)
									   AND ace_type = 1
									   AND ace_flags = 0
									   AND permission_set IN (security_pkg.PERMISSION_READ, security_pkg.PERMISSION_WRITE, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE)
								  )
							 ORDER BY acl_index
							)
					-- include new acls
					 UNION ALL
					SELECT 1 ace_type, 0 ace_flags, v_admins_sid sid_id, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE permission_set FROM DUAL
					 UNION ALL
					SELECT 1 ace_type, 0 ace_flags, v_users_sid sid_id, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE permission_set FROM DUAL
					 UNION ALL
					SELECT 1 ace_type, 0 ace_flags, v_chain_admins_sid sid_id, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE permission_set FROM DUAL
				) LOOP
					-- insert acls
					INSERT INTO security.acl 
					(acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set)
					VALUES 
					(v_new_dacl_id, v_acl_index, acls.ace_type, acls.ace_flags, acls.sid_id, acls.permission_set);

					v_acl_index := v_acl_index + 1;
				END LOOP;
				
				-- set the new dacl
				acl_pkg.SetDACL(v_act_id, v_cap_sid, v_new_dacl_id);
				
			END LOOP;		
		END LOOP;		
	END LOOP;
END;
/

@update_tail

