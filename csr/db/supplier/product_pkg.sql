CREATE OR REPLACE PACKAGE SUPPLIER.product_pkg
IS

TYPE T_TAG_NUMBERS IS TABLE OF product_tag.num%TYPE INDEX BY PLS_INTEGER; -- TO DO  - this should be moved - either into the tag pkg or the supplier\create_types.sql
TYPE T_TAG_NOTES IS TABLE OF product_tag.note%TYPE INDEX BY PLS_INTEGER; -- TO DO  - this should be moved - either into the tag pkg or the supplier\create_types.sql
TYPE T_PRODUCT_IDS IS TABLE OF product.product_id%TYPE INDEX BY PLS_INTEGER;

TYPE T_PERIODS IS TABLE OF period.period_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_PRODUCT_SALES_VOLUMES IS TABLE OF product_sales_volume.volume%TYPE INDEX BY PLS_INTEGER;
TYPE T_PRODUCT_VALUES IS TABLE OF product_sales_volume.value%TYPE INDEX BY PLS_INTEGER;

-- product status constants
DATA_BEING_ENTERED				CONSTANT NUMBER(10) := 1;
DATA_SUBMITTED					CONSTANT NUMBER(10) := 2;
DATA_APPROVED					CONSTANT NUMBER(10) := 3;
DATA_BEING_REVIEWED				CONSTANT NUMBER(10) := 4;

PRODUCT_ACTIVE 					CONSTANT NUMBER(10) := 1;
PRODUCT_INACTIVE 				CONSTANT NUMBER(10) := 0;

PRODUCT_NOT_DELETED				CONSTANT NUMBER(10) := 0;
PRODUCT_DELETED					CONSTANT NUMBER(10) := 1;

-- product status constants
PRODUCT_CLASS_FORMULATED		CONSTANT NUMBER(10) := 1;
PRODUCT_CLASS_MANUFACTURED		CONSTANT NUMBER(10) := 2;
PRODUCT_CLASS_GIFT_PACK			CONSTANT NUMBER(10) := 3;

ERR_NULL_ARRAY_ARGUMENT			CONSTANT NUMBER := -20300;
NULL_ARRAY_ARGUMENT				EXCEPTION;
PRAGMA EXCEPTION_INIT(NULL_ARRAY_ARGUMENT, -20300);

ERR_PRODUCT_HAS_SUPPLIER		CONSTANT NUMBER := -20301;
PRODUCT_HAS_SUPPLIER			EXCEPTION;
PRAGMA EXCEPTION_INIT(PRODUCT_HAS_SUPPLIER, -20301);


PROCEDURE CreateProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_active				IN product.active%TYPE,
	out_product_id			OUT product.product_id%TYPE
);

PROCEDURE CopyProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_product_id			OUT product.product_id%TYPE
);

PROCEDURE CopyQAssToNewProd(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_old_product_id			IN product.product_id%TYPE,
	in_new_product_id			IN product.product_id%TYPE
);

PROCEDURE DeleteMultipleProducts(
	in_act_id				IN security_pkg.T_ACT_ID,	
	in_product_ids			IN T_PRODUCT_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE
);

PROCEDURE UpdateProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_active				IN product.active%TYPE
);

-- for use by the data sync update function
PROCEDURE UpdateProductDescription(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_new_description		IN product.description%TYPE
);

PROCEDURE SetProductTag(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_id				IN tag.tag_id%TYPE
);

PROCEDURE SetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE,
	in_tag_ids				IN tag_pkg.T_TAG_IDS,
	in_tag_numbers			IN T_TAG_NUMBERS,
	in_tag_notes			IN T_TAG_NOTES
);

PROCEDURE SetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE,
	in_tag_ids				IN tag_pkg.T_TAG_IDS
);

PROCEDURE SearchProductCount(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,
	out_count				OUT	NUMBER
);

