CREATE OR REPLACE PACKAGE  CHAIN.type_capability_pkg
IS

/************************************************************************ 
			README
*************************************************************************
- Capabilities are described by types (COMMON, COMPANY, SUPPLIER).

- There are two virtual types as well (ROOT, COMPANIES)

- ROOT is (currently) effectively the same as COMMON, and can be used interchangably.

- COMPANIES is currently only used during capabisetlity registration, and effectively
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
	in_capability_id			IN  capability.capability_id%TYPE,
	in_expected_pt				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

-- this method is public so that it can be accessed by card_pkg
FUNCTION GetCapabilityId (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN capability.capability_id%TYPE;

FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

FUNCTION IsOnBehalfOfCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- It is preferred that one of the standard check capability methods be used (i.e. by name)
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id			IN  capability.capability_id%TYPE,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID DEFAULT NULL
) RETURN BOOLEAN;


/************************************************************** 
		SETUP AND INITIALIZATION METHODS 
**************************************************************/
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_is_supplier				IN  chain_pkg.T_SUPPLIER_CENTRIC_CAPBILITY DEFAULT chain_pkg.INHERIT_IS_SUP_CAPABILITY,
	in_description				IN	capability.description%TYPE DEFAULT NULL
);

/******************************************
	GrantCapability
******************************************/
-- boolean, auto type
PROCEDURE GrantCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE GrantCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE GrantCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP,
	in_permission_set			IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE GrantCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP,
	in_permission_set			IN  security_Pkg.T_PERMISSION
);

/******************************************
	HideCapability
******************************************/
-- auto type
PROCEDURE HideCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE HideCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- auto type
PROCEDURE UnhideCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE UnhideCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);
/******************************************
	OverrideCapability
******************************************/
-- boolean, auto type
PROCEDURE OverrideCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE OverrideCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE OverrideCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP,
	in_permission_set			IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE OverrideCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_group					IN  chain_pkg.T_GROUP,
	in_permission_set			IN  security_Pkg.T_PERMISSION
);

/******************************************
	SetCapabilityPermission
******************************************/
-- boolean, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

-- boolean, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

-- specific, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);	

/******************************************
	SetPermission
******************************************/
-- boolean
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
);

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
);

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
);

-- boolean
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
);

-- boolean
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE, 
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE
);

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
);

-- boolean
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE,
	in_role_name				IN  csr.role.name%TYPE
);

-- boolean
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_state					IN  BOOLEAN DEFAULT TRUE,
	in_role_name				IN  csr.role.name%TYPE
);

--specific
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermission (
	in_company_type				IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION
);

--specific
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE DEFAULT NULL,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_role_name				IN  csr.role.name%TYPE
);

--specific
PROCEDURE SetPermissionToRole (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN  company_type.lookup_key%TYPE,
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	in_role_name				IN  csr.role.name%TYPE
);

-- public, very specific
Procedure SetPermission (
	in_primary_company_type		IN  company_type.lookup_key%TYPE,
	in_secondary_company_type	IN  company_type.lookup_key%Type,
	in_tertiary_company_type	IN  company_type.lookup_key%Type,
	in_group					IN  chain_pkg.T_GROUP,
	in_capability_id			IN  capability.capability_id%TYPE,
	in_permission_set    		IN  security_pkg.T_PERMISSION,
	in_expected_pt     			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL
);

-- public, based on IDs
PROCEDURE SetPermission (
	in_capability_id				IN  capability.capability_id%TYPE,
	in_primary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_secondary_company_type_id	IN  company_type.company_type_id%TYPE,
	in_tertiary_company_type_id		IN  company_type.company_type_id%TYPE,
	in_company_group_type_id		IN  company_group_type.company_group_type_id%TYPE,
	in_role_sid						IN  security_pkg.T_SID_ID,
	in_permission_set    			IN  security_pkg.T_PERMISSION
);

