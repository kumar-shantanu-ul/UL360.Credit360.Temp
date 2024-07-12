CREATE OR REPLACE PACKAGE  CHAIN.capability_pkg
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

-- used in audit logs
FUNCTION GetCapabilityPath (
	in_capability_id			IN  capability.capability_id%TYPE
) RETURN VARCHAR2;

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

-- auto type
PROCEDURE UnhideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE UnhideCapability (
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
		POTENTIAL CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- These are provided for forward compatibility with type_capability_pkg

-- boolean
PROCEDURE CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- boolean
PROCEDURE CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
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

/************************************************************** 
		POTENTIAL CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
-- These are provided for forward compatibility with type_capability_pkg

-- boolean
FUNCTION CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckPotentialCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckPotentialCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

/************************************************************** 
		CHECK CAPABILITY BY SUPPLIER TYPE
**************************************************************/

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

FUNCTION CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

PROCEDURE CheckCapabilityBySupplierType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

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

FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

FUNCTION CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	out_result					OUT NUMBER
);

PROCEDURE CheckCapabilityByTertiaryType (
	in_primary_company_sid		IN  security_pkg.T_SID_ID,
	in_secondary_company_sid	IN  security_pkg.T_SID_ID,
	in_tertiary_company_type	IN  company.company_type_id%TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_permission_set			IN  security_Pkg.T_PERMISSION,
	out_result					OUT NUMBER
);

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

PROCEDURE GetCapabilities(
	out_curs	OUT security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCapabilityGroups(
	out_cur OUT security_pkg.T_OUTPUT_CUR
);

END capability_pkg;
/