PROCEDURE SearchProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,	
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_search				IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchProductCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_search				IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductsByCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductsByDesc(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_desc			IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE, -- Can be NULL to get tags form any gorup
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProdGroupStatus(
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProdGroupStatusFromQClass(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_class				IN questionnaire.class_name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductGroupStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_status_id			IN product_questionnaire_group.group_status_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE
);

PROCEDURE SetProductGroupStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	in_status_id			IN product_questionnaire_group.group_status_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductGroupQuestStatuses(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetSmpWkflwProdUserProv(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSmpWkflwProdUserApprv(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOpenWkflwProdUserLink(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	in_approving			IN NUMBER,
	in_complete				IN NUMBER,
	in_from_dtm				IN DATE, 
	in_to_dtm				IN DATE, 
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/*
PROCEDURE GetOpenWkflwProdUserLinkCnt(
	in_user_sid					IN security_pkg.T_SID_ID,
	in_app_sid					IN security_pkg.T_SID_ID,
	in_group_id					IN questionnaire_group.group_id%TYPE,
	out_count					OUT	NUMBER
);
*/

-- for a particular product and user return a list of all questionnaires ids, whether the questionnaire is used, and whether the user is linked to it as provider or approver. 
PROCEDURE GetAllowUserQLinks(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN user_report_settings.period_id%TYPE,
	out_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSalesVolumesForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_product_id		IN user_report_settings.period_id%TYPE,
	out_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetSalesVolumesForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN product_sales_volume.product_id%TYPE,
	in_period_ids		IN T_PERIODS,
	in_values			IN T_PRODUCT_VALUES,
	in_volumes			IN T_PRODUCT_SALES_VOLUMES
);

PROCEDURE SetSalesVolumeForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_product_code		IN product.product_code%TYPE,
	in_period_id		IN product_sales_volume.period_id%TYPE,
	in_value			IN product_sales_volume.value%TYPE,
	in_volume			IN product_sales_volume.volume%TYPE
);

PROCEDURE SetSalesVolumeForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN product_sales_volume.product_id%TYPE,
	in_period_id		IN product_sales_volume.period_id%TYPE,
	in_value			IN product_sales_volume.value%TYPE,
	in_volume			IN product_sales_volume.volume%TYPE
);

FUNCTION GetSaleType(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(GetSaleType, WNDS, WNPS);

FUNCTION GetMerchantType(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(GetMerchantType, WNDS, WNPS);

FUNCTION GetMerchantTypeDescription(
	in_product_id			IN 	product.product_id%TYPE
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetMerchantTypeDescription, WNDS, WNPS);

FUNCTION IsProductAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_product_id			IN 	product.product_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
	
) RETURN BOOLEAN;	
PRAGMA RESTRICT_REFERENCES(IsProductAccessAllowed, WNDS, WNPS);

PROCEDURE IsProductAccessAllowedWrite(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_allow				OUT NUMBER
);

PROCEDURE GetProductsUserIsProviderFor(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductsUserIsApproverFor(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductsUserIsLinkedTo(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetMinCertExpiryDate (
	in_product_id			IN product.product_id%TYPE
)RETURN DATE;

FUNCTION ProductExists(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE
) RETURN NUMBER;

FUNCTION GetProdCodeFromTag(
	in_tag_id				IN tag.tag_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetAllProviderUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProvidersForQuestionnaire(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id						IN product.product_id%TYPE,
	in_questionnaire_id					IN questionnaire.questionnaire_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetQuestionnaireProviderLinks(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id						IN product.product_id%TYPE,
	in_questionnaire_id					IN questionnaire.questionnaire_id%TYPE,
	in_user_sids						IN security_pkg.T_SID_IDS,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllApproverUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetApproversForQuestionnaire(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id						IN product.product_id%TYPE,
	in_questionnaire_id					IN questionnaire.questionnaire_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetApproversForGrpQuestionn(
	in_product_id						IN product.product_id%TYPE,
	in_group_id							IN questionnaire_group.group_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProvidersForGrpQuestionn(
	in_product_id						IN product.product_id%TYPE,
	in_group_id							IN questionnaire_group.group_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetQuestionnaireApproverLinks(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id						IN product.product_id%TYPE,
	in_questionnaire_id					IN questionnaire.questionnaire_id%TYPE,
	in_user_sids						IN security_pkg.T_SID_IDS,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnairesForProduct(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur 							OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetMaxProdRevisionId(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER;

FUNCTION GetProdRevisionDescription(
    in_product_id			IN 	product.product_id%TYPE,
    in_revision_id          IN  product_revision.revision_id%TYPE
) RETURN VARCHAR2;

FUNCTION GetMaxProdRevisionDescription(
	in_product_id			IN 	product.product_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetAllProductsUserProviding(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_used_only			IN all_product_questionnaire.used%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllProductsUserApproving(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_used_only			IN all_product_questionnaire.used%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStarted(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_started				IN GT_PRODUCT_USER.started%TYPE
);

FUNCTION StatusIconExportName(
	in_status_id			IN	product_questionnaire.questionnaire_status_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetVisibleCompanyProducts(
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_order_by				IN	VARCHAR2,
	in_order_direction		IN	VARCHAR2,
	in_search				IN	VARCHAR2,
	in_overdue_only			IN	NUMBER,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGtApproversAndProviders(
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTags(
	in_group_name					IN	tag_group.name%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

END product_pkg;
/