/******************************************
	RefreshCompanyCapabilities
******************************************/
PROCEDURE RefreshCompanyCapabilities (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE RefreshCompanyTypeCapabilities (
	in_company_type				IN  company_type.lookup_key%TYPE DEFAULT NULL
);

/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- boolean
PROCEDURE CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- boolean
PROCEDURE CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- boolean
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- boolean
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

/************************************************************** 
		POTENTIAL CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- These are used to check if you have the specified capabiilty against ANY related company type.
-- This is handy when you want to decide if you should show a button (e.g. invite supplier)

-- boolean
PROCEDURE CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- boolean
PROCEDURE CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

FUNCTION CheckPotentialTertiaryCap(
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_check_as_tertiary_type	IN  NUMBER DEFAULT 0
)RETURN NUMBER;


/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/

-- boolean
FUNCTION CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_sid		IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

/************************************************************** 
		POTENTIAL CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
-- These are used to check if you have the specified capabiilty against ANY related company type.
-- This is handy when you want to decide if you should show a button (e.g. invite supplier)

-- boolean
FUNCTION CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckPotentialCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckPotentialCapability (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE (PLSQL COMPATIBLE)
**************************************************************/

-- boolean
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE (C# COMPATIBLE)
**************************************************************/

-- boolean
PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- boolean
PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

/************************************************************** 
		CHECK CAPABILITY BY TERTIARY TYPE
**************************************************************/

-- boolean
FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- boolean
PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

-- specific
PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

--boolean
FUNCTION FilterPermissibleSidsByFlow(
	in_company_sids_t			IN security.T_SID_TABLE,
	in_capability				IN chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

--specific
FUNCTION FilterPermissibleSidsByFlow(
	in_company_sids_t			IN security.T_SID_TABLE,
	in_capability				IN chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

--boolean
FUNCTION IsCompanyPermissibleByFlow(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_capability				IN chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

--boolean
FUNCTION GetPermissibleCompanySids (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

-- specific
FUNCTION GetPermissibleCompanySids (
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

--boolean
FUNCTION GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN T_PERMISSIBLE_TYPES_TABLE;

--specific
FUNCTION GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN T_PERMISSIBLE_TYPES_TABLE;

--Boolean: Get permissible company types that satisfy at least one capability from the list
FUNCTION GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capabilities				IN  T_STRING_LIST
) RETURN T_PERMISSIBLE_TYPES_TABLE;

FUNCTION GetPermCompanySidsByTypes (
	in_capability					IN  chain_pkg.T_CAPABILITY,
	in_secondary_company_type_id	IN  company_type.company_type_id%TYPE DEFAULT NULL,
	in_tertiary_company_type_id		IN  company_type.company_type_id%TYPE DEFAULT NULL
)RETURN security.T_SID_TABLE;

FUNCTION FilterPermissibleCompanySids (
	in_company_sids_t			IN  security.T_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

--boolean perm
FUNCTION FilterPermissibleCompanySids (
	in_company_sids_t			IN  security.T_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

FUNCTION FilterPermissibleCompanySids (
	in_company_sid_page			IN  security.T_ORDERED_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

FUNCTION FilterPermissibleCompanySids (
	in_company_sid_filter		IN  T_FILTERED_OBJECT_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

--boolean perm
FUNCTION FilterPermissibleCompanySids (
	in_company_sid_page			IN  security.T_ORDERED_SID_TABLE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

/*-------------*/
--Wrappers for C#

PROCEDURE GetPermissibleCompanyTypes(
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_cur						OUT SYS_REFCURSOR
);

--boolean
PROCEDURE GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_cur						OUT SYS_REFCURSOR
);

--specific
PROCEDURE GetPermissibleCompanyTypes(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_pkg.T_PERMISSION,
	out_cur						OUT SYS_REFCURSOR
);
/*-------------*/

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

PROCEDURE EnableSite;

PROCEDURE GetSiteMatrix (
	out_company_types						OUT security_pkg.T_OUTPUT_CUR,
	out_company_type_relationships	OUT security_pkg.T_OUTPUT_CUR,
	out_on_behalf_of_relationships		OUT security_pkg.T_OUTPUT_CUR,
	out_group_types							OUT security_pkg.T_OUTPUT_CUR,
	out_company_type_roles							OUT security_pkg.T_OUTPUT_CUR,
	out_capabilities								OUT security_pkg.T_OUTPUT_CUR,
	out_matrix										OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPermissionMatrix (
	out_matrix						OUT security_pkg.T_OUTPUT_CUR
);

-- Pass in 0 for "null company type id", -1 for "any non-null company type id", or an exact id to match.
PROCEDURE GetPermissionMatrixByTypes (
	in_capability_ids				IN security_pkg.T_SID_IDS,
	in_primary_company_type_id		IN company_type_capability.primary_company_type_id%TYPE,
	in_secondary_company_type_id	IN company_type_capability.secondary_company_type_id%TYPE,
	in_tertiary_company_type_id		IN company_type_capability.tertiary_company_type_id%TYPE,
	out_matrix						OUT security_pkg.T_OUTPUT_CUR
);

/* (C# COMPATIBLE) */
PROCEDURE CheckNoRelationshipPermission(
	in_primary_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_permission_set		IN security_Pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

/* Checks the permission against a no related supplier */
FUNCTION CheckNoRelationshipPermission(
	in_primary_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_permission_set		IN security_Pkg.T_PERMISSION
)RETURN BOOLEAN; 

PROCEDURE GetUnlinkedCapabilities(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE LinkCapability(
	in_capability				IN	chain_pkg.T_CAPABILITY,
	in_default_permission_set	IN	csr.customer_flow_capability.default_permission_set%TYPE DEFAULT NULL,
	out_cur						OUT	SYS_REFCURSOR
);

FUNCTION GetCapableCompanyTypeIds(
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_reversed_capability			IN	chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

FUNCTION GetCapableCompanySids(
	in_company_sids					IN	security.T_SID_TABLE,
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_reversed_capability			IN	chain_pkg.T_CAPABILITY
) RETURN security.T_SID_TABLE;

PROCEDURE FillUserGroups;

END type_capability_pkg;
/

