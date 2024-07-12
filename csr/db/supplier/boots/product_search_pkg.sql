CREATE OR REPLACE PACKAGE supplier.product_search_pkg
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

ERR_NULL_ARRAY_ARGUMENT			CONSTANT NUMBER := -20300;
NULL_ARRAY_ARGUMENT				EXCEPTION;
PRAGMA EXCEPTION_INIT(NULL_ARRAY_ARGUMENT, -20300);

ERR_PRODUCT_HAS_SUPPLIER		CONSTANT NUMBER := -20301;
PRODUCT_HAS_SUPPLIER			EXCEPTION;
PRAGMA EXCEPTION_INIT(PRODUCT_HAS_SUPPLIER, -20301);




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
	in_gt_product_type_id	IN gt_product_type.gt_product_type_id%TYPE,
	in_gt_product_range_id	IN gt_product_range.gt_product_range_id%TYPE,
	in_is_sub_product		IN NUMBER,	
	in_min_vol				IN NUMBER,
	in_max_vol				IN NUMBER,
	in_questionnaire_class	IN questionnaire.class_name%TYPE,
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
	in_gt_product_type_id	IN gt_product_type.gt_product_type_id%TYPE,
	in_gt_product_range_id	IN gt_product_range.gt_product_range_id%TYPE,
	in_is_sub_product		IN NUMBER,	
	in_min_vol				IN NUMBER,
	in_max_vol				IN NUMBER,
	in_questionnaire_class	IN questionnaire.class_name%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


END product_search_pkg;
/

