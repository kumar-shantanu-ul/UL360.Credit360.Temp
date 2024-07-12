CREATE OR REPLACE PACKAGE CHAIN.setup_pkg
IS

PROCEDURE CreateSOs (
	in_overwrite_default_url		BOOLEAN,
	in_is_single_tier				BOOLEAN,
	in_overwrite_logon_url			BOOLEAN,
	in_create_menu_items			BOOLEAN,
	in_alter_existing_attributes	BOOLEAN
);

PROCEDURE EnableSiteLightweight;

PROCEDURE EnableSite (
	in_site_name					IN customer_options.site_name%TYPE DEFAULT NULL,
	in_support_email				IN customer_options.support_email%TYPE DEFAULT NULL,
	in_overwrite_default_url		IN BOOLEAN DEFAULT FALSE, -- was 0
	in_create_sectors				IN BOOLEAN DEFAULT FALSE, -- was 1
	in_is_single_tier				IN BOOLEAN DEFAULT TRUE,  -- was 1
	in_overwrite_logon_url			IN BOOLEAN DEFAULT TRUE,  -- was 1
	in_enable_csr_supplier			IN BOOLEAN DEFAULT TRUE   -- was based on link_pkg
);

PROCEDURE ReApplyEnableSite (
	in_is_single_tier				BOOLEAN DEFAULT TRUE
);

PROCEDURE EnableOneTier (
	in_top_company_singular			IN company_type.singular%TYPE DEFAULT 'Top company',
	in_top_company_plural			IN company_type.plural%TYPE DEFAULT 'Top companies',
	in_top_company_allow_lower		IN BOOLEAN DEFAULT TRUE,
	in_top_company_key				IN company_type.lookup_key%TYPE DEFAULT 'TOP'
);

PROCEDURE EnableTwoTier (
	in_top_company_singular			IN company_type.singular%TYPE DEFAULT 'Company',
	in_top_company_plural			IN company_type.plural%TYPE DEFAULT 'Companies',
	in_top_company_allow_lower		IN BOOLEAN DEFAULT TRUE,
	in_top_company_key				IN company_type.lookup_key%TYPE DEFAULT 'TOP',
	in_supplier_singular			IN company_type.singular%TYPE DEFAULT 'Supplier',
	in_supplier_plural				IN company_type.plural%TYPE DEFAULT 'Suppliers',
	in_supplier_allow_lower			IN BOOLEAN DEFAULT TRUE,
	in_supplier_key					IN company_type.lookup_key%TYPE DEFAULT 'SUPPLIERS'
);

PROCEDURE EnableThreeTierHolding (
	in_top_company_singular				IN company_type.singular%TYPE DEFAULT 'Company',
	in_top_company_plural				IN company_type.plural%TYPE DEFAULT 'Companies',
	in_top_company_allow_lower			IN BOOLEAN DEFAULT TRUE,
	in_top_company_key					IN company_type.lookup_key%TYPE DEFAULT 'TOP',
	in_holding_singular					IN company_type.singular%TYPE DEFAULT 'Holding company',
	in_holding_plural					IN company_type.plural%TYPE DEFAULT 'Holding companies',
	in_holding_allow_lower				IN BOOLEAN DEFAULT TRUE,
	in_holding_key						IN company_type.lookup_key%TYPE DEFAULT 'HOLDING',
	in_site_singular					IN company_type.singular%TYPE DEFAULT 'Site',
	in_site_plural						IN company_type.plural%TYPE DEFAULT 'Sites',
	in_site_allow_lower					IN BOOLEAN DEFAULT TRUE,
	in_site_key							IN company_type.lookup_key%TYPE DEFAULT 'SITES'
);

-- Creates a company 
FUNCTION CreateCompanyLightweight (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

-- company type implementation
FUNCTION CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateSubCompany (
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

-- company type implementation
PROCEDURE CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
);

-- company type implementation
PROCEDURE ApplyExtendedCapabilities (
	in_company_type_key				IN company_type.lookup_key%TYPE
);

-- traditional implementation (to be depricated)
FUNCTION CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE,
	in_is_top_company				IN BOOLEAN
) RETURN security_pkg.T_SID_ID;

-- traditional implementation (to be depricated)
PROCEDURE ApplyExtendedCapabilities (
	in_company_sid					IN security_pkg.T_SID_ID
);

FUNCTION CreateUserGroupForCompany (
	in_company_sid					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

PROCEDURE AddUsersToCompany (
	in_company_sid					IN security_pkg.T_SID_ID,
	in_filter_by_email_ends_in		IN VARCHAR2 DEFAULT NULL
);

FUNCTION HasImplementation (
	in_name							IN implementation.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasImplementationPackage (
	in_link_pkg						IN implementation.link_pkg%TYPE
) RETURN BOOLEAN;

PROCEDURE AddSupplierImplementation;

PROCEDURE AddImplementation (
	in_name							IN implementation.name%TYPE,	
	in_link_pkg						IN implementation.link_pkg%TYPE
);

FUNCTION IsChainEnabled
RETURN BOOLEAN;

FUNCTION SQL_IsChainEnabled
RETURN NUMBER;

PROCEDURE CreateSectors;

PROCEDURE SetupChainAdminGroup (
	in_survey_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_workflow_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_READ,
	in_reporting_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_csr_users_access				IN	security_pkg.T_PERMISSION DEFAULT 0,
	in_audit_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_alert_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_trash_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_cms_access					IN	security_pkg.T_PERMISSION DEFAULT 0
);

PROCEDURE EnableActivities;

PROCEDURE SetupPlugin(
	in_page_company_type_id		company.company_type_id%TYPE,
	in_user_company_type_id		company.company_type_id%TYPE,
	in_label					company_tab.label%TYPE,
	in_js_class					csr.plugin.js_class%TYPE,
	in_viewing_own_company		company_tab.viewing_own_company%TYPE DEFAULT 1
);

/*
-- This appears to be out of date, and is only referenced by a util script (db\utils\EnableChainSupplierProductTypes).
PROCEDURE EnableSupplierProductTypes (
	in_top_company_type			IN  VARCHAR2,
	in_secondary_company_type	IN  VARCHAR2
);
*/

PROCEDURE SetupDefaultPlugins (
	in_top_company_type			IN  VARCHAR2
);

PROCEDURE EnableCompanySelfReg;

PROCEDURE SetupCsrAlerts;

END setup_pkg;
/