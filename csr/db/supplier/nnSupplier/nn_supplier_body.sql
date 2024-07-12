CREATE OR REPLACE PACKAGE BODY nn_supplier_pkg
IS

PROCEDURE GetAnswers(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- Check for read access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with SID ' || in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT c.company_sid, manufacturing_cats, notes, document_group_id, other_product_info, c.name company_name
		  FROM nn_supplier_answers sa, company c
		 WHERE c.company_sid = in_company_sid
		   AND sa.company_sid(+) = c.company_sid;
	
END;

PROCEDURE GetAnswersAndAssocProducts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_answers					OUT security_pkg.T_OUTPUT_CUR,
	out_assoc_products			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Get answers (checks security for us)
	GetAnswers(in_act_id, in_company_sid, out_answers);
	
	-- Get associated products
	OPEN out_assoc_products FOR
		SELECT product_id, product_code, description, supplier_company_sid, 
			active, deleted, app_sid
		  FROM product
		 WHERE supplier_company_sid = in_company_sid;
END;


PROCEDURE SetAnswers(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	in_manufacturing_cats		IN nn_supplier_answers.manufacturing_cats%TYPE,
	in_notes					IN nn_supplier_answers.notes%TYPE,
	in_doc_group_id				IN nn_supplier_answers.document_group_id%TYPE,
	in_other_product_info		IN nn_supplier_answers.other_product_info%TYPE
)
AS
	v_doc_group_id				nn_supplier_answers.document_group_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with SID ' || in_company_sid);
	END IF;

	-- -ve document group id maps to null
	v_doc_group_id := in_doc_group_id;
	IF v_doc_group_id < 0 THEN
		v_doc_group_id := NULL;
	END IF;

	BEGIN
		INSERT INTO nn_supplier_answers (company_sid, manufacturing_cats, notes, document_group_id, other_product_info) 
			VALUES (in_company_sid, in_manufacturing_cats, in_notes, v_doc_group_id, in_other_product_info);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN	 
		UPDATE nn_supplier_answers
		SET    manufacturing_cats = in_manufacturing_cats,
		       notes              = in_notes,
		       document_group_id  = v_doc_group_id,
		       other_product_info = in_other_product_info
		WHERE  company_sid        = in_company_sid;
	END;

END;

PROCEDURE GetManufacturingSites(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- Check for read access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with SID ' || in_company_sid);
	END IF;

	OPEN out_cur FOR
    SELECT ms.company_part_id, manufacturer_name, site_address, site_contact_name, 
    	site_contact_number, ms.country_code, cty.country country_name, 
    	employees_at_site, processes_at_site
      FROM company_part cp, nn_manufacturing_site ms, country cty
     WHERE cp.company_sid = in_company_sid
       AND cp.parent_id IS NULL
       AND cp.part_type_id = 6 
       AND ms.company_part_id = cp.company_part_id
       AND cty.country_code = ms.country_code
       	ORDER BY ms.company_part_id ASC;
END;

END nn_supplier_pkg;
/
