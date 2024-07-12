CREATE OR REPLACE PACKAGE  CHAIN.company_type_pkg
IS

FUNCTION GetCompanyTypeDescription (
	in_company_type_id			IN  company_type.company_type_id%TYPE
) RETURN VARCHAR2;

PROCEDURE CompanyCreated (
	in_company_sid		IN security_pkg.T_SID_ID
);

PROCEDURE SwitchCompanyCompanyType(
	in_company_sid			IN security_pkg.T_SID_ID,	
	in_old_company_type_id	IN company_type.company_type_id%TYPE,
	in_new_company_type_id	IN company_type.company_type_id%TYPE
);

FUNCTION GetCountOfCompanies(
	in_company_type_id		IN	company_type.company_type_id%TYPE
) RETURN NUMBER;

PROCEDURE ElevateCompanyTypePosition (
	in_company_type_id		IN	company_type.company_type_id%TYPE
);

PROCEDURE DowngradeCompanyTypePosition (
	in_company_type_id		IN	company_type.company_type_id%TYPE
);

PROCEDURE SetCompanyTypePositions (
	in_order_company_type_keys 	IN  chain.T_STRING_LIST
);

PROCEDURE DeleteCompanyType (
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_move_related_companies	IN NUMBER DEFAULT 0
);

FUNCTION GetDefaultCompanyType
RETURN company_type.company_type_id%TYPE;

PROCEDURE SetDefaultCompanyType (
	in_company_type_id		IN	company_type.company_type_id%TYPE
);

PROCEDURE AddCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
);

PROCEDURE AddCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_path				IN  VARCHAR2,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
);

/* c# compatible */
PROCEDURE SetCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	company_type.allow_lower_case%TYPE,
	in_use_user_role				IN  company_type.use_user_role%TYPE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0
);

PROCEDURE SetCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	company_type.allow_lower_case%TYPE,
	in_use_user_role				IN  company_type.use_user_role%TYPE,
	in_css_class					IN  company_type.css_class%TYPE DEFAULT NULL,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1,
	in_create_doc_library_folder    IN  company_type.create_doc_library_folder%TYPE DEFAULT 0,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddDefaultCompanyType (
	in_lookup_key					IN	company_type.lookup_key%TYPE,	
	in_singular						IN	company_type.singular%TYPE,
	in_plural						IN	company_type.plural%TYPE,
	in_allow_lower					IN	BOOLEAN DEFAULT TRUE,
	in_use_user_role				IN  BOOLEAN DEFAULT FALSE,
	in_default_region_type			IN  company_type.default_region_type%TYPE DEFAULT csr.csr_data_pkg.REGION_TYPE_SUPPLIER,
	in_region_root_sid				IN  company_type.region_root_sid%TYPE DEFAULT NULL,
	in_default_region_layout		IN  company_type.default_region_layout%TYPE DEFAULT '{COUNTRY}/{SECTOR}',
	in_create_subsids_under_parent	IN  company_type.create_subsids_under_parent%TYPE DEFAULT 1
);

PROCEDURE AddCompanyTypeRelationship (
	in_company_type			IN	company_type.lookup_key%TYPE,
	in_related_company_type	IN	company_type.lookup_key%TYPE,
	in_use_user_roles		IN  company_type_relationship.use_user_roles%TYPE DEFAULT 0,
	in_flow_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_hidden				IN	company_type_relationship.hidden%TYPE DEFAULT 0,
	in_has_follower_role	IN	NUMBER DEFAULT 0,
	in_can_be_primary		IN  NUMBER DEFAULT 0
);

PROCEDURE AddCompanyTypeRelationship (
	in_company_type			IN	company_type.lookup_key%TYPE,
	in_related_company_type	IN	company_type.lookup_key%TYPE,
	in_use_user_roles		IN  BOOLEAN,
	in_flow_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_hidden				IN	BOOLEAN DEFAULT FALSE,
	in_has_follower_role	IN	BOOLEAN DEFAULT FALSE
);

PROCEDURE AddTertiaryRelationship (
	in_primary_company_type		IN	company_type.lookup_key%TYPE,
	in_secondary_company_type	IN	company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN	company_type.lookup_key%TYPE
);

