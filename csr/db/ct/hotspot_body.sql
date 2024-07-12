CREATE OR REPLACE PACKAGE BODY ct.hotspot_pkg AS

FUNCTION HasCompletedHotspotter 
RETURN NUMBER
AS
BEGIN
	RETURN HasCompletedHotspotter(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION HasCompletedHotspotter (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM breakdown_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND is_hotspot = 1;

	RETURN v_count;
END;

FUNCTION HasSupplierCompletedHotspotter (
	in_supplier_id					IN  supplier.supplier_id%TYPE
) RETURN NUMBER
AS
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT NVL(company_sid, -1) INTO v_company_sid FROM supplier WHERE supplier_id = in_supplier_id;

	IF v_company_sid < 0 THEN
		RETURN 0;
	ELSE
		RETURN HasCompletedHotspotter(v_company_sid);
	END IF;
END;

FUNCTION HasCompletedHotspotterPeriod (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_period_id					IN	company.period_id%TYPE
) RETURN NUMBER
AS
	v_count		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND period_id=in_period_id;

	RETURN v_count;
END;

PROCEDURE GetEios(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- TO DO - secure, make safe version or use custom exporter to stop factors going back to js

	OPEN out_cur FOR 
	  SELECT 
			eio_id, description, eio_group_id, 
			emis_fctr_c_to_g, emis_fctr_c_to_g_inc_use_ph, pct_elec_energy, pct_other_energy, 
			pct_use_phase, pct_warehouse, pct_waste, pct_upstream_trans, 
			pct_downstream_trans, pct_ctfc_scope_one_two, phase_purch_goods_pct -- waste is included in the PG "sometimes"???
		FROM eio e
		JOIN (SELECT primary_eio_cat_id, SUM(pct) phase_purch_goods_pct FROM eio_relationship GROUP BY primary_eio_cat_id) er ON e.eio_id = er.primary_eio_cat_id
	  	WHERE eio_group_id IN (SELECT eio_group_id FROM eio_group WHERE hide = 0)
	   ORDER BY description;
END;

PROCEDURE GetEio(
	in_eio_id						IN  eio.eio_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_phase_p_and_g_pct					NUMBER(20,10);
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to EIO data');
	END IF;

	-- TO DO might need to factor waste / add waste back into here
	SELECT SUM(pct) INTO v_phase_p_and_g_pct FROM eio_relationship WHERE primary_eio_cat_id = in_eio_id;

	OPEN out_cur FOR 
		SELECT 
			eio_id, description, eio_group_id, 
			emis_fctr_c_to_g, emis_fctr_c_to_g_inc_use_ph, pct_elec_energy, pct_other_energy, 
			pct_use_phase, pct_warehouse, pct_waste, pct_upstream_trans, 
			pct_downstream_trans, pct_ctfc_scope_one_two, v_phase_p_and_g_pct phase_purch_goods_pct
		FROM eio
	   WHERE eio_id = in_eio_id
	   ORDER BY description;
END;

PROCEDURE GetGroups(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT eio_group_id, description, eio_group_id as eio_id -- Note: passing this back as eio_id is odd but deliberate to support the Maersk style category picker
		  FROM eio_group
		 WHERE hide = 0
		 ORDER BY eio_group_id;
END;

PROCEDURE GetCountries(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_us_full_lifecycle_ef			hot_region.full_lifecycle_ef%TYPE;
BEGIN

	-- TO DO - secure, make safe version or use custom exporter to stop factors going back to js

	SELECT full_lifecycle_ef 
	  INTO v_us_full_lifecycle_ef 
	  FROM region r
	  JOIN hot_region hr ON r.region_id = hr.region_id
	 WHERE r.region_id = util_pkg.GetRegionIdFromCode(admin_pkg.USA_COUNTRY_CODE);

	OPEN out_cur FOR 
	SELECT region_id, description, country, full_lifecycle_ef, combusition_ef, pct_prop_of_us_ef
	  FROM 
	   (
		  SELECT 
				r.parent_id, r.region_id, description, country, full_lifecycle_ef, combusition_ef, ROUND(full_lifecycle_ef/v_us_full_lifecycle_ef, 20) pct_prop_of_us_ef
			FROM region r
			JOIN hot_region hr ON r.region_id = hr.region_id
		   WHERE (parent_id = admin_pkg.ROW_COUNTRY_CODE_ID OR r.region_id = admin_pkg.ROW_COUNTRY_CODE_ID)
				UNION
			-- fall back to R.O.W for regions not represented in hot region specifically
			SELECT    
				r.parent_id, r.region_id, description, country, full_lifecycle_ef, combusition_ef, ROUND(full_lifecycle_ef/v_us_full_lifecycle_ef, 20) pct_prop_of_us_ef
			FROM region r
			JOIN hot_region hr ON (hr.region_id = admin_pkg.ROW_COUNTRY_CODE_ID)
		   WHERE (parent_id = admin_pkg.ROW_COUNTRY_CODE_ID OR r.region_id = admin_pkg.ROW_COUNTRY_CODE_ID)
			 AND r.region_id NOT IN (SELECT region_id FROM hot_region)
		)
      ORDER BY NVL(parent_id,-1), description;
END;

PROCEDURE GetPeriods(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT period_id, description, usd_ratio_to_base_yr, start_date, end_date
		  FROM period
	  ORDER BY description;
END;

PROCEDURE GetPeriod(
	in_period_id					IN currency_period.period_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT period_id, description, usd_ratio_to_base_yr, start_date, end_date
		  FROM period
		 WHERE period_id = in_period_id;
END;

PROCEDURE GetCurrencies(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT currency_id, description, acronym, symbol
		  FROM currency
		  ORDER BY currency_id;
END;

PROCEDURE GetCurrency(
	in_currency_id					IN  currency.currency_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT currency_id, description, acronym, symbol
		  FROM currency
		 WHERE currency_id = in_currency_id;
END;

PROCEDURE GetCurrencyForPeriod(
	in_currency_id					IN currency_period.currency_id%TYPE,
	in_period_id					IN currency_period.period_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to currency for period data');
	END IF;
	--fall back to the max period this currency has stored values against, ie. use 2014 for 2015 if no data found for 2015
	OPEN out_cur FOR 
		SELECT period_id, currency_id, acronym, symbol, purchse_pwr_parity_fact, conversion_to_dollar
		  FROM 
			(
			SELECT in_period_id period_id, cp.currency_id, acronym, symbol, purchse_pwr_parity_fact, conversion_to_dollar,
			  ROW_NUMBER() over (ORDER BY cp.period_id DESC) rn
					  FROM currency_period cp
					  JOIN period p ON p.period_id = cp.period_id
					  JOIN currency c ON c.currency_id = cp.currency_id
					 WHERE cp.currency_id = in_currency_id
					   AND cp.period_id <= in_period_id 
			)x
		 WHERE x.rn = 1;
END;

PROCEDURE GetBusinessTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT business_type_id, description
		  FROM business_type
		  ORDER BY business_type_id;
END;

PROCEDURE SaveHotspotResult(
	in_breakdown_id              IN hotspot_result.breakdown_id%TYPE,       
	in_region_id                 IN hotspot_result.region_id%TYPE,                     
	in_eio_id                    IN hotspot_result.eio_id%TYPE,   
	in_company_sid				 IN hotspot_result.company_sid%TYPE,       
	in_pg_emissions              IN hotspot_result.pg_emissions%TYPE,               
	in_scope_one_two_emissions   IN hotspot_result.scope_one_two_emissions%TYPE,   
	in_upstream_emissions        IN hotspot_result.upstream_emissions%TYPE,        
	in_downstream_emissions      IN hotspot_result.downstream_emissions%TYPE,      
	in_use_emissions             IN hotspot_result.use_emissions%TYPE,             
	in_waste_emissions           IN hotspot_result.waste_emissions%TYPE,           
	in_emp_comm_emissions        IN hotspot_result.emp_comm_emissions%TYPE,        
	in_business_travel_emissions IN hotspot_result.business_travel_emissions%TYPE
)
AS
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing hotspot results data');
	END IF;

	BEGIN
		INSERT INTO hotspot_result 
		(
		   region_id, 
		   breakdown_id, 
		   eio_id, 
		   company_sid,
		   pg_emissions, 
		   scope_one_two_emissions, 
		   upstream_emissions, 
		   downstream_emissions, 
		   use_emissions, 
		   waste_emissions, 
		   emp_comm_emissions, 
		   business_travel_emissions
		) 
		VALUES 
		( 
		   in_region_id, 
		   in_breakdown_id, 
		   in_eio_id, 
		   in_company_sid,
		   in_pg_emissions,  
		   in_scope_one_two_emissions, 
		   in_upstream_emissions, 
		   in_downstream_emissions, 
		   in_use_emissions, 
		   in_waste_emissions, 
		   in_emp_comm_emissions, 
		   in_business_travel_emissions	
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE hotspot_result
			   SET   
				   company_sid				 = in_company_sid,
				   pg_emissions              = in_pg_emissions,
				   scope_one_two_emissions   = in_scope_one_two_emissions,
				   upstream_emissions        = in_upstream_emissions,
				   downstream_emissions      = in_downstream_emissions,
				   use_emissions             = in_use_emissions,
				   waste_emissions           = in_waste_emissions,
				   emp_comm_emissions        = in_emp_comm_emissions,
				   business_travel_emissions = in_business_travel_emissions
			WHERE region_id                  = in_region_id
			  AND breakdown_id               = in_breakdown_id
			  AND eio_id                     = in_eio_id;
	END;
	
END;

PROCEDURE GetHotRegionsForBreakdown(
	in_breakdown_id					IN breakdown.breakdown_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_full_lifecycle_ef				hot_region.full_lifecycle_ef%TYPE;
	v_combusition_ef				hot_region.combusition_ef%TYPE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to Hotspot region data');
	END IF;

	-- fall back to ROW if any region used not present in hot region
	SELECT full_lifecycle_ef, combusition_ef INTO v_full_lifecycle_ef, v_combusition_ef FROM hot_region WHERE region_id = admin_pkg.ROW_COUNTRY_CODE_ID;
	
	OPEN out_cur FOR 
		SELECT 	br.region_id, br.breakdown_id, br.fte_travel, 
				NVL(full_lifecycle_ef, v_full_lifecycle_ef) full_lifecycle_ef, 
				NVL(combusition_ef, v_combusition_ef) combusition_ef
	      FROM breakdown_region br
		  JOIN region r ON br.region_id = r.region_id
		 LEFT JOIN hot_region hr ON r.region_id = hr.region_id
		 WHERE br.breakdown_id = in_breakdown_id;
END;

PROCEDURE GetHotResults(
	in_company_sid 					company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to Hotspot results');
	END IF;

	OPEN out_cur FOR
		SELECT 
			breakdown_id, region_id, 
			eio_id, company_sid, pg_emissions, scope_one_two_emissions, 
			upstream_emissions, downstream_emissions, use_emissions, 
			waste_emissions, emp_comm_emissions, business_travel_emissions
		  FROM ct.hotspot_result
		 WHERE company_sid = in_company_sid
		   AND app_sid = security_pkg.getApp
		   AND (pg_emissions + scope_one_two_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions) > 0;
END;

PROCEDURE GetScopeData (
	in_company_sid 					IN company.company_sid%TYPE,
	in_breakdown_type_id			IN breakdown_type.breakdown_type_id%TYPE,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
) 
AS	
	v_breakdown_ids					security_pkg.T_SID_IDS;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - scope');
	END IF;
	
	SELECT breakdown_id 
	  BULK COLLECT INTO v_breakdown_ids
	  FROM breakdown 
	 WHERE breakdown_type_id = in_breakdown_type_id
	   AND app_sid = security_pkg.getApp;
	   
	GetScopeData(in_company_sid, v_breakdown_ids, in_breakdown, out_cur);
END;

PROCEDURE GetScopeData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - scope');
	END IF;
	GetScopeData(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_ids, in_breakdown, out_cur);
END;

PROCEDURE GetScopeData (
	in_company_sid 					company.company_sid%TYPE,
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	
	v_scope_one_emissions			ct.company.scope_1%TYPE;
	v_scope_two_emissions			ct.company.scope_2%TYPE;
	
	v_scope_three_total				hotspot_result.scope_one_two_emissions%TYPE;
	
	v_breakdown_type_id				v$hs_breakdown_type.breakdown_type_id%TYPE;
	
	v_scope_input_type_id			ct.company.scope_input_type_id%TYPE;
	v_scope_12_entered				NUMBER(1) := 0;
	v_scope_12_calcd				NUMBER(1) := 0;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - scope');
	END IF;

	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	
	-- find the breakdown type ID
	-- this will and should blow up if you mix breakdown's across types - not supported
	BEGIN
		SELECT breakdown_type_id
		  INTO v_breakdown_type_id
		  FROM v$hs_breakdown_type
		 WHERE breakdown_type_id IN (
			SELECT breakdown_type_id FROM breakdown WHERE breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
		 );
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RETURN;		
	END;
	 
	 -- find the scope 3 emissions total for all breakdown ids in this breakdown_type
	 SELECT 
			ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions)/1000, 5) scope_three_emissions 
	  INTO v_scope_three_total
	  FROM hotspot_result hr
	 WHERE breakdown_id IN (
		SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = v_breakdown_type_id
	 );
	
	-- ignore these values if not direct entry	
	SELECT NVL(scope_1, 0), NVL(scope_2, 0), scope_input_type_id
	  INTO v_scope_one_emissions, v_scope_two_emissions, v_scope_input_type_id 
	  FROM ct.company 
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

	IF v_scope_input_type_id = hotspot_pkg.ENTER_SCOPE_12_DIRECTLY OR v_scope_input_type_id = hotspot_pkg.ENTER_SCOPE_12_CONSUMP THEN
		v_scope_12_entered := 1;
		v_scope_12_calcd := 0;	
	ELSE
		v_scope_12_entered := 0;
		v_scope_12_calcd := 1;	
	END IF;
	   
	IF in_breakdown = 0 THEN 
		OPEN out_cur FOR
			-- if entered directly ammortize the scope1, 2 by scope3/totalscope3 ratio
			SELECT 	scope_one_emissions, scope_two_emissions, 
					scope_one_emissions + scope_two_emissions + scope_one_two_emissions scope_one_two_emissions, -- this should always sum to scope 1+ 2 emissions - no matter how we store the data 
					scope_three_emissions, 
					scope_one_emissions + scope_two_emissions + scope_one_two_emissions + scope_three_emissions scope_one_two_three_emissions
			  FROM
			(
				SELECT 	scope_one_two_emissions * v_scope_12_calcd scope_one_two_emissions, scope_three_emissions, 
						DECODE(v_scope_three_total, 0, 0, ROUND(v_scope_one_emissions*(scope_three_emissions/v_scope_three_total), 5)) * v_scope_12_entered scope_one_emissions,
						DECODE(v_scope_three_total, 0, 0, ROUND(v_scope_two_emissions*(scope_three_emissions/v_scope_three_total), 5)) * v_scope_12_entered scope_two_emissions
				  FROM (
					SELECT 	 
							ROUND(SUM(scope_one_two_emissions)/1000, 5) scope_one_two_emissions, 
							ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions)/1000, 5) scope_three_emissions 
					  FROM hotspot_result hr
					 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
					   AND app_sid = security_pkg.GetApp
					)
			);
	ELSE
		-- if entered directly ammortize the scope1, 2 by scope3/totalscope3 ratio
		OPEN out_cur FOR
			SELECT 	breakdown_id, description, plural, singular, scope_three_emissions, 
					scope_one_emissions + scope_two_emissions + scope_one_two_emissions scope_one_two_emissions, -- this should always sum to scope 1+ 2 emissions - no matter how we store the data 
					scope_one_emissions, scope_two_emissions, 
					scope_one_emissions + scope_two_emissions + scope_one_two_emissions + scope_three_emissions scope_one_two_three_emissions
			  FROM (
				SELECT 	breakdown_id, description, plural, singular, scope_three_emissions, scope_one_two_emissions,
						ROUND(v_scope_one_emissions * (scope_three_emissions/(SUM(scope_three_emissions) OVER ())),5) scope_one_emissions,
						ROUND(v_scope_two_emissions * (scope_three_emissions/(SUM(scope_three_emissions) OVER ())),5) scope_two_emissions
				  FROM
					(
						SELECT 	
								b.breakdown_id, 
								b.description,
								bt.plural,
								bt.singular, 
								ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions)/1000, 5) scope_three_emissions, 
								ROUND(SUM(scope_one_two_emissions)/1000, 5) scope_one_two_emissions
						  FROM hotspot_result hr
						  JOIN breakdown b ON hr.app_sid = b.app_sid AND hr.breakdown_id = b.breakdown_id
						  JOIN v$hs_breakdown_type bt ON b.app_sid = bt.app_sid AND b.breakdown_type_id = bt.breakdown_type_id
						 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
						   AND hr.app_sid = security_pkg.GetApp
						 GROUP BY b.breakdown_id, b.description, bt.plural, bt.singular
					)
				 
			)
			ORDER BY breakdown_id, description, plural, singular	;
	END IF;
END;
	
PROCEDURE GetScopeEIOData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - EIO');
	END IF;

	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	
	OPEN out_cur FOR
		SELECT 	
				e.eio_id, 
				e.description,
				ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions)/1000, 5) scope_three_emissions 
		  FROM hotspot_result hr
		  JOIN eio e ON hr.eio_id = e.eio_id
		 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
		   AND hr.app_sid = security_pkg.GetApp
		 GROUP BY e.eio_id, e.description
		 ORDER BY e.eio_id, e.description;

END;

PROCEDURE GetEIOByBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - EIO');
	END IF;

	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	

	-- we need a 2d "array" of data back - where each eio id / breakdown id involved is represented as a pair
	OPEN out_cur FOR
		-- TO DO - for pities sake tidy this up .....
   SELECT  y.eio_id, x.breakdown_id, 
                breakdown_description,
                plural,
                singular,
                eio_description,
                ROUND(NVL( scope_three_emission_pct,0),5)  scope_three_emission_pct 
          FROM (
             SELECT DISTINCT b.breakdown_id, b.description breakdown_description, singular, plural
               FROM hotspot_result hr
               JOIN breakdown b ON 1=1
               JOIN v$hs_breakdown_type bt ON b.breakdown_type_id = bt.breakdown_type_id
              WHERE b.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
                AND hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
        ) x, (
                SELECT breakdown_id, eio_id, eio_description,100*(scope_three_emissions/SUM(scope_three_emissions) OVER ()) scope_three_emission_pct
                FROM (
                	SELECT  	
                        hr.breakdown_id,
                        er.related_eio_cat_id eio_id, 
                		 erel.description eio_description, 
                		 ROUND(SUM(er.pct)*SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions), 5)  scope_three_emissions
                	  FROM hotspot_result hr
                	  JOIN eio e ON hr.eio_id = e.eio_id
                	  JOIN eio_relationship er ON er.primary_eio_cat_id = hr.eio_id
                	  JOIN eio erel ON er.related_eio_cat_id = erel.eio_id
                	  JOIN (
                			SELECT primary_eio_cat_id, sum(pct) sum_pg_pct 
                			  FROM eio_relationship 
                			 GROUP BY primary_eio_cat_id
                			) sp ON sp.primary_eio_cat_id = hr.EIO_ID
                	 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
                	   AND app_sid = security_pkg.GetApp
                	GROUP BY hr.breakdown_id, er.related_eio_cat_id, erel.description
                   )
        ) y 
         WHERE x.breakdown_id = y.breakdown_id(+) 
         ORDER BY  y.eio_description, y.eio_id, x.breakdown_description, x.breakdown_id;
END;

PROCEDURE GetEmissionBreakdownByRank (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_show_scope_three_categ		IN NUMBER,
	in_show_pg_as_breakdown			IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;

	v_scope_total					NUMBER(30, 10);
	
	v_pg_emissions					hotspot_result.pg_emissions%TYPE;
	v_upstream_emissions			hotspot_result.upstream_emissions%TYPE;
	v_downstream_emissions			hotspot_result.downstream_emissions%TYPE;
	v_use_emissions					hotspot_result.use_emissions%TYPE;
	v_waste_emissions				hotspot_result.waste_emissions%TYPE;
	v_emp_comm_emissions			hotspot_result.emp_comm_emissions%TYPE;
	v_business_travel_emissions		hotspot_result.business_travel_emissions%TYPE;
	
	v_scope_three_emissions			NUMBER(30, 10);

BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - ranked emissions');
	END IF;
		
	IF in_show_scope_three_categ + in_show_pg_as_breakdown = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'One breakdown must be set');
	END IF;
		
	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	-- in kg here 
	SELECT 
		NVL(SUM(pg_emissions),0) pg_emissions,
		NVL(SUM(upstream_emissions),0) upstream_emissions, 
		NVL(SUM(downstream_emissions),0) downstream_emissions,
		NVL(SUM(use_emissions),0) use_emissions,
		NVL(SUM(waste_emissions),0) waste_emissions,
		NVL(SUM(emp_comm_emissions),0) emp_comm_emissions,
		NVL(SUM(business_travel_emissions),0) business_travel_emissions,
		ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions), 5) scope_three_emissions 
	  INTO v_pg_emissions, v_upstream_emissions, v_downstream_emissions, v_use_emissions, v_waste_emissions, v_emp_comm_emissions, v_business_travel_emissions, v_scope_three_emissions
	  FROM hotspot_result hr
	 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
	   AND app_sid = security_pkg.GetApp;
			
	IF in_show_scope_three_categ > 0 THEN
		INSERT INTO chart_value (description, val) VALUES ('Upstream transportation and distribution', v_upstream_emissions);
		INSERT INTO chart_value (description, val) VALUES ('Downstream transportation and distribution', v_downstream_emissions);
		INSERT INTO chart_value (description, val) VALUES ('Use of sold products', v_use_emissions);
		INSERT INTO chart_value (description, val) VALUES ('Waste generated in operations', v_waste_emissions );
		INSERT INTO chart_value (description, val) VALUES ('Employee commuting', v_emp_comm_emissions);
		INSERT INTO chart_value (description, val) VALUES ('Business travel', v_business_travel_emissions);
		
		IF in_show_pg_as_breakdown = 0 THEN
			INSERT INTO chart_value (description, val) VALUES ('Purchased goods', v_pg_emissions);
		END IF;
	END IF;
	
	IF in_show_pg_as_breakdown > 0 THEN	
		INSERT INTO chart_value (description, val) 
		SELECT description, SUM(emiss) 
		  FROM (
			SELECT related_eio_cat_id, description, hr.pg_emissions * (rel_eio_pg_pct_cont/total_pg_pct_cont) emiss
			  FROM hotspot_result hr
			  JOIN (
				SELECT er.primary_eio_cat_id, er.related_eio_cat_id, erel.description, total_pg_pct_cont, ROUND(SUM(er.pct),5) rel_eio_pg_pct_cont
			     FROM eio_relationship er 
				 JOIN eio erel ON er.related_eio_cat_id = erel.eio_id
				 JOIN (
					SELECT primary_eio_cat_id, sum(pct) total_pg_pct_cont 
					  FROM eio_relationship 
					 GROUP BY primary_eio_cat_id
				  ) sp ON sp.primary_eio_cat_id = er.primary_eio_cat_id
			    GROUP BY  er.primary_eio_cat_id,er.related_eio_cat_id, erel.description, total_pg_pct_cont
			  ) er ON hr.eio_id = primary_eio_cat_id
		  WHERE total_pg_pct_cont > 0 -- stop div by 0
		   AND app_sid = security_pkg.GetApp
		   AND hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
		  ) 
		 GROUP BY related_eio_cat_id, description;
	END IF;
	
	SELECT SUM(val) INTO v_scope_total FROM chart_value;
	
	IF v_scope_total <= 0 THEN 
		RETURN;
	END IF;
	
	--return as %
	OPEN out_cur FOR
		SELECT description, ROUND(pg_pct_cont, 20) pg_pct_cont
		  FROM (SELECT description, 100*val/v_scope_total pg_pct_cont FROM chart_value)
		 WHERE pg_pct_cont > 0
		ORDER BY pg_pct_cont DESC;
END;

PROCEDURE GetEmissionByCategory (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	in_breakdown					NUMBER,
	in_stack_PG						NUMBER,
	in_get_pct						NUMBER,
	in_scope_category_id			scope_3_category.scope_category_id%TYPE,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_scope_three_total				NUMBER(30, 10);

BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - emissions by category');
	END IF;
		
	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	
	SELECT SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions) scope_three_emissions 
	  INTO v_scope_three_total
	  FROM hotspot_result hr
	 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
	   AND app_sid = security_pkg.GetApp;
	   
	   -- testing amortizing overscope 1, 2, 3
	/*SELECT SUM(scope_one_two_emissions+pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions) scope_three_emissions 
	  INTO v_scope_three_total
	  FROM hotspot_result hr
	 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
	   AND app_sid = security_pkg.GetApp;
	*/	

	
	-- put in all the non PG stuff - not stacked
	FOR r IN (
		 SELECT 
				hr.breakdown_id,
				NVL(SUM(upstream_emissions)/v_scope_three_total,0) upstream_emissions, 
				NVL(SUM(downstream_emissions)/v_scope_three_total,0) downstream_emissions,
				NVL(SUM(use_emissions)/v_scope_three_total,0) use_emissions,
				NVL(SUM(waste_emissions)/v_scope_three_total,0) waste_emissions,
				NVL(SUM(emp_comm_emissions)/v_scope_three_total,0) emp_comm_emissions,
				NVL(SUM(business_travel_emissions)/v_scope_three_total,0) business_travel_emissions, 
				NVL(SUM(pg_emissions)/v_scope_three_total,0) pg_emissions
		   FROM hotspot_result hr
		  WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
			AND app_sid = security_pkg.GetApp
		  GROUP BY hr.breakdown_id
	)
	LOOP
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Upstream transportation and distribution', r.upstream_emissions, 2, UPSTREAM_TRANSPORTATION);
		
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Downstream transportation and distribution', r.downstream_emissions, 3, DOWNSTREAM_TRANSPORT);
		
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Use of sold products', r.use_emissions, 4, USE_OF_SOLD_PRODUCTS);
		
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Waste generated in operations', r.waste_emissions, 5, WASTE);
		
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Employee commuting', r.emp_comm_emissions, 6, EMPLOYEE_COMMUTING);
		
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
		VALUES (r.breakdown_id, 'Business travel', r.business_travel_emissions, 7, BUSINESS_TRAVEL);
		
		IF in_stack_PG = 0 THEN 
			INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
			VALUES (r.breakdown_id, 'Purchased goods', r.pg_emissions, 1, PURCHASED_GOODS_AND_SERVICES);		
		END IF;
	END LOOP;
		
	IF in_stack_PG = 1 THEN 
		INSERT INTO chart_value (breakdown_id, description, val, pos, scope_3_category_id) 
			SELECT breakdown_id, description, pg_pct_cont, 1, PURCHASED_GOODS_AND_SERVICES
				  FROM (
				   SELECT breakdown_id, description, pg_pct_cont
					 FROM(
						 SELECT  
							hr.breakdown_id,
							 er.related_eio_cat_id, 
							 erel.description, 
							ROUND((SUM(hr.pg_emissions/sum_pg_pct) * SUM(er.pct * e.emis_fctr_c_to_g_inc_use_ph))/v_scope_three_total,5) pg_pct_cont
						  FROM hotspot_result hr
						  JOIN eio e ON hr.eio_id = e.eio_id
						  JOIN eio_relationship er ON er.primary_eio_cat_id = hr.eio_id
						  JOIN eio erel ON er.related_eio_cat_id = erel.eio_id
						  JOIN (
								SELECT primary_eio_cat_id, sum(pct * ei.emis_fctr_c_to_g_inc_use_ph) sum_pg_pct 
								  FROM eio_relationship err
								 join EIO ei on err.primary_eio_cat_id = ei.eio_id
								 GROUP BY primary_eio_cat_id
								) sp ON sp.primary_eio_cat_id = hr.eio_id
						 WHERE hr.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
						   AND app_sid = security_pkg.GetApp
						GROUP BY sum_pg_pct, hr.breakdown_id, er.related_eio_cat_id, erel.description
					)
				) WHERE pg_pct_cont > 0
				ORDER BY pg_pct_cont ASC;
	END IF;

	IF in_breakdown = 0 THEN 
		OPEN out_cur FOR
			SELECT description, ROUND(val ,5) val, pos, scope_3_category_id
			  FROM (
					SELECT scope_3_category_id, description, DECODE(in_get_pct, 1, 100*SUM(val), SUM(val)*v_scope_three_total/1000) val, pos 
					  FROM chart_value 
					 WHERE ((in_scope_category_id IS NULL) OR (scope_3_category_id = in_scope_category_id)) -- maybe just get one scope
					 GROUP BY scope_3_category_id, description, pos
			  )
			ORDER BY pos,val DESC;	
	ELSE
		OPEN out_cur FOR
			SELECT 
				e.breakdown_id, 
				b.description,
				bt.plural,
				bt.singular,				
				ROUND(val ,5) val, pos, scope_3_category_id
			  FROM (
					SELECT breakdown_id, scope_3_category_id, description, DECODE(in_get_pct, 1, 100*val, val*v_scope_three_total/1000) val, pos 
					  FROM chart_value
					 WHERE ((in_scope_category_id IS NULL) OR (scope_3_category_id = in_scope_category_id)) -- maybe just get one scope
				) e
			  JOIN breakdown b ON e.breakdown_id = b.breakdown_id
			  JOIN v$hs_breakdown_type bt ON b.app_sid = bt.app_sid AND b.breakdown_type_id = bt.breakdown_type_id
			 WHERE b.app_sid = security_pkg.getApp
			ORDER BY pos DESC;		
	END IF;
		

END;

PROCEDURE GetHotECTransportData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_type_id				v$hs_breakdown_type.breakdown_type_id%TYPE;

	
	v_car_kg_co2_per_km_cont		ec_car_type.kg_co2_per_km_contribution%TYPE;
	v_bus_kg_co2_per_km_cont		ec_bus_type.kg_co2_per_km_contribution%TYPE;
	v_train_kg_co2_per_km_cont		ec_train_type.kg_co2_per_km_contribution%TYPE;
	v_motorbike_kg_co2_per_km_cont	ec_motorbike_type.kg_co2_per_km_contribution%TYPE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - ECTransport');
	END IF;

	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	END IF;
	
	BEGIN
		-- find the breakdown type ID
		SELECT breakdown_type_id
		  INTO v_breakdown_type_id
		  FROM v$hs_breakdown_type
		 WHERE breakdown_type_id IN (
			SELECT breakdown_type_id FROM breakdown WHERE breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
		 );
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RETURN;		
	END;
	  
    SELECT kg_co2_per_km_contribution INTO v_car_kg_co2_per_km_cont FROM ec_car_type WHERE is_default = 1;
    SELECT kg_co2_per_km_contribution INTO v_bus_kg_co2_per_km_cont  FROM ec_bus_type WHERE is_default = 1;
    SELECT kg_co2_per_km_contribution INTO v_train_kg_co2_per_km_cont  FROM ec_train_type WHERE is_default = 1;
    SELECT kg_co2_per_km_contribution INTO v_motorbike_kg_co2_per_km_cont  FROM ec_motorbike_type WHERE is_default = 1;
	
	OPEN out_cur FOR
        SELECT ROUND(100*car_cont/(car_cont+bus_cont+train_cont+motorbike_cont), 5) car_cont_pct,
               ROUND(100*bus_cont/(car_cont+bus_cont+train_cont+motorbike_cont), 5) bus_cont_pct,
               ROUND(100*train_cont/(car_cont+bus_cont+train_cont+motorbike_cont), 5) train_cont_pct,
               ROUND(100*motorbike_cont/(car_cont+bus_cont+train_cont+motorbike_cont), 5) motorbike_cont_pct,
                0 walk_cont_pct,
                0 bike_cont_pct
          FROM (
            SELECT  
                    SUM(fte * v_car_kg_co2_per_km_cont * ecr.car_avg_pct_use) car_cont,
                    SUM(fte * v_bus_kg_co2_per_km_cont * ecr.bus_avg_pct_use) bus_cont,
                    SUM(fte * v_train_kg_co2_per_km_cont * ecr.train_avg_pct_use) train_cont,
                    SUM(fte * v_motorbike_kg_co2_per_km_cont * ecr.motorbike_avg_pct_use) motorbike_cont
              FROM breakdown_region br
              JOIN breakdown b ON b.breakdown_id = br.breakdown_id 
              JOIN v$ec_region ecr ON ecr.region_id = br.region_id 
             WHERE br.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
			   AND br.app_sid = security_pkg.GetApp
         );

END;

PROCEDURE GetHotBTTransportData (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for hotspot report data - ECTransport');
	END IF;

	-- TO DO - the model has not yet been written / basedata not yet uploaded to calculate these factors
	-- As CT only have data for R.O.W at the moment anyway these are effectively hardcoded factors in the Hotspot model - so deal with them like this for now
	OPEN out_cur FOR
        SELECT 7.5806 	car_cont_pct,
               0.0688 	bus_cont_pct,
               0.4067 	train_cont_pct,
			   0 		walk_cont_pct,
			   0 		bike_cont_pct,
			   91.9437 	air_cont_pct
          FROM dual;

END;

FUNCTION GetResultCountForBreakdowns (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_breakdown_id_table			security.T_SID_TABLE;
	v_cnt 							NUMBER;
BEGIN

	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
	ELSE 
		RETURN 0;
	END IF;

	SELECT COUNT(*) 
	  INTO v_cnt 
	  FROM hotspot_result 
	 WHERE breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))
	   AND app_sid = security_pkg.GetApp;
	
	RETURN v_cnt;
	
END;

FUNCTION SaveBreakdownAsRegion(
	in_region_name				IN	ct.breakdown.description%TYPE,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_parent_region_sid		IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_act			security_pkg.T_ACT_ID DEFAULT security_pkg.getact;
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_region_sid := csr.region_pkg.GetRegionSidFromRef(v_act, security_pkg.getapp, in_breakdown_id);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			--region with region_ref not found, try to get region from path
			BEGIN
				v_region_sid := security.securableobject_pkg.getSidFromPath(v_act, in_parent_region_sid, in_region_name);
				
				csr.region_pkg.SetRegionRef(v_region_sid, in_breakdown_id);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					csr.region_pkg.CreateRegion(
						in_parent_sid => in_parent_region_sid,
						in_name => in_region_name,
						in_description => in_region_name,
						in_active => 1,
						in_region_ref => in_breakdown_id,
						in_region_type => 0, --CSRRegion
						in_apply_deleg_plans => 1,
						in_write_calc_jobs => 1,
						out_region_sid => v_region_sid
					);
			END;
	END;
	
	RETURN v_region_sid;
END;

END  hotspot_pkg;
/
