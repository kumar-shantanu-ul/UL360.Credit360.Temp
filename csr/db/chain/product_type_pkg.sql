CREATE OR REPLACE PACKAGE CHAIN.product_type_pkg
IS

PRODUCT_TYPE_LEAF			CONSTANT NUMBER(1) := 0;
PRODUCT_TYPE_FOLDER			CONSTANT NUMBER(1) := 1;
DEFAULT_ROOT_DESCRIPTION	VARCHAR(14) := 'Product types';


FUNCTION GetRootProductType
RETURN product_type.product_type_id%TYPE;

FUNCTION CreateRootProductType
RETURN product_type.product_type_id%TYPE;

PROCEDURE AddProductType (
	in_parent_product_type_id	IN	product_type.parent_product_type_id%TYPE,
	in_description				IN	product_type_tr.description%TYPE,
	in_lookup_key				IN	product_type.lookup_key%TYPE DEFAULT NULL,
	in_node_type				IN	product_type.node_type%TYPE DEFAULT product_type_pkg.PRODUCT_TYPE_LEAF,
	in_active					IN	product_type.active%TYPE DEFAULT 1,
	out_product_type_id			OUT	product_type.product_type_id%TYPE
);

PROCEDURE DeleteProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE
);

PROCEDURE RenameProductType (
	in_product_type_id		   	IN	product_type.product_type_id%TYPE,
	in_description 				IN	product_type_tr.description%TYPE
);

PROCEDURE MoveProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE,
	in_new_parent_id			IN	product_type.product_type_id%TYPE
);

PROCEDURE AmendProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE,
	in_description				IN	product_type_tr.description%TYPE,
	in_lookup_key				IN	product_type.lookup_key%TYPE,
	in_node_type				IN	product_type.node_type%TYPE,
	in_active					IN	product_type.active%TYPE
);

PROCEDURE ActivateProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE
);

PROCEDURE DeactivateProductType (
	in_product_type_id			IN	product_type.product_type_id%TYPE
);


-- Tree functions

PROCEDURE GetTreeWithDepth(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	in_include_root					IN	NUMBER DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithSelect(
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTextFiltered(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetList(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTextFiltered(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_leaf_nodes			IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderChildren(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE ExportProductTypes(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetProductTypes(
	in_node_type			IN	NUMBER DEFAULT NULL,
	in_include_inactive		IN	NUMBER DEFAULT 1,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetProductType(
	in_product_type_id		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllTranslations(
	in_root_product_type_id	IN	product_type.product_type_id%TYPE,
	in_validation_lang		IN	product_type_tr.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTranslations(
	in_product_type_ids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	product_type_tr.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetTranslation(
	in_product_type_id	IN	product_type.product_type_id%TYPE,
	in_lang				IN	product_type_tr.LANG%TYPE,
	in_translated		IN	VARCHAR2
);

PROCEDURE TryGetTypeFromDescription(
	in_description		IN product_type_tr.description%TYPE,
	out_product_type_id	OUT product_type.product_type_id%TYPE
);

PROCEDURE TryGetTypeFromLookupKey(
	in_lookup_key		IN product_type.lookup_key%TYPE,
	out_product_type_id	OUT product_type.product_type_id%TYPE
);

PROCEDURE ConfirmProductTypeIdExists(
	in_product_type_id		IN product_type.product_type_id%TYPE,
	out_product_type_id		OUT product_type.product_type_id%TYPE
);

END product_type_pkg;
/