PROCEDURE DeleteTertiaryRelationship (
	in_primary_company_type		IN	company_type.lookup_key%TYPE,	
	in_secondary_company_type	IN	company_type.lookup_key%TYPE,
	in_tertiary_company_type	IN	company_type.lookup_key%TYPE
);

PROCEDURE DeleteCompanyTypeRel_UNSEC(
	in_primary_company_type_id			IN	company_type.company_type_id%TYPE,
	in_secondary_company_type_id		IN	company_type.company_type_id%TYPE
);

PROCEDURE DeleteCompanyTypeRelationship (
	in_primary_company_type_id			IN	company_type.company_type_id%TYPE,
	in_secondary_company_type_id		IN	company_type.company_type_id%TYPE
);

PROCEDURE DeleteCompanyTypeRelationship (
	in_primary_company_type			IN	company_type.lookup_key%TYPE,
	in_secondary_company_type		IN	company_type.lookup_key%TYPE
);

PROCEDURE SetTopCompanyType (
	in_company_type			IN	company_type.lookup_key%TYPE
);

FUNCTION IsTopCompanyType (
	in_company_type			IN	company_type.lookup_key%TYPE
) RETURN BOOLEAN;

PROCEDURE SetTopCompanyType (
	in_company_type_id		IN	company_type.company_type_id%TYPE
);

FUNCTION GetCompanyTypeId
RETURN NUMBER;

FUNCTION GetCompanyTypeId (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_swallow_not_found	IN  BOOLEAN DEFAULT FALSE
) RETURN NUMBER;

FUNCTION GetCompanyTypeId (
	in_lookup_key			IN  company_type.lookup_key%TYPE,
	in_swallow_not_found	IN  BOOLEAN DEFAULT FALSE
) RETURN NUMBER;

FUNCTION GetCompanyTypeLookupKey (
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN company_type.lookup_key%TYPE;

FUNCTION GetLookupKey (
	in_company_type_id	IN	company_type.company_type_id%TYPE
) RETURN company_type.lookup_key%TYPE;

PROCEDURE GetCompanyTypeById (
	in_company_type_id		IN company_type.company_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyTypeRelationships (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTertiaryRelationships (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetDefaultCompanyTypeID RETURN company_type.company_type_id%TYPE;

PROCEDURE GetRelatedTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION IsType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_lookup_key			IN  company_type.lookup_key%TYPE
) RETURN BOOLEAN;

PROCEDURE IsType (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_lookup_key			IN  company_type.lookup_key%TYPE,
	out_result				OUT NUMBER
);

PROCEDURE GetCompanyRoles (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyTypeRoles (
	in_company_type_id		IN  company_type_role.company_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION IsRoleApplicable(
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_role_sid				IN security_pkg.T_SID_ID
)RETURN BOOLEAN;

PROCEDURE LinkRoleToCompanyType_UNSEC(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_mandatory			IN	company_type_role.mandatory%TYPE := 1,
	in_cascade_to_supplier	IN	company_type_role.cascade_to_supplier%TYPE := 0,
	in_pos					IN	company_type_role.pos%TYPE := NULL
);

PROCEDURE SetCompanyTypeRole (
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_role_name			IN	csr.role.name%TYPE DEFAULT NULL,
	in_mandatory			IN	company_type_role.mandatory%TYPE := 1,
	in_cascade_to_supplier	IN	company_type_role.cascade_to_supplier%TYPE := 0,
	in_pos					IN	company_type_role.pos%TYPE := NULL,
	in_lookup_key			IN	csr.role.lookup_key%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCompanyTypeRole(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GetAvailableCompTypeRoles(
	in_company_type_id		IN	company_type_role.company_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetManagementPageCompanyTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierTypesWithCapability (
	in_capability			IN	chain_pkg.T_CAPABILITY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTertiaryTypesWithCapability (
	in_capability					IN	chain_pkg.T_CAPABILITY,
	in_secondary_company_type_id	IN	company_type.company_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetDefaultRegionLayout(
	in_company_type_id		company_type.company_type_id%TYPE
) RETURN company_type.default_region_layout%TYPE;

END company_type_pkg;
/

