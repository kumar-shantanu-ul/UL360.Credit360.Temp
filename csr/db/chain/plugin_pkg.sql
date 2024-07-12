CREATE OR REPLACE PACKAGE  CHAIN.plugin_pkg
IS

PROCEDURE AddCompanyTab(
	in_plugin_id					IN	company_tab.plugin_id%TYPE,
	in_pos							IN	company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_page_company_type_id			IN	company_tab.page_company_type_id%TYPE,
	in_user_company_type_id			IN  company_tab.user_company_type_id%TYPE,	
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE DEFAULT 0,
	in_options						IN  company_tab.options%TYPE DEFAULT NULL,
	in_page_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_flow_capability_id			IN	company_tab.flow_capability_id%TYPE DEFAULT NULL,
	in_bus_rel_type_id				IN	company_tab.business_relationship_type_id%TYPE DEFAULT NULL,
	in_supplier_restriction			IN 	NUMBER DEFAULT 0
);

PROCEDURE AddCompanyHeader(
	in_plugin_id					IN	company_header.plugin_id%TYPE,
	in_pos							IN	company_header.pos%TYPE,
	in_page_company_type_id			IN	company_header.page_company_type_id%TYPE,
	in_user_company_type_id			IN  company_header.user_company_type_id%TYPE,	
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE DEFAULT 0,
	in_page_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL
);

PROCEDURE GetCompanyTabs (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE DEFAULT NULL,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_related_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_tab_comp_type_rl_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyTabs (	
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE,
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE DEFAULT NULL,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_related_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_tab_comp_type_rl_cur	OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION HasCompanyTabs (
	in_company_sid 					IN company.company_sid%TYPE
) RETURN NUMBER;

PROCEDURE GetCompanyTabsForExport (
	out_plugins_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyTab (
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE,
	in_plugin_id					IN  company_tab.plugin_id%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_options						IN  company_tab.options%TYPE,
	in_page_company_col_sid			IN	company_tab.page_company_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	company_tab.user_company_col_sid%TYPE DEFAULT NULL,
	in_flow_capability_id			IN	company_tab.flow_capability_id%TYPE DEFAULT NULL,
	in_bus_rel_type_id				IN	company_tab.business_relationship_type_id%TYPE DEFAULT NULL,
	in_default_saved_filter_sid		IN	company_tab.default_saved_filter_sid%TYPE DEFAULT NULL,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_company_tab_id				IN	company_tab.company_tab_id%TYPE DEFAULT 0,
	in_supplier_restriction			IN 	NUMBER DEFAULT 0,
	in_company_type_role_ids		IN	security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_company_type_is_role_ids		IN	security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyTab (
	in_page_company_type_lookup		IN  company_type.lookup_key%TYPE,
	in_user_company_type_lookup		IN  company_type.lookup_key%TYPE,
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_options						IN  company_tab.options%TYPE,
	in_page_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_flow_capability_id			IN	company_tab.flow_capability_id%TYPE DEFAULT NULL,
	in_bus_rel_type_lookup			IN	business_relationship_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_restriction 		IN  NUMBER DEFAULT 0
);

PROCEDURE RemoveCompanyTab (
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE
);

PROCEDURE GetCompanyHeaders (
	in_company_sid					IN  security_pkg.T_SID_ID,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyHeaders (	
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyHeader (
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE,
	in_plugin_id					IN  company_header.plugin_id%TYPE,
	in_pos							IN  company_header.pos%TYPE,
	in_page_company_col_sid			IN	company_tab.page_company_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	company_tab.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyHeader (
	in_page_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_user_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_viewing_own_company				IN  company_tab.viewing_own_company%TYPE,
	in_js_class							IN  csr.plugin.js_class%TYPE,
	in_form_path						IN  csr.plugin.form_path%TYPE,
	in_group_key						IN  csr.plugin.group_key%TYPE,
	in_pos								IN  company_tab.pos%TYPE,
	in_page_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL
);

PROCEDURE RemoveCompanyHeader (
	in_company_header_id				IN  company_header.company_header_id%TYPE
);

PROCEDURE RemoveCompanyPlugin (	
	in_plugin_id						IN  csr.plugin.plugin_id%TYPE
);

/*
Product procedures
*/
PROCEDURE GetProductHeaders (
	in_product_id					IN  company_product.product_id%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductHeaders (	
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_header.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_header.viewing_as_supplier%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductHeader (
	in_product_header_id			IN  product_header.product_header_id%TYPE,
	in_plugin_id					IN  product_header.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_header.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_header.viewing_as_supplier%TYPE,
	in_pos							IN  product_header.pos%TYPE,
	in_product_col_sid				IN	product_header.product_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	product_header.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductHeader (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE
);

PROCEDURE RemoveProductHeader (
	in_product_header_id			IN  product_header.product_header_id%TYPE
);

PROCEDURE GetProductTabs (
	in_product_id					IN  company_product.product_id%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTabs (	
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductTab (
	in_product_tab_id				IN  product_tab.product_tab_id%TYPE,
	in_plugin_id					IN  product_tab.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_pos							IN  product_tab.pos%TYPE,
	in_label						IN  product_tab.label%TYPE,
	in_product_col_sid				IN	product_tab.product_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	product_tab.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductTab (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE
);

PROCEDURE RemoveProductTab (
	in_product_tab_id			IN  product_tab.product_tab_id%TYPE
);

PROCEDURE GetProductSupplierTabs (
	in_product_id					IN  company_product.product_id%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductSupplierTabs (
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_supplier_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_supplier_tab.viewing_as_supplier%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductSupplierTab (
	in_product_supplier_tab_id		IN  product_supplier_tab.product_supplier_tab_id%TYPE,
	in_plugin_id					IN  product_supplier_tab.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_supplier_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_supplier_tab.viewing_as_supplier%TYPE,
	in_pos							IN  product_supplier_tab.pos%TYPE,
	in_label						IN  product_supplier_tab.label%TYPE,
	in_purchaser_company_col_sid	IN  product_supplier_tab.purchaser_company_col_sid%TYPE,
	in_supplier_company_col_sid		IN  product_supplier_tab.supplier_company_col_sid%TYPE,
	in_user_company_col_sid			IN  product_supplier_tab.user_company_col_sid%TYPE,
	in_product_col_sid				IN  product_supplier_tab.product_col_sid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductSupplierTab (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE,
	in_purchaser_company_col_name	IN	cms.tab_column.oracle_column%TYPE,
	in_supplier_company_col_name		IN	cms.tab_column.oracle_column%TYPE
);

PROCEDURE RemoveProductSupplierTab (
	in_product_supplier_tab_id		IN  product_supplier_tab.product_supplier_tab_id%TYPE
);

PROCEDURE GetProductTabsForExport(
	out_customer_plugins			OUT	security_pkg.T_OUTPUT_CUR,
	out_product_tabs				OUT	security_pkg.T_OUTPUT_CUR,
	out_product_headers				OUT	security_pkg.T_OUTPUT_CUR,
	out_prod_supplier_tabs			OUT	security_pkg.T_OUTPUT_CUR
);


/*
Generic procedures
*/
PROCEDURE RemovePlugin (	
	in_plugin_id						IN  csr.plugin.plugin_id%TYPE
);

END plugin_pkg;
/

