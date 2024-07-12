CREATE OR REPLACE PACKAGE chain.test_chain_utils_pkg AS

TYPE	T_VARCHAR2_T		IS TABLE OF VARCHAR2(4000);

TAB_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(TAB_NOT_FOUND, -00942);

FUNCTION GetTagGroupId(
	in_lookup_key	csr.tag_group.lookup_key%TYPE
)RETURN csr.tag_group.tag_group_id%TYPE;

FUNCTION ToArr(
	in_vals		IN VARCHAR2
)RETURN security_pkg.T_VARCHAR2_ARRAY;

PROCEDURE LinkRoleToCompanyType(
	in_role_sid				security_pkg.T_SID_ID,
	in_company_type_lookup	company_type.lookup_key%TYPE
);

FUNCTION GetChainCompanySid(
	in_name				company.name%TYPE,
	in_country_code		company.country_code%TYPE
)RETURN security_pkg.T_SID_ID;

PROCEDURE SetupSingleTier;
PROCEDURE SetupTwoTier;

PROCEDURE TearDownSingleTier;
PROCEDURE TearDownTwoTier;
PROCEDURE TearDownImportSource(
	in_lookup_key	import_source.lookup_key%TYPE
);
PROCEDURE DeleteFullyCompaniesOfType(
	in_company_type_lookup	IN company_type.lookup_key%TYPE
);

PROCEDURE GetCompaniesFromProcessedRec(
	in_processed_record_id		IN NUMBER,
	out_created_company_sid		OUT security.security_pkg.T_SID_ID,
	out_matched_company_sids	OUT security.security_pkg.T_SID_IDS
);

PROCEDURE ProcessParentStagingRecord( 
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_force_re_eval			IN NUMBER DEFAULT 0,
	out_processed_record_ids	OUT security_pkg.T_SID_IDS,
	out_created_company_sid		OUT security.security_pkg.T_SID_ID,
	out_matched_company_sids	OUT security.security_pkg.T_SID_IDS
);

PROCEDURE CreateCompanyNoRelationship(
	in_name				IN company.name%TYPE,
	in_country_code		IN company.country_code%TYPE,
	in_company_type_id	IN company.company_type_id%TYPE,
	in_city				IN company.city%TYPE DEFAULT NULL,
	in_state			IN company.state%TYPE DEFAULT NULL,
	in_sector_id		IN company.sector_id%TYPE,
	out_company_sid		OUT security.security_pkg.T_SID_ID
);

PROCEDURE ConnectWithTopCompany(
	in_company_sid		IN security.security_pkg.T_SID_ID
);

PROCEDURE ConnectCompanies(
	in_purchaser_sid		IN security.security_pkg.T_SID_ID,
	in_supplier_sid			IN security.security_pkg.T_SID_ID
);

PROCEDURE CreateCompanyHelper(
	in_name				IN company.name%TYPE,
	in_country_code		IN company.country_code%TYPE,
	in_company_type_id	IN company.company_type_id%TYPE,
	in_city				IN company.city%TYPE DEFAULT NULL,
	in_state			IN company.state%TYPE DEFAULT NULL,
	in_sector_id		IN company.sector_id%TYPE,
	out_company_sid		OUT security.security_pkg.T_SID_ID
);

PROCEDURE CreateSubCompanyHelper(
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	in_name						IN	company.name%TYPE,
	in_country_code				IN	company.name%TYPE,
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	out_company_sid				OUT security.security_pkg.T_SID_ID
);

PROCEDURE SetupUITest_CTStructure;
PROCEDURE SetupUITest_EnableRemoveUser;

FUNCTION SetupUITest_AddTopCompUser(
	in_user_name		csr.csr_user.user_name%TYPE,
	in_email			csr.csr_user.email%TYPE,
	in_pwd				VARCHAR2
) RETURN security.security_pkg.T_SID_ID;

PROCEDURE UpdateCompanyTypeLayout(
	in_lookup_key				company_type.lookup_key%TYPE,
	in_default_region_layout	company_type.default_region_layout%TYPE
);

PROCEDURE ToggleCreateSubsUnderParentForCompanyType(
	in_lookup_key					company_type.lookup_key%TYPE,
	in_create_subsids_under_parent 	company_type.create_subsids_under_parent%TYPE
);

PROCEDURE EnableRoleForCompanyType(
	in_lookup_key	company_type.lookup_key%TYPE
);

PROCEDURE EnableCascadeRoleForCTR(
	in_prim_lookup_key	company_type.lookup_key%TYPE,
	in_sec_lookup_key	company_type.lookup_key%TYPE
);

FUNCTION EnableFollowerRoleForCompTypeRel(
	in_vendor_key	company_type.lookup_key%TYPE,
	in_supplier_key	company_type.lookup_key%TYPE
) RETURN NUMBER;

FUNCTION CreateCompanyUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN  csr.csr_user.user_name%TYPE
) RETURN security.security_pkg.T_SID_ID;

END;
/