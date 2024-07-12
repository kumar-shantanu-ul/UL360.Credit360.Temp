CREATE OR REPLACE PACKAGE BODY DONATIONS.options_pkg
IS

PROCEDURE GetCustomerOptions (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check for read access on csr root
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading object with sid ' || in_app_sid);
	END IF;

	OPEN out_cur FOR
		SELECT c.app_sid,
			   NVL(co.default_country, 'gb') default_country,
			   NVL(default_currency, 'GBP') default_currency,
			   NVL(default_field, 'cash_value') default_field,
			   NVL(document_description_enabled, 0) document_description_enabled,
			   NVL(is_recipient_tax_id_mandatory, 0) is_recipient_tax_id_mandatory,
			   NVL(is_recipient_address_mandatory, 0) is_recipient_address_mandatory,
			   NVL(co.show_all_years_by_default, 0) show_all_years_by_default,
			   co.fc_tag_id,
			   co.fc_amount_field_lookup_key,
			   co.fc_status_tag_group_sid,
			   co.fc_paid_tag_id,
			   co.fc_reconciled_tag_id,
			   co.fc_being_processed_tag_id,
			   NVL(co.fc_grid_def_sort_column, 'name') fc_grid_def_sort_column
		  FROM customer_options co, csr.customer c
		 WHERE c.app_sid = co.app_sid(+) -- so we get a row with gb defaults 
		   AND c.app_sid = in_app_sid;
END;

END options_pkg;
/



