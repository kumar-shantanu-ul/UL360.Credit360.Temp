CREATE OR REPLACE PACKAGE  CHAIN.helper_pkg
IS

TYPE T_NUMBER_ARRAY IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetInvitationUserTpl (
	in_lang					IN  invitation_user_tpl.lang%TYPE,
	in_header				IN  invitation_user_tpl.header%TYPE,
	in_footer				IN  invitation_user_tpl.footer%TYPE
);

PROCEDURE GetInvitationUserTpl (
	in_lang					IN  invitation_user_tpl.lang%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION HasCustomerOptions
RETURN NUMBER;

PROCEDURE GetCustomerOptions (
	in_host					IN  url_overrides.host%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreatePendingContainer
RETURN security_pkg.T_SID_ID;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetChainCountryCode(
	in_country_name		v$country.name%TYPE
) RETURN v$country.country_code%TYPE;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE;

FUNCTION NumericArrayEmpty(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN NUMBER;

FUNCTION NumericArrayToTable(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN T_NUMERIC_TABLE;

PROCEDURE IsChainAdmin(
	out_result				OUT  NUMBER
);

FUNCTION IsChainAdmin
RETURN BOOLEAN;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsChainUser(
	out_result				OUT  NUMBER
);

FUNCTION IsChainUser
RETURN BOOLEAN;

FUNCTION IsChainUser (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsChainUserNum (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

FUNCTION IsElevatedAccount
RETURN BOOLEAN;

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE RevertLogonUCD;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

FUNCTION IsTopCompany
RETURN NUMBER;

FUNCTION IsSidTopCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION IsChainTrnsprntForMyCmpny
RETURN BOOLEAN;

FUNCTION Flag (
	in_flags				IN  chain_pkg.T_FLAG,
	in_flag					IN  chain_pkg.T_FLAG
) RETURN chain_pkg.T_FLAG;

FUNCTION NormaliseCompanyName (
	in_company_name			IN  company.name%TYPE
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC;

FUNCTION GenerateSOName (
	in_company_name			IN company.name%TYPE,
	in_company_sid			IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC;

PROCEDURE UpdateSector (
	in_sector_id			IN	sector.sector_id%TYPE,
	in_description			IN	sector.description%TYPE,
	in_parent_sector_id		IN	sector.parent_sector_id%TYPE DEFAULT NULL
);

PROCEDURE DeleteSector (
	in_sector_id			IN	sector.sector_id%TYPE
);

PROCEDURE GetSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateBusinessUnit (
	in_business_unit_id		IN	business_unit.business_unit_id%TYPE,
	in_description			IN	business_unit.description%TYPE,
	in_parent_business_unit_id	IN	business_unit.parent_business_unit_id%TYPE DEFAULT NULL
);

PROCEDURE DeleteBusinessUnit (
	in_business_unit_id		IN	business_unit.business_unit_id%TYPE
);

FUNCTION GetBusinessUnitId (
	in_description			IN  business_unit.description%TYPE
) RETURN NUMBER;

PROCEDURE GetBusinessUnits (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveBusinessUnits (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteReferenceLabel (
	in_reference_id						IN reference.reference_id%TYPE
);

PROCEDURE SaveReferenceLabel (
	in_reference_id						IN reference.reference_id%TYPE,
	in_lookup_key						IN reference.lookup_key%TYPE,
	in_label							IN reference.label%TYPE,
	in_mandatory						IN reference.mandatory%TYPE,
	in_reference_uniqueness_id			IN reference.reference_uniqueness_id%TYPE,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT 0,
	in_show_in_filter					IN reference.show_in_filter%TYPE DEFAULT 1,
	in_reference_validation_id 			IN reference.reference_validation_id%TYPE DEFAULT 0,
	in_company_type_ids					IN T_NUMBER_ARRAY,
	out_reference_id					OUT reference.reference_id%TYPE
);

FUNCTION GetRefPermsByType (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_company_sid						IN company.company_sid%TYPE DEFAULT NULL,
	in_reference_id						IN reference.reference_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL
)
RETURN T_REF_PERM_TABLE;

FUNCTION GetBestRefPerms (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_company_sid						IN company.company_sid%TYPE DEFAULT NULL,
	in_reference_id						IN reference.reference_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL
)
RETURN T_REF_PERM_TABLE;

PROCEDURE GetPermissibleReferences (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL,
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPermissibleReferencesBySid (
	in_company_sid						IN company.company_sid%TYPE,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL,
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReferences (
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetReferenceCapability (
	in_reference_id						IN reference_capability.reference_id%TYPE,
	in_primary_company_type_id			IN reference_capability.primary_company_type_id%TYPE,
	in_primary_comp_group_type_id		IN reference_capability.primary_company_group_type_id%TYPE,
	in_primary_comp_type_role_sid		IN reference_capability.primary_company_type_role_sid%TYPE,
	in_secondary_company_type_id		IN reference_capability.secondary_company_type_id%TYPE,
	in_permission_set					IN reference_capability.permission_set%TYPE
);

PROCEDURE GetReferenceCapabilities (
	in_reference_id						IN reference_capability.reference_id%TYPE,
	in_primary_company_type_id			IN reference_capability.primary_company_type_id%TYPE,
	in_secondary_company_type_id		IN reference_capability.secondary_company_type_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION UseTypeCapabilities
RETURN BOOLEAN;

FUNCTION UseTraditionalCapabilities
RETURN BOOLEAN;

FUNCTION AddSidLinkLookup (
	in_sids			IN	security.T_SID_TABLE
) RETURN NUMBER;

FUNCTION AddFilterSidLinkLookup (
	in_sids			IN	T_FILTERED_OBJECT_TABLE
) RETURN NUMBER;

FUNCTION IsShareQnrWithOnBehalfEnabled
RETURN NUMBER;

FUNCTION UseCompanyTypeUserGroups
RETURN NUMBER;

PROCEDURE LockRegionTree(
	in_tree_sid				IN			security.security_pkg.T_SID_ID
);

FUNCTION IsEmailDomainRestricted
RETURN NUMBER;

FUNCTION SendChangeEmailAlert
RETURN NUMBER;

FUNCTION ShowAllComponents
RETURN NUMBER;

FUNCTION IsDedupePreprocessEnabled
RETURN NUMBER;

FUNCTION IsProductComplianceEnabled
RETURN NUMBER;

FUNCTION AllowDuplicateEmails
RETURN NUMBER;

PROCEDURE GetExportMenuItems (
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION AreVisibilityOptionsEnabled
RETURN NUMBER;

PROCEDURE GetReferenceValidations(
	out_cur 		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllReferenceLabelValues (
	in_lookup_key				IN reference.lookup_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION CanReinviteSupplier RETURN customer_options.reinvite_supplier%TYPE;

PROCEDURE GetRiskLevels (
	out_risk_level_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteRiskLevel(
	in_risk_level_id			IN	risk_level.risk_level_id%TYPE
);

PROCEDURE SaveRiskLevel(
	in_risk_level_id			IN	risk_level.risk_level_id%TYPE,
	in_label					IN	risk_level.label%TYPE,
	in_lookup_key				IN	risk_level.lookup_key%TYPE,
	out_risk_level_id			OUT	risk_level.risk_level_id%TYPE
);

PROCEDURE GetCountryRiskLevels (
	out_country_risk_level_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCountryRiskLevel(
	in_country					IN	country_risk_level.country%TYPE,
	in_risk_level_id			IN	risk_level.risk_level_id%TYPE,
	in_start_dtm				IN	country_risk_level.start_dtm%TYPE
);

PROCEDURE DeleteCountryRiskLevel(
	in_country				IN	country_risk_level.country%TYPE
);

PROCEDURE ImportCountryRisk;

FUNCTION IsChainSite
RETURN NUMBER;

FUNCTION HasCompanyContext
RETURN security_pkg.T_SID_ID;

FUNCTION IsCompanyGeotagEnabled
RETURN NUMBER;

FUNCTION GenerateCompanySignature(
	in_company_name			company.name%TYPE,
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL,
	in_parent_sid			security_pkg.T_SID_ID DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC;

END helper_pkg;
/
