CREATE OR REPLACE PACKAGE ct.supplier_pkg AS

FUNCTION SaveSupplier(
	in_supplier_id					IN	supplier.supplier_id%TYPE,
	in_name							IN	supplier.name%TYPE
) RETURN NUMBER;

FUNCTION SaveSupplier (
	in_supplier_id					IN	supplier.supplier_id%TYPE,
	in_name							IN	supplier.name%TYPE,
	in_description					IN	supplier.description%TYPE,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER;

PROCEDURE SaveSupplierContact (
	in_supplier_id					IN	supplier_contact.supplier_id%TYPE,
	in_full_name					IN	supplier_contact.full_name%TYPE,
	in_email						IN	supplier_contact.email%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION SaveSupplierContact (
	in_supplier_id					IN	supplier_contact.supplier_id%TYPE,
	in_full_name					IN	supplier_contact.full_name%TYPE,
	in_email						IN	supplier_contact.email%TYPE
) RETURN NUMBER;

PROCEDURE GetSuppliers (
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplier (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers (
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierAsCompany (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_country_code					IN  chain.company.country_code%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierContactAsUser (
	in_supplier_contact_id			IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierContacts (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierContact (
	in_supplier_contact_id			IN  supplier_contact.supplier_contact_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetSupplierStatus (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_status_id				IN supplier_status.status_id%TYPE
);

END supplier_pkg;
/
