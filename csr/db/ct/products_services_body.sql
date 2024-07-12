CREATE OR REPLACE PACKAGE BODY ct.products_services_pkg AS

PROCEDURE SetItemINTERNAL(
	in_item_id						IN  ps_item.item_id%TYPE,
	in_worksheet_id					IN  ps_item.worksheet_id%TYPE,
	in_row_number					IN  ps_item.row_number%TYPE,
	in_breakdown_id					IN  breakdown_region.breakdown_id%TYPE,
	in_region_id					IN  breakdown_region.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_description					IN	ps_item.description%TYPE,
	in_spend						IN	ps_item.spend%TYPE,
	in_currency_id					IN	ps_item.currency_id%TYPE,
	in_purchase_date				IN	ps_item.purchase_date%TYPE,
	in_auto_eio_id					IN	ps_item.auto_eio_id%TYPE,
	in_auto_eio_id_score			IN	ps_item.auto_eio_id_score%TYPE,
	in_auto_eio_id_two				IN	ps_item.auto_eio_id_two%TYPE,
	in_auto_eio_id_score_two		IN	ps_item.auto_eio_id_score_two%TYPE,
	in_match_auto_accepted			IN	ps_item.match_auto_accepted%TYPE,
	in_from_worksheet				IN  NUMBER,
	out_item_id						OUT	ps_item.item_id%TYPE
)
AS	
	v_worksheet_id					ps_item.worksheet_id%TYPE;
	v_row_number					ps_item.row_number%TYPE;
BEGIN
	
	IF in_item_id IS NULL THEN
		INSERT INTO ps_item (app_sid, company_sid, breakdown_id, region_id, supplier_id, item_id,
							 description, spend, currency_id, purchase_date, worksheet_id, row_number,
							 created_by_sid, created_dtm, modified_by_sid, last_modified_dtm, auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two)
			 VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_id, 
					 in_region_id, in_supplier_id, ps_item_id_seq.NEXTVAL,
					 in_description, in_spend, in_currency_id, in_purchase_date, in_worksheet_id, in_row_number,
					 security_pkg.getSID, SYSDATE, security_pkg.getSID, SYSDATE, in_auto_eio_id, in_auto_eio_id_score, in_auto_eio_id_two, in_auto_eio_id_score_two)
		  RETURNING item_id INTO out_item_id;
	ELSE
		IF in_from_worksheet = 0 THEN
			-- check to see if we're changing any data that's come from an excel worksheet
			BEGIN
				SELECT worksheet_id, row_number
				  INTO v_worksheet_id, v_row_number
				  FROM ps_item
				 WHERE app_sid = security_pkg.getApp
				   AND item_id = in_item_id
				   AND worksheet_id IS NOT NULL
				   AND breakdown_id <> in_breakdown_id
				   AND region_id <> region_id
				   AND supplier_id <> in_supplier_id
				   AND description <> in_description
				   AND spend <> in_spend
				   AND currency_id <> in_currency_id
				   AND purchase_date <> in_purchase_date
				   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN NULL;
			END;

			IF v_worksheet_id IS NOT NULL THEN
				csr.excel_pkg.IgnoreRow(v_worksheet_id, v_row_number);
			END IF;
		END IF;
			   
		UPDATE ps_item
		   SET breakdown_id = in_breakdown_id,
		       region_id = region_id,
			   supplier_id = in_supplier_id,
			   description = in_description,
			   spend = in_spend,
			   currency_id = in_currency_id,
			   purchase_date = in_purchase_date,
			   modified_by_sid = security_pkg.getSID,
			   last_modified_dtm = SYSDATE,  
			   auto_eio_id = in_auto_eio_id, 
			   auto_eio_id_score = in_auto_eio_id_score, 
			   auto_eio_id_two = in_auto_eio_id_two, 
			   auto_eio_id_score_two = in_auto_eio_id_score_two 
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND item_id = in_item_id;
		   
	   out_item_id := in_item_id;
	END IF;
END;



PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	OPEN out_cur FOR
		SELECT breakdown_type_id, period_id, auto_match_thresh
		  FROM ps_options
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE SetOptions(
	in_breakdown_type_id			IN  ps_options.breakdown_type_id%TYPE, 
	in_auto_match_thresh			IN  ps_options.auto_match_thresh%TYPE
)
AS
	v_period_id 					period.period_id%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.ADMIN_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	SELECT period_id INTO v_period_id FROM company WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND app_sid = security_pkg.getApp;
	
	BEGIN
		INSERT INTO ps_options (app_sid, company_sid, breakdown_type_id, period_id, auto_match_thresh)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_type_id, v_period_id, in_auto_match_thresh);
			-- at the moment just use the period ID from the hotspotter			 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ps_options
			   SET 	breakdown_type_id = in_breakdown_type_id, 
					period_id = v_period_id, 
					auto_match_thresh = in_auto_match_thresh
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
	END;
END;

PROCEDURE GetItemSummaries(
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	OPEN out_cur FOR 
		SELECT item.item_id, item.description, item.spend, item.currency_id, currency.description currency_description, 
		       item.purchase_date, item.breakdown_id, item.region_id, item.supplier_id, supplier.name as supplier_name, 
		       supplier.description as supplier_description, item.kg_co2,
		       item.spend_in_company_currency, item.company_currency_id,
			   item.auto_eio_id auto_eio_id_top, item.auto_eio_id_score auto_eio_id_top_score,
		       item.auto_eio_id_two auto_eio_id_next_best,
		       item.auto_eio_id_score_two auto_eio_id_next_best_score, match_auto_accepted
		  FROM v$ps_item item
		  JOIN currency
		    ON item.currency_id = currency.currency_id
		  LEFT JOIN supplier
		    ON item.app_sid = supplier.app_sid
		   AND item.supplier_id = supplier.supplier_id
		 WHERE item.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND item.company_sid = in_company_sid
		   AND item.breakdown_id = in_breakdown_id
		   AND item.region_id = in_region_id
		   AND item.supplier_id = in_supplier_id
	  ORDER BY item.purchase_date, item.description;
END;

PROCEDURE GetItemSummaries(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	OPEN out_cur FOR 
		SELECT item.item_id, item.description, item.spend, item.currency_id, currency.description currency_description,
		       item.purchase_date, item.breakdown_id, item.region_id, item.supplier_id supplier_id,
		       supplier.name as supplier_name, supplier.description as supplier_description, item.kg_co2,
		       item.spend_in_company_currency, item.company_currency_id, 
			   item.auto_eio_id auto_eio_id_top, item.auto_eio_id_score auto_eio_id_top_score,
		       item.auto_eio_id_two auto_eio_id_next_best,
		       item.auto_eio_id_score_two auto_eio_id_next_best_score, match_auto_accepted
		  FROM v$ps_item item
		  JOIN currency
		    ON item.currency_id = currency.currency_id
		  LEFT JOIN supplier
		    ON item.app_sid = supplier.app_sid
		   AND item.supplier_id = supplier.supplier_id
		 WHERE item.app_sid = security_pkg.getApp
		   AND item.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	  ORDER BY item.spend_in_company_currency;
END;

PROCEDURE GetItems(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetItem(NULL, out_cur);
END;

PROCEDURE GetItem(
	in_item_id						IN  ps_item.item_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	OPEN out_cur FOR 
		SELECT item.item_id, item.description, item.spend, item.currency_id, currency.description currency_description, item.purchase_date,
		       item.breakdown_id, item.region_id, item.supplier_id,
		       item.created_dtm created_date, item.last_modified_dtm last_modified_date, item.worksheet_id,
		       ccu.full_name created_by, mcu.full_name last_modified_by, supplier.name as supplier_name, supplier.description as supplier_description,
		       item.spend_in_company_currency, item.company_currency_id, item.kg_co2, item.auto_eio_id auto_eio_id_top,
		       item.auto_eio_id_score auto_eio_id_top_score,
		       item.auto_eio_id_two auto_eio_id_next_best,
		       item.auto_eio_id_score_two auto_eio_id_next_best_score, match_auto_accepted
		  FROM v$ps_item item
		  JOIN currency
		    ON item.currency_id = currency.currency_id
		  LEFT JOIN supplier
		    ON item.app_sid = supplier.app_sid AND item.supplier_id = supplier.supplier_id
		  JOIN csr.csr_user ccu
		    ON item.app_sid = ccu.app_sid AND item.created_by_sid = ccu.csr_user_sid
		  JOIN csr.csr_user mcu
		    ON item.app_sid = mcu.app_sid AND item.created_by_sid = mcu.csr_user_sid
		 WHERE item.app_sid = security_pkg.getApp
		   AND item.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND item.item_id = NVL(in_item_id, item.item_id)
	  ORDER BY item.spend_in_company_currency DESC;
END;

PROCEDURE GetItemEios(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	OPEN out_cur FOR
		SELECT ie.item_id, ie.eio_id, ie.pct, eio.description
		  FROM ps_item_eio ie
		  JOIN eio
		    ON ie.eio_id = eio.eio_id
		 WHERE ie.app_sid = security_pkg.GetApp
		   AND ie.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ie.item_id = in_item_id
	  ORDER BY ie.pct DESC;
END;

PROCEDURE GetSpendBreakdowns(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSpendBreakdown(NULL, NULL, out_cur);
END;

PROCEDURE GetSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	OPEN out_cur FOR
		SELECT breakdown_id, region_id, spend
		  FROM ps_spend_breakdown
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_id = NVL(in_breakdown_id, breakdown_id)
		   AND region_id = NVL(in_region_id, region_id);
	
END;

PROCEDURE SetCo2(
	in_item_id						IN  ps_item.item_id%TYPE,
	in_kg_co2						IN  ps_item.kg_co2%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
		UPDATE ps_item
		   SET kg_co2 = in_kg_co2
		 WHERE app_sid = security_pkg.getApp
		   AND item_id = in_item_id;
END;

PROCEDURE SetItem(
	in_item_id						IN  ps_item.item_id%TYPE,
	in_breakdown_id					IN  breakdown_region.breakdown_id%TYPE,
	in_region_id					IN  breakdown_region.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_description					IN	ps_item.description%TYPE,
	in_spend						IN	ps_item.spend%TYPE,
	in_currency_id					IN	ps_item.currency_id%TYPE,
	in_purchase_date				IN	ps_item.purchase_date%TYPE,
	out_item_id						OUT	ps_item.item_id%TYPE
)
AS	
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	SetItemINTERNAL(in_item_id, null, null, in_breakdown_id, in_region_id, in_supplier_id, in_description, in_spend, in_currency_id, in_purchase_date, null, null, null, null, 0, 0, out_item_id);
END;

PROCEDURE SetItem(
	in_worksheet_id					IN  ps_item.worksheet_id%TYPE,
	in_row_number					IN  ps_item.row_number%TYPE,
	in_breakdown_id					IN  breakdown_region.breakdown_id%TYPE,
	in_region_id					IN  breakdown_region.region_id%TYPE,
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_description					IN	ps_item.description%TYPE,
	in_spend						IN	ps_item.spend%TYPE,
	in_currency_id					IN	ps_item.currency_id%TYPE,
	in_purchase_date				IN	ps_item.purchase_date%TYPE,
	in_auto_eio_id					IN	ps_item.auto_eio_id%TYPE,
	in_auto_eio_id_score			IN	ps_item.auto_eio_id_score%TYPE,
	in_auto_eio_id_two				IN	ps_item.auto_eio_id_two%TYPE,
	in_auto_eio_id_score_two		IN	ps_item.auto_eio_id_score_two%TYPE,
	in_match_auto_accepted			IN	ps_item.match_auto_accepted%TYPE,
	out_item_id						OUT	ps_item.item_id%TYPE
)
AS
	v_item_id						ps_item.item_id%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	BEGIN
		SELECT item_id
		  INTO v_item_id
		  FROM ps_item 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND worksheet_id = in_worksheet_id
		   AND row_number = in_row_number;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN NULL;
	END;	  
	
	SetItemINTERNAL(v_item_id, in_worksheet_id, in_row_number, in_breakdown_id, in_region_id, in_supplier_id, in_description, in_spend, in_currency_id, in_purchase_date, in_auto_eio_id, in_auto_eio_id_score, in_auto_eio_id_two, in_auto_eio_id_score_two, in_match_auto_accepted, 1, out_item_id);
END;

PROCEDURE SetItemEio(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	in_eio_id						IN  ps_item_eio.eio_id%TYPE,	
	in_pct							IN  ps_item_eio.pct%TYPE,
	in_from_worksheet				IN  NUMBER
)
AS
	v_worksheet_id					ps_item.worksheet_id%TYPE;
	v_row_number					ps_item.row_number%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	IF in_from_worksheet = 0 THEN
		-- check to see if we're changing any data that's come from an excel worksheet
		BEGIN
			SELECT worksheet_id, row_number
			  INTO v_worksheet_id, v_row_number
			  FROM ps_item
			 WHERE app_sid = security_pkg.getApp				   
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND item_id = in_item_id
			   AND worksheet_id IS NOT NULL;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN NULL;
		END;

		IF v_worksheet_id IS NOT NULL THEN
			csr.excel_pkg.IgnoreRow(v_worksheet_id, v_row_number);
		END IF;
	END IF;
	
	BEGIN
		INSERT INTO ps_item_eio (app_sid, company_sid, item_id, eio_id, pct)
			 VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_item_id, in_eio_id, in_pct);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN		
			   
		UPDATE ps_item_eio
		   SET pct = in_pct
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND item_id = in_item_id
		   AND eio_id = in_eio_id;
	END;
END;

PROCEDURE SetSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE,
	in_spend						IN  ps_spend_breakdown.spend%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.ADMIN_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	BEGIN
		INSERT INTO ps_spend_breakdown (app_sid, company_sid, breakdown_id, region_id, spend)
			 VALUES	(security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_id, in_region_id, in_spend);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ps_spend_breakdown
			   SET spend = in_spend
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_id = in_breakdown_id 
			   AND region_id = in_region_id;	
	END;
END;

PROCEDURE DeleteItem(
	in_item_id						IN  ps_item.item_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	FOR r in (
		SELECT eio_id
		  FROM ps_item_eio
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND item_id = in_item_id
	) LOOP
		DeleteItemEio(in_item_id, r.eio_id);
	END LOOP;
	
	DELETE FROM ps_item
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND item_id = in_item_id;
END;

PROCEDURE DeleteItemEio(
	in_item_id						IN  ps_item_eio.item_id%TYPE,
	in_eio_id						IN  ps_item_eio.eio_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	DELETE FROM ps_item_eio
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND item_id = in_item_id
	   AND eio_id = in_eio_id;
END;


PROCEDURE GetItemsForBreakdownRegion(
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_from							IN  period.start_date%TYPE,
	in_to							IN  period.end_date%TYPE,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_result_cur FOR
		  SELECT item.item_id, item.description, item.spend, item.supplier_id,		         
			     item.currency_id, item.breakdown_id, item.region_id, item.purchase_date,
			     supplier.name as supplier_name, supplier.description as supplier_description,
			     item.kg_co2, item.auto_eio_id auto_eio_id_top,
		         item.auto_eio_id_score auto_eio_id_top_score,
		         item.auto_eio_id_two auto_eio_id_next_best,
		         item.auto_eio_id_score_two auto_eio_id_next_best_score, match_auto_accepted
		    FROM v$ps_item item
		    LEFT JOIN supplier ON item.app_sid = supplier.app_sid AND item.supplier_id = supplier.supplier_id
		   WHERE ((in_from IS NULL) OR (item.purchase_date>=in_from))
		     AND ((in_to IS NULL) OR (item.purchase_date<=in_to))
			 AND breakdown_id = in_breakdown_id
			 AND region_id = in_region_id
		ORDER BY spend_in_company_currency DESC;
END;


PROCEDURE DeleteSpendBreakdown(
	in_breakdown_id					IN  ps_spend_breakdown.breakdown_id%TYPE,
	in_region_id					IN  ps_spend_breakdown.region_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.ADMIN_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	DELETE FROM ps_spend_breakdown
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND breakdown_id = in_breakdown_id 
	   AND region_id = in_region_id;
END;


PROCEDURE SearchItems(
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_source_id					IN  ps_item.worksheet_id%TYPE,
	in_all_sources					IN  NUMBER,
	in_supplier_id					IN  ps_item.supplier_id%TYPE,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	in_only_show_untagged_eio		IN  NUMBER,
	in_period_id					IN  period.period_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_page							NUMBER(10) DEFAULT in_page;
	v_total_count					NUMBER(10) DEFAULT 0;
	v_total_pages					NUMBER(10) DEFAULT 0;
	v_period_start					period.start_date%TYPE DEFAULT NULL;
	v_period_end					period.end_date%TYPE DEFAULT NULL;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	-- find period start-end
	IF in_period_id IS NOT NULL THEN
		SELECT start_date, end_date
		  INTO v_period_start, v_period_end --eg: 01/01/2012, 01/01/2013
		  FROM period
		 WHERE period_id = in_period_id;
	END IF;	
	
	-- search based on inputs, and put sorted results in temporary table
	INSERT INTO tt_ps_item_search (spend, item_id)
	SELECT spend, item.item_id
	  FROM v$ps_item item
	  LEFT JOIN supplier ON item.app_sid = supplier.app_sid AND item.supplier_id = supplier.supplier_id
	  LEFT JOIN (
		SELECT item_id, count(eio_id) eios
		FROM ct.ps_item_eio
		GROUP BY item_id
	  ) eios
		ON item.item_id = eios.item_id
	 WHERE item.app_sid = security_pkg.getApp
	   AND item.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (LOWER(item.description) LIKE v_search
		OR LOWER(supplier.name) LIKE v_search
		OR LOWER(supplier.description) LIKE v_search)
	   AND (in_supplier_id IS NULL
	    OR item.supplier_id = in_supplier_id)
	   AND breakdown_id = NVL(in_breakdown_id, breakdown_id)
	   AND region_id = NVL(in_region_id, region_id)
	   AND (in_all_sources = 1
		OR (in_all_sources = 0
	   AND DECODE(worksheet_id, in_source_id, 1) = 1))		   
	   AND (in_only_show_untagged_eio = 0
		OR (in_only_show_untagged_eio = 1
	   AND eios.eios IS NULL))
	   AND (v_period_start IS NULL
		OR purchase_date >= v_period_start)	 
	   AND (v_period_end IS NULL
		OR purchase_date < v_period_end)
  ORDER BY spend_in_company_currency DESC;
	  
	-- get total record count/pages
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM tt_ps_item_search;
	  
	SELECT CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END
	  INTO v_total_pages		    
	  FROM tt_ps_item_search;
	
	-- delete any records that aren't between the current pages
	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_ps_item_search
		 WHERE item_id NOT IN (
			SELECT item_id
			  FROM (
				SELECT item_id, rownum rn
				  FROM tt_ps_item_search
			)
			WHERE rn > in_page_size * (v_page - 1)
			  AND rn <= in_page_size * v_page
		 );		 
	END IF;
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count,
		       v_total_pages total_pages
		  FROM dual;

	-- match the paged, sorted results to the relevant tables to return the results
	OPEN out_result_cur FOR
		  SELECT item.item_id, item.description, item.spend, item.supplier_id,		         
			     item.currency_id, item.breakdown_id, item.region_id, item.purchase_date,
			     supplier.name as supplier_name, supplier.description as supplier_description,
			     item.kg_co2, item.auto_eio_id auto_eio_id_top,
		         item.auto_eio_id_score auto_eio_id_top_score,
		         item.auto_eio_id_two auto_eio_id_next_best,
		         item.auto_eio_id_score_two auto_eio_id_next_best_score, match_auto_accepted
		    FROM v$ps_item item
		    LEFT JOIN supplier ON item.app_sid = supplier.app_sid AND item.supplier_id = supplier.supplier_id
		   WHERE item.item_id IN (SELECT item_id FROM tt_ps_item_search)
		ORDER BY spend_in_company_currency DESC;
END;

PROCEDURE ClearEmissionResults(
	in_calculation_source_id	IN ps_calculation_source.calculation_source_id%TYPE
)
AS
BEGIN

	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	DELETE FROM ps_emissions_all
	 WHERE calculation_source_id = in_calculation_source_id 
	   AND app_sid = security_pkg.getApp;
	
END;

PROCEDURE SaveEmissionResult(
    in_breakdown_id 			IN ps_emissions_all.breakdown_id%TYPE,
    in_region_id 				IN ps_emissions_all.region_id%TYPE,
    in_eio_id 					IN ps_emissions_all.eio_id%TYPE,
	in_calculation_source_id	IN ps_calculation_source.calculation_source_id%TYPE,
	in_contribution_source_id	IN ps_calculation_source.calculation_source_id%TYPE,
    in_kg_co2 					IN ps_emissions_all.kg_co2%TYPE
)
AS
BEGIN

	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	DELETE FROM ps_emissions_all
	 WHERE breakdown_id = in_breakdown_id
	   AND region_id = in_region_id
	   AND calculation_source_id = in_calculation_source_id
	   AND contribution_source_id = in_contribution_source_id
	   AND eio_id = in_eio_id
	   AND app_sid = security_pkg.GetApp;


	INSERT INTO ps_emissions_all
	(
		breakdown_id,
		region_id,
		eio_id, 
		calculation_source_id,
		contribution_source_id,
		kg_co2
	)VALUES
	(
		in_breakdown_id,
		in_region_id,
		in_eio_id,
		in_calculation_source_id,
		in_contribution_source_id,
		in_kg_co2
	);

	
END;

PROCEDURE GetEmissionResults(
	in_calculation_source_id		IN ps_calculation_source.calculation_source_id%TYPE, 
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	OPEN out_cur FOR
		SELECT pse.breakdown_id, pse.region_id, calculation_source_id, pse.eio_id, kg_co2, pct eio_pct
		  FROM v$ps_emissions pse
		  JOIN breakdown_region_eio bre ON pse.breakdown_id = bre.breakdown_id AND pse.region_id = bre.region_id AND pse.eio_id = bre.eio_id AND pse.app_sid = bre.app_sid
		 WHERE calculation_source_id = in_calculation_source_id
		   AND pse.app_sid = security_pkg.getApp;
	
END;


PROCEDURE ConfirmFirstAutomatchEio (
	in_item_id						IN ps_item.item_id%TYPE
)
AS 
	v_auto_eio_id					ps_item.auto_eio_id%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	SELECT auto_eio_id
	  INTO v_auto_eio_id
	  FROM ps_item
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   AND app_sid = security_pkg.getApp
	   AND item_id = in_item_id;
	   
	IF v_auto_eio_id IS NOT NULL THEN
		DELETE FROM ps_item_eio
		      WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
		        AND app_sid = security_pkg.getApp
		        AND item_id = in_item_id;
		
		INSERT INTO ps_item_eio (app_sid, company_sid, item_id, eio_id, pct)
			VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') , in_item_id, v_auto_eio_id, 100);
	END IF;	
END;

PROCEDURE GetEIOForSupplier(
	in_supplier_id		IN  ps_calculation_source.calculation_source_id%TYPE, 
	out_eio_id			OUT company.eio_id%TYPE
)
AS 
BEGIN
	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	SELECT NVL(c.eio_id, -1) eio_id
	  INTO out_eio_id
	  FROM supplier s
	  LEFT JOIN company c ON s.company_sid = c.company_sid AND s.app_sid = c.app_sid
	 WHERE s.supplier_id = in_supplier_id
	   AND s.app_sid = security_pkg.getApp;
	   
END;

END  products_services_pkg;
/
