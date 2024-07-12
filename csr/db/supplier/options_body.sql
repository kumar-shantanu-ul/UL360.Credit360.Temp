CREATE OR REPLACE PACKAGE BODY SUPPLIER.options_pkg
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
		SELECT app_sid, 
			search_product_url, edit_product_url, edit_supplier_url, edit_user_url,
			supplier_cat_form_class, product_cat_form_class,
			quest_product_url, quest_supplier_url, user_work_filter 
		  FROM customer_options
		 WHERE app_sid = in_app_sid;
END;

END options_pkg;
/



