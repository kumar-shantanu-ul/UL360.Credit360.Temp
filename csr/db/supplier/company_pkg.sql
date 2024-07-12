CREATE OR REPLACE PACKAGE  SUPPLIER.company_pkg
IS

COMPANY_ACTIVE 				CONSTANT NUMBER(10) := 1;
COMPANY_INACTIVE 			CONSTANT NUMBER(10) := 0;

COMPANY_NOT_DELETED			CONSTANT NUMBER(10) := 0;
COMPANY_DELETED				CONSTANT NUMBER(10) := 1;

ERR_COMPANY_IS_SUPPLIER		CONSTANT NUMBER := -20215;
COMPANY_IS_SUPPLIER			EXCEPTION;
PRAGMA EXCEPTION_INIT(COMPANY_IS_SUPPLIER, -20215);

ERR_COMPANY_IS_APPROVER		CONSTANT NUMBER := -20216;
COMPANY_IS_APPROVER			EXCEPTION;
PRAGMA EXCEPTION_INIT(COMPANY_IS_APPROVER, -20216);

ERR_COMPANY_HAS_USERS		CONSTANT NUMBER := -20217;
COMPANY_HAS_USERS			EXCEPTION;
PRAGMA EXCEPTION_INIT(COMPANY_HAS_USERS, -20217);

ERR_NULL_ARRAY_ARGUMENT		CONSTANT NUMBER := -20218;
NULL_ARRAY_ARGUMENT			EXCEPTION;
PRAGMA EXCEPTION_INIT(NULL_ARRAY_ARGUMENT, -20218);

COMPANY_DATA_BEING_ENTERED	CONSTANT NUMBER(10) := 1;

TYPE T_TAG_NUMBERS IS TABLE OF company_tag.num%TYPE INDEX BY PLS_INTEGER;
TYPE T_TAG_NOTES IS TABLE OF company_tag.note%TYPE INDEX BY PLS_INTEGER;

FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;

FUNCTION GetCompanyName
RETURN security_pkg.T_SO_NAME;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_class_id				IN	security_pkg.T_CLASS_ID,
	in_name					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id		IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN	security_pkg.T_SID_ID
);

PROCEDURE CreateCompany(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_addr1				IN	company.address_1%TYPE,
	in_addr2				IN	company.address_2%TYPE,
	in_addr3				IN	company.address_3%TYPE,
	in_addr4				IN	company.address_4%TYPE,
	in_town					IN	company.town%TYPE,
	in_state				IN	company.state%TYPE,
	in_postcode				IN	company.postcode%TYPE,
	in_phone				IN	company.phone%TYPE,
	in_phone_alt			IN	company.phone_alt%TYPE,
	in_fax					IN	company.fax%TYPE,
	in_internal_supplier	IN	company.internal_supplier%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	out_company_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_act					IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_addr1				IN	company.address_1%TYPE,
	in_addr2				IN	company.address_2%TYPE,
	in_addr3				IN	company.address_3%TYPE,
	in_addr4				IN	company.address_4%TYPE,
	in_town					IN	company.town%TYPE,
	in_state				IN	company.state%TYPE,
	in_postcode				IN	company.postcode%TYPE,
	in_phone				IN	company.phone%TYPE,
	in_phone_alt			IN	company.phone_alt%TYPE,
	in_fax					IN	company.fax%TYPE,
	in_internal_supplier	IN	company.internal_supplier%TYPE,
	in_active				IN	company.active%TYPE,
	in_country_code			IN	company.country_code%TYPE
);

PROCEDURE DeleteMultipleCompanies(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sids			IN	security_pkg.T_SID_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_act					IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompanyCount(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_active				IN	company.active%TYPE,
	out_count				OUT	NUMBER
);

PROCEDURE SearchCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_active				IN	company.active%TYPE,
	in_order_by				IN	VARCHAR2,
	in_order_direction		IN	VARCHAR2,
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_search				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddContact(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_contact_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SearchForUnassignedUsers(
    in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	csr.csr_user.full_name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveContact(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_contact_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetContacts(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION MakeFullAddress(
	in_address_1			IN	VARCHAR2,
	in_address_2			IN	VARCHAR2,
	in_address_3			IN	VARCHAR2,
	in_address_4			IN	VARCHAR2,
	in_town					IN	VARCHAR2,
	in_state				IN	VARCHAR2,
	in_postcode				IN	VARCHAR2
) RETURN VARCHAR2;

FUNCTION IsCompanyAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	company.company_sid%TYPE,
	in_perms				IN	security_pkg.T_PERMISSION
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(IsCompanyAccessAllowed, WNDS, WNPS);

FUNCTION IsCompanyAccessAllowed(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	company.company_sid%TYPE,
	in_perms				IN	security_pkg.T_PERMISSION
) RETURN BOOLEAN;
--PRAGMA RESTRICT_REFERENCES(IsCompanyAccessAllowed, WNDS, WNPS);

FUNCTION IsCompaniesAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_user_to_check_sid	IN	security_pkg.T_SID_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_perms				IN	security_pkg.T_PERMISSION
) RETURN BOOLEAN;
--PRAGMA RESTRICT_REFERENCES(IsCompaniesAccessAllowed, WNDS, WNPS);

FUNCTION IsCompanyWriteAccessAllowed(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	company.company_sid%TYPE
) RETURN NUMBER;
--PRAGMA RESTRICT_REFERENCES(IsCompanyWriteAccessAllowed, WNDS, WNPS);

FUNCTION GetNameFromSid(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

PROCEDURE GetAllowedCompForProduct (
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllowedIntCompForProduct (
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

-------------------------------------

PROCEDURE GetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE, -- Can be NULL to get tags form any gorup
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			    IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE,
	in_tag_ids				IN	tag_pkg.T_TAG_IDS,
	in_tag_numbers			IN	T_TAG_NUMBERS,
	in_tag_notes			IN	T_TAG_NOTES
);

PROCEDURE SetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE,
	in_tag_ids				IN	tag_pkg.T_TAG_IDS
);

PROCEDURE GetCountries(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetCompanies(
	out_cur							OUT	SYS_REFCURSOR
);

END company_pkg;
/

