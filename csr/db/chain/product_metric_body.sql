CREATE OR REPLACE PACKAGE BODY CHAIN.product_metric_pkg AS

K_COMPANY					CONSTANT NUMBER := 0;
K_PRODUCT					CONSTANT NUMBER := 1;
K_SUPPLIER					CONSTANT NUMBER := 2;

PROCEDURE GetProductMetricIcons(
	out_cur						out		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT product_metric_icon_id,
			   description,
			   icon_path
		  FROM product_metric_icon;
END;

PROCEDURE GetProductMetrics(
	in_product_type_id			IN		product_metric_product_type.product_type_id%TYPE,
	out_cur						out		security_pkg.T_OUTPUT_CUR,
	out_product_types_cur		out		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pmi.ind_sid, 
			   i.description,
			   pmi.applies_to_product,
			   pmi.applies_to_prod_supplier,
			   pmi.product_metric_icon_id,
			   pmi.is_mandatory,
			   pmi.show_measure,
			   i.lookup_key
		  FROM product_metric pmi
		  JOIN csr.v$ind i ON i.ind_sid = pmi.ind_sid
		 WHERE in_product_type_id IS NULL OR EXISTS (
				SELECT NULL
				  FROM product_metric_product_type pmpt
				  JOIN (
						SELECT pt.product_type_id
						  FROM product_type pt
						 START WITH pt.product_type_id = in_product_type_id
					   CONNECT BY PRIOR pt.parent_product_type_id = pt.product_type_id
				  ) pt_tree ON pt_tree.product_type_id = pmpt.product_type_id
				 WHERE pmpt.ind_sid = pmi.ind_sid
			 )
		 ORDER BY LOWER(i.description), pmi.ind_sid;
	
	OPEN out_product_types_cur FOR
		SELECT product_type_id,
			   ind_sid
		  FROM product_metric_product_type;
END;

PROCEDURE SaveProductMetric(
	in_ind_sid					IN	product_metric.ind_sid%TYPE,
	in_applies_to_product		IN	product_metric.applies_to_product%TYPE,
	in_applies_to_prod_supplier	IN	product_metric.applies_to_prod_supplier%TYPE,
	in_product_metric_icon_id	IN	product_metric.product_metric_icon_id%TYPE,
	in_is_mandatory				IN	product_metric.is_mandatory%TYPE,
	in_show_measure				IN	product_metric.show_measure%TYPE,
	in_product_types			IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_records_count				NUMBER;
	v_product_types				security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit product metrics');
	END IF;
	
	v_product_types := security_pkg.SidArrayToTable(in_product_types);

	IF v_product_types.COUNT = 0 THEN
		v_product_types.EXTEND;
		v_product_types(1) := product_type_pkg.GetRootProductType();
	END IF;
	
	SELECT COUNT(ind_sid) INTO v_records_count
		FROM product_metric
		WHERE ind_sid = in_ind_sid;

	-- if records count is 0 this is new metric
	IF v_records_count = 0 THEN
		BEGIN
			INSERT INTO product_metric(ind_sid, applies_to_product, applies_to_prod_supplier, product_metric_icon_id, is_mandatory, show_measure) 
				 VALUES (in_ind_sid, in_applies_to_product, in_applies_to_prod_supplier, in_product_metric_icon_id, in_is_mandatory, in_show_measure);
		END;
	ELSE
		BEGIN
			UPDATE product_metric 
			   SET applies_to_product = in_applies_to_product,
			       applies_to_prod_supplier = in_applies_to_prod_supplier,
				   product_metric_icon_id = in_product_metric_icon_id,
				   is_mandatory = in_is_mandatory,
				   show_measure = in_show_measure
			 WHERE ind_sid = in_ind_sid;
		END;
	END IF;
	

	DELETE FROM chain.product_metric_product_type
	 WHERE ind_sid = in_ind_sid
	   AND product_type_id NOT IN (SELECT column_value FROM TABLE(v_product_types));
	
	INSERT INTO chain.product_metric_product_type (product_type_id, ind_sid)
	SELECT t.column_value product_type_id,
		   in_ind_sid ind_sid
	  FROM TABLE(v_product_types) t
	 WHERE t.column_value NOT IN (SELECT product_type_id FROM chain.product_metric_product_type WHERE ind_sid = in_ind_sid);
	
	-- Output cursors
	OPEN out_cur FOR
		SELECT  pmi.ind_sid, 
				i.description,
				pmi.applies_to_product,
				pmi.applies_to_prod_supplier,
				pmi.product_metric_icon_id,
				pmi.is_mandatory,
				pmi.show_measure
		  FROM product_metric pmi
		  JOIN csr.v$ind i ON i.ind_sid = pmi.ind_sid
		 WHERE pmi.ind_sid = in_ind_sid;

	OPEN out_product_types_cur FOR
		SELECT product_type_id,
			   ind_sid
		  FROM product_metric_product_type
		 WHERE ind_sid = in_ind_sid;			
END;

PROCEDURE GetProductMetricCalcs(
	out_cur						out		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pmc.product_metric_calc_id,
			   pmc.destination_ind_sid, di.description destination_ind_desc,
			   pmc.applies_to_products, pmc.applies_to_product_companies,
			   pmc.applies_to_product_suppliers, pmc.applies_to_prod_sup_purchasers, pmc.applies_to_prod_sup_suppliers,
			   pmc.calc_type, pmc.operator, pmc.source_argument_2, pmc.user_values_only,
			   pmc.source_ind_sid_1, si1.description source_ind_desc_1,
			   pmc.source_ind_sid_2, si2.description source_ind_desc_2
		  FROM product_metric_calc pmc
		  JOIN csr.v$ind di ON di.ind_sid = pmc.destination_ind_sid
		  LEFT JOIN csr.v$ind si1 ON si1.ind_sid = pmc.source_ind_sid_1
		  LEFT JOIN csr.v$ind si2 ON si2.ind_sid = pmc.source_ind_sid_2
		 ORDER BY di.description,
			   pmc.applies_to_products DESC,
			   applies_to_product_companies DESC,
			   pmc.applies_to_product_suppliers DESC,
			   applies_to_prod_sup_purchasers DESC,
			   pmc.applies_to_prod_sup_suppliers DESC;
END;

PROCEDURE SaveProductMetricCalc(
	in_product_metric_calc_id	IN	product_metric_calc.product_metric_calc_id%TYPE,
	in_destination_ind_sid		IN	product_metric_calc.destination_ind_sid%TYPE,
	in_applies_to_products		IN	product_metric_calc.applies_to_products%TYPE,
	in_applies_to_prod_comps	IN	product_metric_calc.applies_to_product_companies%TYPE,
	in_applies_to_prod_supps	IN	product_metric_calc.applies_to_product_suppliers%TYPE,
	in_applies_to_ps_purchasers	IN	product_metric_calc.applies_to_prod_sup_purchasers%TYPE,
	in_applies_to_ps_suppliers	IN	product_metric_calc.applies_to_prod_sup_suppliers%TYPE,
	in_calc_type				IN	product_metric_calc.calc_type%TYPE,
	in_operator					IN	product_metric_calc.operator%TYPE,
	in_source_ind_sid_1			IN	product_metric_calc.source_ind_sid_1%TYPE,
	in_source_ind_sid_2			IN	product_metric_calc.source_ind_sid_2%TYPE,
	in_source_argument_2		IN	product_metric_calc.source_argument_2%TYPE,
	in_user_values_only			IN	product_metric_calc.user_values_only%TYPE,
	out_cur						out	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_metric_calc_id	product_metric_calc.product_metric_calc_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit product metrics');
	END IF;

	IF in_product_metric_calc_id IS NULL THEN
		INSERT INTO product_metric_calc (
			product_metric_calc_id, destination_ind_sid, 
			applies_to_products, applies_to_product_companies,
			applies_to_product_suppliers, applies_to_prod_sup_purchasers, applies_to_prod_sup_suppliers,
			calc_type, operator, source_ind_sid_1, source_ind_sid_2, source_argument_2, user_values_only
		) VALUES (
			product_metric_calc_id_seq.NEXTVAL, in_destination_ind_sid,
			in_applies_to_products, in_applies_to_prod_comps,
			in_applies_to_prod_supps, in_applies_to_ps_purchasers, in_applies_to_ps_suppliers,
			in_calc_type, in_operator, in_source_ind_sid_1, in_source_ind_sid_2, in_source_argument_2, in_user_values_only
		) RETURNING product_metric_calc_id INTO v_product_metric_calc_id;
	ELSE
		UPDATE product_metric_calc
		   SET applies_to_products = in_applies_to_products,
			   applies_to_product_companies = in_applies_to_prod_comps,
			   applies_to_product_suppliers = in_applies_to_prod_supps,
			   applies_to_prod_sup_purchasers = in_applies_to_ps_purchasers,
			   applies_to_prod_sup_suppliers = in_applies_to_ps_suppliers,
			   calc_type = in_calc_type,
			   operator = in_operator,
			   source_ind_sid_1 = in_source_ind_sid_1,
			   source_ind_sid_2 = in_source_ind_sid_2,
			   source_argument_2 = in_source_argument_2,
			   user_values_only = in_user_values_only
		 WHERE product_metric_calc_id = in_product_metric_calc_id;

		 v_product_metric_calc_id := in_product_metric_calc_id;
	END IF;

	OPEN out_cur FOR
		SELECT pmc.product_metric_calc_id,
			   pmc.destination_ind_sid, di.description destination_ind_desc,
			   pmc.applies_to_products, pmc.applies_to_product_companies,
			   pmc.applies_to_product_suppliers, pmc.applies_to_prod_sup_purchasers, pmc.applies_to_prod_sup_suppliers,
			   pmc.calc_type, pmc.operator, pmc.source_argument_2, pmc.user_values_only,
			   pmc.source_ind_sid_1, si1.description source_ind_desc_1,
			   pmc.source_ind_sid_2, si2.description source_ind_desc_2
		  FROM product_metric_calc pmc
		  JOIN csr.v$ind di ON di.ind_sid = pmc.destination_ind_sid
		  LEFT JOIN csr.v$ind si1 ON si1.ind_sid = pmc.source_ind_sid_1
		  LEFT JOIN csr.v$ind si2 ON si2.ind_sid = pmc.source_ind_sid_2
		 WHERE product_metric_calc_id = v_product_metric_calc_id;
END;

PROCEDURE DeleteProductMetricCalc(
	in_product_metric_calc_id	IN	product_metric_calc.product_metric_calc_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit product metrics');
	END IF;

	DELETE FROM product_metric_calc
	 WHERE product_metric_calc_id = in_product_metric_calc_id;
END;

PROCEDURE Internal_SetProductMetric(
	in_product_id				IN	product_metric_val.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE,
	in_val						IN	product_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_metric_val.note%TYPE,
	in_source_type				IN	product_metric_val.source_type%TYPE,
	in_propagate_scores			IN	NUMBER
);

PROCEDURE Internal_SetProdSupMetric(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE,
	in_val						IN	product_supplier_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_supplier_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_supplier_metric_val.note%TYPE,
	in_source_type				IN	product_supplier_metric_val.source_type%TYPE,
	in_propagate_scores			IN	NUMBER
);

PROCEDURE Internal_RecalcCompMetric(
	in_company_sid				IN	company_product.company_sid%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE
)
AS
	v_applies_to_prod_companies	product_metric_calc.applies_to_product_companies%TYPE;
	v_applies_to_ps_purchasers	product_metric_calc.applies_to_prod_sup_purchasers%TYPE;
	v_applies_to_ps_suppliers	product_metric_calc.applies_to_prod_sup_suppliers%TYPE;
	v_calc_type					product_metric_calc.calc_type%TYPE;
	v_operator					product_metric_calc.operator%TYPE;
	v_source_ind_sid_1			product_metric_calc.source_ind_sid_1%TYPE;
	v_source_argument_1			product_metric_val.val_number%TYPE;
	v_source_ind_sid_2			product_metric_calc.source_ind_sid_2%TYPE;
	v_source_argument_2			product_metric_val.val_number%TYPE;
	v_user_values_only			product_metric_calc.user_values_only%TYPE;
	v_result					product_metric_val.val_number%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
	v_val_id					NUMBER(20);
	v_file_uploads				security_pkg.T_SID_IDS; -- empty
BEGIN
	SELECT applies_to_product_companies, applies_to_prod_sup_purchasers, applies_to_prod_sup_suppliers,
		   calc_type, operator, source_ind_sid_1, source_ind_sid_2, user_values_only
	  INTO v_applies_to_prod_companies, v_applies_to_ps_purchasers, v_applies_to_ps_suppliers,
		   v_calc_type, v_operator, v_source_ind_sid_1, v_source_ind_sid_2, v_user_values_only
	  FROM product_metric_calc
	 WHERE destination_ind_sid = in_ind_sid
	   AND (applies_to_product_companies = 1 OR applies_to_prod_sup_purchasers = 1 OR applies_to_prod_sup_suppliers = 1);
	   
	-- Since we've bucketed the values, we only need to look up start dates.

	IF v_applies_to_prod_companies = 1 THEN

		IF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG THEN
		
			SELECT CASE v_operator
				   WHEN 'count'	THEN COUNT(pmv.val_number)
				   WHEN 'sum'	THEN SUM(pmv.val_number)
				   WHEN 'min'	THEN MIN(pmv.val_number)
				   WHEN 'max'	THEN MAX(pmv.val_number)
				   WHEN 'avg'	THEN AVG(pmv.val_number)
			   END INTO v_result
			  FROM company_product cp
			  JOIN product_metric_val pmv ON pmv.product_id = cp.product_id
			 WHERE cp.company_sid = in_company_sid
			   AND cp.is_active = chain_pkg.ACTIVE
			   AND (pmv.ind_sid = v_source_ind_sid_1 OR pmv.ind_sid = v_source_ind_sid_2)
			   AND pmv.start_dtm = in_start_date
			   AND (v_user_values_only = 0 OR pmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);

		ELSIF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG THEN
	
			SELECT CASE v_operator
				   WHEN 'count'	THEN COUNT(val_number)
				   WHEN 'sum'	THEN SUM(val_number)
				   WHEN 'min'	THEN MIN(val_number)
				   WHEN 'max'	THEN MAX(val_number)
				   WHEN 'avg'	THEN AVG(val_number)
			   END INTO v_result
			  FROM (
					SELECT pmv.val_number, pmv.source_type
					  FROM company_product cp
					  JOIN product_metric_val pmv ON pmv.product_id = cp.product_id
					 WHERE cp.company_sid = in_company_sid
					   AND cp.is_active = chain_pkg.ACTIVE
					   AND (pmv.ind_sid = v_source_ind_sid_1 OR pmv.ind_sid = v_source_ind_sid_2)
					   AND pmv.start_dtm = in_start_date
					   AND (v_user_values_only = 0 OR pmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER)
					 UNION ALL
					SELECT psmv.val_number, psmv.source_type
					  FROM company_product cp
					  JOIN product_supplier ps ON ps.product_id = cp.product_id
					  JOIN product_supplier_metric_val psmv ON psmv.product_supplier_id = ps.product_supplier_id
					 WHERE cp.company_sid = in_company_sid
					   AND cp.is_active = chain_pkg.ACTIVE
					   AND ps.is_active = chain_pkg.ACTIVE
					   AND (psmv.ind_sid = v_source_ind_sid_1 OR psmv.ind_sid = v_source_ind_sid_2)
					   AND psmv.start_dtm = in_start_date
					   AND (v_user_values_only = 0 OR psmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER)
			  );

		ELSE

			RAISE_APPLICATION_ERROR(-20001, 'Product metric calculation type ' || v_calc_type || ' is not supported for product companies');

		END IF;

	ELSE
	
		IF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG THEN
		
			SELECT CASE v_operator
				   WHEN 'count'		THEN COUNT(psmv.val_number)
				   WHEN 'sum'		THEN SUM(psmv.val_number)
				   WHEN 'min'		THEN MIN(psmv.val_number)
				   WHEN 'max'		THEN MAX(psmv.val_number)
				   WHEN 'avg'		THEN AVG(psmv.val_number)
			   END INTO v_result
			  FROM product_supplier ps
			  JOIN product_supplier_metric_val psmv ON psmv.product_supplier_id = ps.product_supplier_id
			 WHERE ((
						v_applies_to_ps_purchasers = 1 AND ps.purchaser_company_sid = in_company_sid
				   ) OR (
						v_applies_to_ps_suppliers = 1 AND ps.supplier_company_sid = in_company_sid
				   ))
				   AND ps.is_active = chain_pkg.ACTIVE
				   AND (psmv.ind_sid = v_source_ind_sid_1 OR psmv.ind_sid = v_source_ind_sid_2)
				   AND psmv.start_dtm = in_start_date
				   AND (v_user_values_only = 0 OR psmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);

		ELSE

			RAISE_APPLICATION_ERROR(-20001, 'Product metric calculation type ' || v_calc_type || ' is not supported for product supplier companies');

		END IF;

	END IF;

	v_region_sid := csr.supplier_pkg.GetRegionSid(in_company_sid);

	csr.indicator_pkg.SetValueWithReasonWithSid(
		in_user_sid				=> security_pkg.GetSid,
		in_ind_sid				=> in_ind_sid,
		in_region_sid			=> v_region_sid,
		in_period_start			=> in_start_date,
		in_period_end			=> in_end_date,
		in_val_number			=> v_result,
		in_flags				=> 0,
		in_source_type_id		=> csr.csr_data_pkg.SOURCE_TYPE_CHAIN_PRD_MET_CALC,
		in_entry_conversion_id	=> NULL,
		in_entry_val_number		=> v_result,
		in_note					=> NULL,
		in_reason				=> 'Product metric calc',
		in_have_file_uploads	=> 0,
		in_file_uploads			=> v_file_uploads,
		out_val_id				=> v_val_id
	);
	
	csr.calc_pkg.AddJobsForVal(
		in_ind_sid,	
		v_region_sid,
		in_start_date,
		in_end_date
	);	
END;

PROCEDURE Internal_RecalcProdMetric(
	in_product_id				IN	company_product.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE
)
AS
	v_calc_type					product_metric_calc.calc_type%TYPE;
	v_operator					product_metric_calc.operator%TYPE;
	v_source_ind_sid_1			product_metric_calc.source_ind_sid_1%TYPE;
	v_source_argument_1			product_metric_val.val_number%TYPE;
	v_source_ind_sid_2			product_metric_calc.source_ind_sid_2%TYPE;
	v_source_argument_2			product_metric_val.val_number%TYPE;
	v_user_values_only			product_metric_calc.user_values_only%TYPE;
	v_result					product_metric_val.val_number%TYPE;
BEGIN
	SELECT calc_type, operator, source_ind_sid_1, source_ind_sid_2, source_argument_2, user_values_only
	  INTO v_calc_type, v_operator, v_source_ind_sid_1, v_source_ind_sid_2, v_source_argument_2, v_user_values_only
	  FROM product_metric_calc
	 WHERE destination_ind_sid = in_ind_sid
	   AND applies_to_products = 1;

	-- Since we've bucketed the values, we only need to look up start dates.

	IF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC THEN
		
		BEGIN
			SELECT val_number
			  INTO v_source_argument_1
			  FROM product_metric_val
			 WHERE product_id = in_product_id
			   AND ind_sid = v_source_ind_sid_1
			   AND start_dtm = in_start_date;
		EXCEPTION
			WHEN no_data_found THEN
				v_source_argument_2 := NULL;
		END;

		IF v_source_ind_sid_2 IS NOT NULL THEN
			BEGIN
				SELECT val_number
				  INTO v_source_argument_2
				  FROM product_metric_val
				 WHERE product_id = in_product_id
				   AND ind_sid = v_source_ind_sid_2
				   AND start_dtm = in_start_date;
			EXCEPTION
				WHEN no_data_found THEN
					v_source_argument_2 := NULL;
			END;
		END IF;

		BEGIN
			v_result := CASE v_operator
				WHEN '+' THEN v_source_argument_1 + v_source_argument_2
				WHEN '-' THEN v_source_argument_1 - v_source_argument_2
				WHEN '*' THEN v_source_argument_1 * v_source_argument_2
				WHEN '/' THEN v_source_argument_1 / v_source_argument_2
			END;
		EXCEPTION
			WHEN value_error THEN
				v_result := NULL;
			WHEN zero_divide THEN
				v_result := NULL;
		END;

	ELSIF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG THEN
		
		SELECT CASE v_operator
			   WHEN 'count'		THEN COUNT(psmv.val_number)
			   WHEN 'sum'		THEN SUM(psmv.val_number)
			   WHEN 'min'		THEN MIN(psmv.val_number)
			   WHEN 'max'		THEN MAX(psmv.val_number)
			   WHEN 'avg'		THEN AVG(psmv.val_number)
		   END INTO v_result
		  FROM company_product cp
		  JOIN product_supplier ps ON ps.product_id = cp.product_id AND ps.purchaser_company_sid = cp.company_sid
		  JOIN product_supplier_metric_val psmv ON psmv.product_supplier_id = ps.product_supplier_id
		 WHERE cp.product_id = in_product_id
		   AND ps.is_active = chain_pkg.ACTIVE
		   AND (psmv.ind_sid = v_source_ind_sid_1 OR psmv.ind_sid = v_source_ind_sid_2)
		   AND psmv.start_dtm = in_start_date
		   AND (v_user_values_only = 0 OR psmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);

	ELSIF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG THEN
		
		SELECT CASE v_operator
			   WHEN 'count'		THEN COUNT(psmv.val_number)
			   WHEN 'sum'		THEN SUM(psmv.val_number)
			   WHEN 'min'		THEN MIN(psmv.val_number)
			   WHEN 'max'		THEN MAX(psmv.val_number)
			   WHEN 'avg'		THEN AVG(psmv.val_number)
		   END INTO v_result
		  FROM company_product cp
		  JOIN product_supplier ps ON ps.product_id = cp.product_id
		  JOIN product_supplier_metric_val psmv ON psmv.product_supplier_id = ps.product_supplier_id
		 WHERE cp.product_id = in_product_id
		   AND ps.is_active = chain_pkg.ACTIVE
		   AND (psmv.ind_sid = v_source_ind_sid_1 OR psmv.ind_sid = v_source_ind_sid_2)
		   AND psmv.start_dtm = in_start_date
		   AND (v_user_values_only = 0 OR psmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);

	ELSE

		RAISE_APPLICATION_ERROR(-20001, 'Product metric calculation type ' || v_calc_type || ' is not supported for products');

	END IF;
	
	Internal_SetProductMetric(
		in_product_id				=>	in_product_id,
		in_ind_sid					=>	in_ind_sid,
		in_start_date				=>	in_start_date,
		in_end_date					=>	in_end_date,
		in_val						=>	v_result,
		in_measure_conversion_id	=>	NULL,
		in_note						=>	NULL,
		in_source_type				=>	chain_pkg.METRIC_VAL_SOURCE_TYPE_CALC,
		in_propagate_scores			=>	0
	);
END;

PROCEDURE Internal_RecalcSuppMetric(
	in_product_supplier_id		IN	product_supplier.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE
)
AS
	v_calc_type					product_metric_calc.calc_type%TYPE;
	v_operator					product_metric_calc.operator%TYPE;
	v_source_ind_sid_1			product_metric_calc.source_ind_sid_1%TYPE;
	v_source_argument_1			product_supplier_metric_val.val_number%TYPE;
	v_source_ind_sid_2			product_metric_calc.source_ind_sid_2%TYPE;
	v_source_argument_2			product_supplier_metric_val.val_number%TYPE;
	v_user_values_only			product_metric_calc.user_values_only%TYPE;
	v_result					product_supplier_metric_val.val_number%TYPE;
BEGIN
	SELECT calc_type, operator, source_ind_sid_1, source_ind_sid_2, source_argument_2, user_values_only
	  INTO v_calc_type, v_operator, v_source_ind_sid_1, v_source_ind_sid_2, v_source_argument_2, v_user_values_only
	  FROM product_metric_calc
	 WHERE destination_ind_sid = in_ind_sid
	   AND applies_to_product_suppliers = 1;
	   
	-- Since we've bucketed the values, we only need to look up start dates.

	IF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC THEN

		BEGIN
			SELECT val_number
			  INTO v_source_argument_1
			  FROM product_supplier_metric_val
			 WHERE product_supplier_id = in_product_supplier_id
			   AND ind_sid = v_source_ind_sid_1
			   AND start_dtm = in_start_date;
		EXCEPTION
			WHEN no_data_found THEN
				v_source_argument_1 := NULL;
		END;

		IF v_source_ind_sid_2 IS NOT NULL THEN
			BEGIN
				SELECT val_number
				  INTO v_source_argument_2
				  FROM product_supplier_metric_val
				 WHERE product_supplier_id = in_product_supplier_id
				   AND ind_sid = v_source_ind_sid_2
				   AND start_dtm = in_start_date;
			EXCEPTION
				WHEN no_data_found THEN
					v_source_argument_2 := NULL;
			END;
		END IF;

		BEGIN
			v_result := CASE v_operator
				WHEN '+' THEN v_source_argument_1 + v_source_argument_2
				WHEN '-' THEN v_source_argument_1 - v_source_argument_2
				WHEN '*' THEN v_source_argument_1 * v_source_argument_2
				WHEN '/' THEN v_source_argument_1 / v_source_argument_2
			END;
		EXCEPTION
			WHEN value_error THEN
				v_result := NULL;
			WHEN zero_divide THEN
				v_result := NULL;
		END;

	ELSIF v_calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG THEN
		
		SELECT CASE v_operator
			   WHEN 'count'		THEN COUNT(psmv.val_number)
			   WHEN 'sum'		THEN SUM(psmv.val_number)
			   WHEN 'min'		THEN MIN(psmv.val_number)
			   WHEN 'max'		THEN MAX(psmv.val_number)
			   WHEN 'avg'		THEN AVG(psmv.val_number)
		   END INTO v_result
		  FROM product_supplier dps
		  JOIN product_supplier sps ON sps.product_id = dps.product_id AND sps.purchaser_company_sid = dps.supplier_company_sid
		  JOIN product_supplier_metric_val psmv ON psmv.product_supplier_id = sps.product_supplier_id
		 WHERE dps.product_supplier_id = in_product_supplier_id
		   AND sps.is_active = chain_pkg.ACTIVE
		   AND (psmv.ind_sid = v_source_ind_sid_1 OR psmv.ind_sid = v_source_ind_sid_2)
		   AND psmv.start_dtm = in_start_date
		   AND (v_user_values_only = 0 OR psmv.source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);
		   
	ELSE

		RAISE_APPLICATION_ERROR(-20001, 'Product metric calculation type ' || v_calc_type || ' is not supported for product suppliers');

	END IF;
	
	Internal_SetProdSupMetric(
		in_product_supplier_id		=>	in_product_supplier_id,
		in_ind_sid					=>	in_ind_sid,
		in_start_date				=>	in_start_date,
		in_end_date					=>	in_end_date,
		in_val						=>	v_result,
		in_measure_conversion_id	=>	NULL,
		in_note						=>	NULL,
		in_source_type				=>	chain_pkg.METRIC_VAL_SOURCE_TYPE_CALC,
		in_propagate_scores			=>	0
	);
END;

PROCEDURE Intrnl_PropagateProductMetric(
	in_product_id				IN	product_metric_val.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE
)
AS
	v_company_sid				company_product.company_sid%TYPE;
BEGIN 
	SELECT company_sid
	  INTO v_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	FOR r IN (
		WITH dependencies AS (
			-- product -> product calculations
			SELECT K_PRODUCT source_object_type, in_product_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_PRODUCT destination_object_type, in_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_products = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			 UNION ALL
			SELECT K_PRODUCT source_object_type, in_product_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_PRODUCT destination_object_type, in_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_products = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product -> product company aggregations
			SELECT K_PRODUCT source_object_type, in_product_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			 UNION ALL
			SELECT K_PRODUCT source_object_type, in_product_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			   AND pmc.source_ind_sid_2 IS NOT NULL
		)
		SELECT object_type, object_id, ind_sid FROM (
			SELECT object_type, object_id, ind_sid, MAX(lvl) max_lvl FROM (
				SELECT destination_object_type object_type, destination_object_id object_id, destination_ind_sid ind_sid, LEVEL lvl
				  FROM dependencies cd
				 START WITH source_object_type = K_PRODUCT
				        AND source_object_id = in_product_id
						AND (in_ind_sid IS NULL OR source_ind_sid = in_ind_sid)
				 CONNECT BY source_object_type = PRIOR destination_object_type
						AND source_object_id = PRIOR destination_object_id
						AND source_ind_sid = PRIOR destination_ind_sid
			)
			GROUP BY object_type, object_id, ind_sid
		)
		ORDER BY max_lvl ASC
	) LOOP
		IF r.object_type = K_PRODUCT THEN
			Internal_RecalcProdMetric(
				in_product_id			=>	r.object_id,
				in_ind_sid				=>	r.ind_sid,
				in_start_date			=>	in_start_date,
				in_end_date				=>	in_end_date
			);
		ELSIF r.object_type = K_COMPANY THEN
			Internal_RecalcCompMetric(
				in_company_sid			=>	r.object_id,
				in_ind_sid				=>	r.ind_sid,
				in_start_date			=>	in_start_date,
				in_end_date				=>	in_end_date
			);
		END IF;
	END LOOP;
END;

PROCEDURE Internal_SetProductMetric(
	in_product_id				IN	product_metric_val.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE,
	in_val						IN	product_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_metric_val.note%TYPE,
	in_source_type				IN	product_metric_val.source_type%TYPE,
	in_propagate_scores			IN	NUMBER
)
AS
BEGIN
	IF in_val IS NULL THEN
		DELETE FROM product_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND product_id = in_product_id
		   AND ind_sid = in_ind_sid
		   AND start_dtm = in_start_date
		   AND end_dtm = in_end_date
		   AND (in_source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER OR source_type != chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);
	ELSE
		BEGIN
			INSERT INTO product_metric_val (
				product_metric_val_id,
				product_id,
				ind_sid,
				start_dtm,
				end_dtm,
				entered_by_sid,
				entered_dtm,
				val_number,
				entered_as_val_number,
				note,
				measure_conversion_id,
				source_type
			) VALUES (
				product_metric_val_id_seq.nextval,
				in_product_id,
				in_ind_sid,
				in_start_date,
				in_end_date,
				security_pkg.GetSID,
				SYSDATE,
				csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_measure_conversion_id, in_start_date),
				in_val,
				in_note,
				in_measure_conversion_id,
				in_source_type
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE product_metric_val
					SET entered_by_sid = security_pkg.GetSID,
						entered_dtm = SYSDATE,
						val_number = csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_measure_conversion_id, in_start_date),
						entered_as_val_number = in_val,
						note = in_note,
						measure_conversion_id = in_measure_conversion_id,
						source_type = in_source_type
					WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   		AND product_id = in_product_id
			   		AND ind_sid = in_ind_sid
			   		AND start_dtm = in_start_date
			   		AND end_dtm = in_end_date
					AND (in_source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER OR source_type != chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);
		END;
	END IF;

	IF in_propagate_scores = 1 THEN
		Intrnl_PropagateProductMetric(
			in_product_id				=>	in_product_id,
			in_ind_sid					=>	in_ind_sid,
			in_start_date				=>	in_start_date,
			in_end_date					=>	in_end_date
		);
	END IF;
END;

PROCEDURE SetProductMetric(
	in_product_id				IN	product_metric_val.product_id%TYPE,
	in_ind_sid					IN	product_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_metric_val.end_dtm%TYPE,
	in_val						IN	product_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_metric_val.note%TYPE
)
AS
	v_divisibility			NUMBER;
	v_value_to_insert		NUMBER(24,10);
	v_current_start_date	DATE;
	v_current_end_date		DATE;
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid		security_pkg.T_SID_ID;
	v_product_supplier_cnt	NUMBER;
	v_can_write_metric		NUMBER := 0;
BEGIN
	SELECT company_sid
	  INTO v_owner_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;
	 
	IF v_company_sid = v_owner_company_sid THEN
		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
			v_can_write_metric := 1;
		END IF;
	ELSE
		IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
			v_can_write_metric := 1;
		END IF;
	END IF;
		
	SELECT count(*)
	  INTO v_product_supplier_cnt
	  FROM product_supplier
	 WHERE product_id = in_product_id
	   AND supplier_company_sid =  v_company_sid;

	IF v_product_supplier_cnt > 0 AND type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
		v_can_write_metric := 1;
	END IF;

	IF v_can_write_metric = 0 THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access on products metrics denied on product '||in_product_id);
	END IF;

	SELECT NVL(i.divisibility, m.divisibility)
	  INTO v_divisibility
	  FROM csr.ind i 
	  LEFT JOIN csr.measure m ON m.measure_sid = i.measure_sid
	 WHERE i.ind_sid = in_ind_sid;

	IF v_divisibility = csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
		v_value_to_insert := in_val / ROUND(MONTHS_BETWEEN(in_end_date, in_start_date));
	ELSE
		v_value_to_insert := in_val;
	END IF;

	v_current_start_date := in_start_date;
	v_current_end_date := ADD_MONTHS(v_current_start_date, 1);

	WHILE v_current_start_date < in_end_date
	LOOP
		Internal_SetProductMetric(
			in_product_id				=> in_product_id,
			in_ind_sid					=> in_ind_sid,
			in_start_date				=> v_current_start_date,
			in_end_date					=> v_current_end_date,
			in_val						=> v_value_to_insert,
			in_measure_conversion_id	=> in_measure_conversion_id,
			in_note						=> in_note,
			in_source_type				=> chain_pkg.METRIC_VAL_SOURCE_TYPE_USER,
			in_propagate_scores			=> 1
		);

		v_current_start_date := v_current_end_date;
		v_current_end_date := ADD_MONTHS(v_current_end_date, 1);
	END LOOP;
END;

PROCEDURE UNSEC_PropagateProductMetrics(
	in_product_id				IN	product_metric_val.product_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT start_dtm, end_dtm
		  FROM product_metric_val
		 WHERE product_id = in_product_id
		 GROUP BY start_dtm, end_dtm
	)
	LOOP
		Intrnl_PropagateProductMetric(
			in_product_id				=> in_product_id,
			in_ind_sid					=> NULL,
			in_start_date				=> r.start_dtm,
			in_end_date					=> r.end_dtm
		);
	END LOOP;
END;

PROCEDURE Intrnl_PropagateProdSupMetric(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE
)
AS
	v_product_id				company_product.product_id%TYPE;
	v_company_sid				company_product.company_sid%TYPE;
BEGIN
	SELECT product_id
	  INTO v_product_id
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	SELECT company_sid
	  INTO v_company_sid
	  FROM company_product
	 WHERE product_id = v_product_id;

	FOR r IN (
		WITH dependencies AS (
			-- product supplier -> product supplier aggregations
			SELECT K_SUPPLIER source_object_type, sps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_SUPPLIER destination_object_type, dps.product_supplier_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier sps
			  JOIN product_supplier dps ON sps.purchaser_company_sid = dps.supplier_company_sid
			 CROSS JOIN product_metric_calc pmc
			 WHERE sps.product_id = v_product_id
			   AND dps.product_id = v_product_id
			   AND pmc.applies_to_product_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, sps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_SUPPLIER destination_object_type, dps.product_supplier_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier sps
			  JOIN product_supplier dps ON sps.purchaser_company_sid = dps.supplier_company_sid
			 CROSS JOIN product_metric_calc pmc
			 WHERE sps.product_id = v_product_id
			   AND dps.product_id = v_product_id
			   AND pmc.applies_to_product_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product supplier -> product supplier calculations
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_SUPPLIER destination_object_type, ps.product_supplier_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_product_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_SUPPLIER destination_object_type, ps.product_supplier_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_product_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product supplier -> product aggregations
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_PRODUCT destination_object_type, v_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_products = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_PRODUCT destination_object_type, v_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_products = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product supplier -> product supplier purchaser company aggregations
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_COMPANY destination_object_type, ps.purchaser_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_prod_sup_purchasers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_COMPANY destination_object_type, ps.purchaser_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_prod_sup_purchasers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product supplier -> product supplier supplier sompany aggregations
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_COMPANY destination_object_type, ps.supplier_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_prod_sup_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_COMPANY destination_object_type, ps.supplier_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE ps.product_id = v_product_id
			   AND pmc.applies_to_prod_sup_suppliers = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product -> product calculations
			SELECT K_PRODUCT source_object_type, v_product_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_PRODUCT destination_object_type, v_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_products = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			 UNION ALL
			SELECT K_PRODUCT source_object_type, v_product_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_PRODUCT destination_object_type, v_product_id destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_products = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_CALC
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product supplier -> product company aggregations
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG
			 UNION ALL
			SELECT K_SUPPLIER source_object_type, ps.product_supplier_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_supplier ps
			 CROSS JOIN product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type = chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG
			   AND pmc.source_ind_sid_2 IS NOT NULL
			 UNION ALL
			-- product -> product company aggregations
			SELECT K_PRODUCT source_object_type, v_product_id source_object_id, pmc.source_ind_sid_1 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			 UNION ALL
			SELECT K_PRODUCT source_object_type, v_product_id source_object_id, pmc.source_ind_sid_2 source_ind_sid,
				   K_COMPANY destination_object_type, v_company_sid destination_object_id, pmc.destination_ind_sid
			  FROM product_metric_calc pmc
			 WHERE pmc.applies_to_product_companies = 1
			   AND pmc.calc_type IN (chain_pkg.METRIC_VAL_CALC_TYPE_CHILD_AGG, chain_pkg.METRIC_VAL_CALC_TYPE_DESC_AGG)
			   AND pmc.source_ind_sid_2 IS NOT NULL
		)
		SELECT object_type, object_id, ind_sid FROM (
			SELECT object_type, object_id, ind_sid, MAX(lvl) max_lvl FROM (
				SELECT destination_object_type object_type, destination_object_id object_id, destination_ind_sid ind_sid, LEVEL lvl
				  FROM dependencies cd
				 START WITH source_object_type = K_SUPPLIER
				        AND source_object_id = in_product_supplier_id
						AND (in_ind_sid IS NULL OR source_ind_sid = in_ind_sid)
				 CONNECT BY source_object_type = PRIOR destination_object_type
						AND source_object_id = PRIOR destination_object_id
						AND source_ind_sid = PRIOR destination_ind_sid
			)
			GROUP BY object_type, object_id, ind_sid
		)
		ORDER BY max_lvl ASC
	) LOOP
		IF r.object_type = K_SUPPLIER THEN
			Internal_RecalcSuppMetric(
				in_product_supplier_id	=>	r.object_id,
				in_ind_sid				=>	r.ind_sid,
				in_start_date			=>	in_start_date,
				in_end_date				=>	in_end_date
			);
		ELSIF r.object_type = K_PRODUCT THEN
			Internal_RecalcProdMetric(
				in_product_id			=>	r.object_id,
				in_ind_sid				=>	r.ind_sid,
				in_start_date			=>	in_start_date,
				in_end_date				=>	in_end_date
			);
		ELSIF r.object_type = K_COMPANY THEN
			Internal_RecalcCompMetric(
				in_company_sid			=>	r.object_id,
				in_ind_sid				=>	r.ind_sid,
				in_start_date			=>	in_start_date,
				in_end_date				=>	in_end_date
			);
		END IF;
	END LOOP;
END;

PROCEDURE Internal_SetProdSupMetric(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE,
	in_val						IN	product_supplier_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_supplier_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_supplier_metric_val.note%TYPE,
	in_source_type				IN	product_supplier_metric_val.source_type%TYPE,
	in_propagate_scores			IN	NUMBER
)
AS
	v_product_id				company_product.product_id%TYPE;
	v_company_sid				company_product.company_sid%TYPE;
BEGIN
	IF in_val IS NULL THEN
		DELETE FROM product_supplier_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND product_supplier_id = in_product_supplier_id
		   AND ind_sid = in_ind_sid
		   AND start_dtm = in_start_date
		   AND end_dtm = in_end_date
		   AND (in_source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER OR source_type != chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);
	ELSE
		BEGIN
			INSERT INTO product_supplier_metric_val (
				supplier_product_metric_val_id,
				product_supplier_id,
				ind_sid,
				start_dtm,
				end_dtm,
				entered_by_sid,
				entered_dtm,
				val_number,
				entered_as_val_number,
				note,
				measure_conversion_id,
				source_type
			) VALUES (
				product_supplr_mtrc_val_id_seq.nextval,
				in_product_supplier_id,
				in_ind_sid,
				in_start_date,
				in_end_date,
				security_pkg.GetSID,
				SYSDATE,
				csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_measure_conversion_id, in_start_date),
				in_val,
				in_note,
				in_measure_conversion_id,
				in_source_type
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE product_supplier_metric_val
					SET entered_by_sid = security_pkg.GetSID,
						entered_dtm = SYSDATE,
						val_number = csr.measure_pkg.UNSEC_GetBaseValue(in_val, in_measure_conversion_id, in_start_date),
						entered_as_val_number = in_val,
						note = in_note,
						measure_conversion_id = in_measure_conversion_id,
						source_type = in_source_type
				  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   		AND product_supplier_id = in_product_supplier_id
			   		AND ind_sid = in_ind_sid
			   		AND start_dtm = in_start_date
			   		AND end_dtm = in_end_date
					AND (in_source_type = chain_pkg.METRIC_VAL_SOURCE_TYPE_USER OR source_type != chain_pkg.METRIC_VAL_SOURCE_TYPE_USER);
		END;
	END IF;

	IF in_propagate_scores = 1 THEN
		Intrnl_PropagateProdSupMetric(
			in_product_supplier_id		=>	in_product_supplier_id,
			in_ind_sid					=>	in_ind_sid,
			in_start_date				=>	in_start_date,
			in_end_date					=>	in_end_date
		);
	END IF;
END;

PROCEDURE SetProductSupplierMetric(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE,
	in_ind_sid					IN	product_supplier_metric_val.ind_sid%TYPE,
	in_start_date				IN	product_supplier_metric_val.start_dtm%TYPE,
	in_end_date					IN	product_supplier_metric_val.end_dtm%TYPE,
	in_val						IN	product_supplier_metric_val.val_number%TYPE,
	in_measure_conversion_id	IN	product_supplier_metric_val.measure_conversion_id%TYPE,
	in_note						IN	product_supplier_metric_val.note%TYPE
)
AS
	v_divisibility			NUMBER;
	v_value_to_insert		NUMBER(24,10);
	v_current_start_date	DATE;
	v_current_end_date		DATE;
	v_product_id			chain.product_supplier.product_id%TYPE;
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_purchaser_company_sid	security_pkg.T_SID_ID;
	v_supplier_company_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	
	IF v_company_sid = v_supplier_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write Access denied for product metrics to product supplier '||in_product_supplier_id);
		END IF;
	ELSIF v_company_sid = v_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_supplier_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write Access denied for product metrics to product supplier '||in_product_supplier_id);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_purchaser_company_sid, v_supplier_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write Access denied for product metrics to product supplier '||in_product_supplier_id);
		END IF;
	END IF;

	SELECT NVL(i.divisibility, m.divisibility)
	  INTO v_divisibility
	  FROM csr.ind i 
	  LEFT JOIN csr.measure m ON m.measure_sid = i.measure_sid
	 WHERE i.ind_sid = in_ind_sid;

	IF v_divisibility = csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
		v_value_to_insert := in_val / ROUND(MONTHS_BETWEEN(in_end_date, in_start_date));
	ELSE
		v_value_to_insert := in_val;
	END IF;

	v_current_start_date := in_start_date;
	v_current_end_date := ADD_MONTHS(v_current_start_date, 1);

	WHILE v_current_start_date < in_end_date
	LOOP
		Internal_SetProdSupMetric(
			in_product_supplier_id		=> in_product_supplier_id,
			in_ind_sid					=> in_ind_sid,
			in_start_date				=> v_current_start_date,
			in_end_date					=> v_current_end_date,
			in_val						=> v_value_to_insert,
			in_measure_conversion_id	=> in_measure_conversion_id,
			in_note						=> in_note,
			in_source_type				=> chain_pkg.METRIC_VAL_SOURCE_TYPE_USER,
			in_propagate_scores			=> 1
		);

		v_current_start_date := v_current_end_date;
		v_current_end_date := ADD_MONTHS(v_current_end_date, 1);
	END LOOP;
END;

PROCEDURE UNSEC_PropagateProdSupMetrics(
	in_product_supplier_id		IN	product_supplier_metric_val.product_supplier_id%TYPE
)
AS
	v_product_id				product_supplier.product_id%TYPE;
BEGIN
	SELECT product_id
	  INTO v_product_id
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	FOR r IN (
		SELECT start_dtm, end_dtm FROM (
				SELECT pmv.start_dtm, pmv.end_dtm
				  FROM product_metric_val pmv
				 WHERE pmv.product_id = v_product_id
				 UNION ALL
				SELECT psmv.start_dtm, psmv.end_dtm
				  FROM product_supplier_metric_val psmv
				  JOIN product_supplier ps ON ps.product_supplier_id = psmv.product_supplier_id
				 WHERE ps.product_id = v_product_id
		) GROUP BY start_dtm, end_dtm
	)
	LOOP
		Intrnl_PropagateProdSupMetric(
			in_product_supplier_id		=> in_product_supplier_id,
			in_ind_sid					=> NULL,
			in_start_date				=> r.start_dtm,
			in_end_date					=> r.end_dtm
		);
	END LOOP;
END;

END product_metric_pkg;
/
