CREATE OR REPLACE PACKAGE CHAIN.purchased_component_pkg
IS

PROCEDURE CheckUniquePurchasedSKU(
	in_component_id			IN  component.component_id%TYPE,
	in_component_code		IN  chain_pkg.T_COMPONENT_CODE
);

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_tag_sids				IN  security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetPurchaseId(
	in_component_id			component.component_id%TYPE,
	in_purchase_order		IN	purchase.purchase_order%TYPE
)RETURN NUMBER;

FUNCTION GetComponentIdByCode(
	in_component_code		IN  component.component_code%TYPE
)RETURN NUMBER;

PROCEDURE GetComponentFromCode (
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
);

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
);

FUNCTION AutoMap (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid				IN security.security_pkg.T_SID_ID
) RETURN product.product_id%TYPE;

FUNCTION TryGetMappedProduct (
	in_component_id			IN  component.component_id%TYPE, --the pc
	in_supplier_sid				IN security.security_pkg.T_SID_ID -- the supplier
) RETURN product.product_id%TYPE;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE GetPurchaseChannels (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePurchase (
	in_purchase_id			IN  purchase.purchase_id%TYPE,
	in_component_id			IN  purchase.component_id%TYPE,
	in_start_date			IN  purchase.start_date%TYPE,
	in_end_date				IN  purchase.end_date%TYPE,
	in_invoice_number		IN  purchase.invoice_number%TYPE,
	in_purchase_order		IN  purchase.purchase_order%TYPE,
	in_note					IN  purchase.note%TYPE,
	in_amount				IN  purchase.amount%TYPE,
	in_amount_unit_id		IN  purchase.amount_unit_id%TYPE,
	in_purchase_channel_id	IN  purchase.purchase_channel_id%TYPE,
	in_tag_sids				IN  security_pkg.T_SID_IDS
);

PROCEDURE SearchPurchases (
	in_component_id		IN	purchase.component_id%TYPE,
	in_start			IN	NUMBER,
	in_count			IN	NUMBER,
	out_total			OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchase (
	in_component_code		IN	component.component_code%TYPE,
	in_start_date			IN	purchase.start_date%TYPE,
	in_end_date				IN	purchase.end_date%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchase (
	in_component_code		IN	component.component_code%TYPE,
	in_purchase_order		IN	purchase.purchase_order%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadPurchases (
	in_component_id		IN	purchase.component_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeletePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_component_id			purchase.component_id%TYPE
);

-- TO DO - this is a temporary procedure to "finish" adding purchases
-- This will be redundant when / if we need to move to a "timeline" model
-- but I need this for demo / reports / at the moment
PROCEDURE SetPurchaseLock (
	in_component_id			component.component_id%TYPE,
	in_purchases_locked		purchased_component.purchases_locked%TYPE
);

FUNCTION AreUnitsMixedForProd	(
	in_component_id			component.component_id%TYPE
) RETURN NUMBER;

PROCEDURE GetSupplierNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

END purchased_component_pkg;
/
