CREATE OR REPLACE PACKAGE CSR.utility_pkg IS

PROCEDURE SearchForContract(
	in_text				IN	VARCHAR2,
	in_start_row	    IN	NUMBER,
	in_end_row		    IN	NUMBER,
	in_sort_by		    IN	VARCHAR2,
	in_sort_dir		    IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE
);

PROCEDURE SaveSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	in_name					IN	utility_supplier.supplier_name%TYPE,
	in_contact				IN	utility_supplier.contact_details%TYPE,
	out_id					OUT	utility_supplier.utility_supplier_id%TYPE
);

PROCEDURE GetContract(
	in_contract_id			IN utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSuppliers (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContracts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContractsForSupplier (
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetMeterContract (
	in_meter_sid			IN	security_pkg.T_SID_ID,
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
);

PROCEDURE SaveContract(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	in_account_ref			IN	utility_contract.account_ref%TYPE,
	in_from_dtm				IN	utility_contract.from_dtm%TYPE,
	in_to_dtm				IN	utility_contract.to_dtm%TYPE,
	in_alert_due			IN	utility_contract.alert_when_due%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_delete_file			IN	NUMBER,
	out_id					OUT	utility_contract.utility_contract_id%TYPE
);

PROCEDURE DeleteContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
);

PROCEDURE GetInvoicesForContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvoices (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvoices (
	in_start_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_end_dtm				IN	utility_invoice.invoice_dtm%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchInvoices (
	in_search				IN	VARCHAR2,
	in_unverified_only		IN	NUMBER,
	in_start_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_end_dtm				IN	utility_invoice.invoice_dtm%TYPE,
	in_start_row			IN  NUMBER,
	in_end_row				IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAssocMetersForContract(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContractDocData(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveIvoiceFromReading(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE
);

PROCEDURE SaveInvoice(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_reference			IN	utility_invoice.reference%TYPE,
	in_invoice_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_cost_value			IN	utility_invoice.cost_value%TYPE,
	in_cost_measure_sid		IN	security_pkg.T_SID_ID,
	in_cost_conv_id			IN	utility_invoice.cost_conv_id%TYPE,
	in_consumption			IN	utility_invoice.consumption%TYPE,
	in_cons_measure_sid		IN	security_pkg.T_SID_ID,
	in_cons_conv_id			IN	utility_invoice.consumption_conv_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_delete_file			IN	NUMBER,
	out_id					OUT	utility_invoice.utility_invoice_id%TYPE
);

PROCEDURE GetInvoiceDocData(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteInvoice (
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE
);

PROCEDURE AssociateMetersWithContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveAssociationWithContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetInvoice (
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAssocMetersForInvoice(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


FUNCTION GetPropRegionSid(
	in_child_region			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
;

FUNCTION GetAgentRegionSid(
	in_child_region			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
;

FUNCTION GetPropRegionSidFromContractId (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
) RETURN security_pkg.T_SID_ID
;

PROCEDURE GetInvoiceDateRange(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterReadingsForInvoice (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvoiceVerificationData (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE,
	out_invoice			OUT security_pkg.T_OUTPUT_CUR,
	out_readings		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE VerifyInvoice (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE
);

FUNCTION LastInvoiceVerified(
	in_region_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetInvoiceFields (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvoiceFields (
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvoiceFieldsForReading (
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveInvoiceField (
	in_field_id				IN	utility_invoice_field_val.field_id%TYPE,
	in_invoice_id			IN	utility_invoice_field_val.utility_invoice_id%TYPE,
	in_conversion_id		IN	utility_invoice_field_val.measure_conversion_id%TYPE,
	in_val					IN	utility_invoice_field_val.val%TYPE
);

PROCEDURE SaveFieldForReading (
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	in_field_id				IN	utility_invoice_field_val.field_id%TYPE,
	in_conversion_id		IN	utility_invoice_field_val.measure_conversion_id%TYPE,
	in_val					IN	utility_invoice_field_val.val%TYPE
);

END utility_pkg;
/
