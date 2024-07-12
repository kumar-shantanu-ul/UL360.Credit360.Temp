CREATE OR REPLACE PACKAGE BODY ct.value_chain_report_pkg AS

PROCEDURE GetPeriodStartEnd (
	out_start_date					OUT period.start_date%TYPE,
	out_end_date 					OUT period.end_date%TYPE
)
AS
	v_period_id						period.period_id%TYPE;
BEGIN
	SELECT period_id INTO v_period_id FROM ct.company WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND app_sid = security_pkg.getApp;
	
	SELECT start_date, end_date INTO out_start_date, out_end_date FROM period WHERE period_id = v_period_id;
END;

PROCEDURE GetBTEmissionsByMode (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  bt_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetBTEmissionsByMode');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT 
			cs.calculation_source_id, 
			cs.description,
			ROUND(SUM(car_kg_co2)/1000, 0) car_tonne_co2, 
			ROUND(SUM(bus_kg_co2)/1000, 0) bus_tonne_co2, 
			ROUND(SUM(train_kg_co2)/1000, 0) train_tonne_co2, 
			ROUND(SUM(motorbike_kg_co2)/1000, 0) motorbike_tonne_co2, 
			ROUND(SUM(bike_kg_co2)/1000, 0) bike_tonne_co2, 
			ROUND(SUM(walk_kg_co2)/1000, 0) walk_tonne_co2, 
			ROUND(SUM(air_kg_co2)/1000, 0) air_tonne_co2
		 FROM bt_emissions bt
		 JOIN bt_calculation_source cs ON cs.calculation_source_id = bt.calculation_source_id
		 JOIN bt_options o ON bt.app_sid = o.app_sid
		WHERE ((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
		  AND bt.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
		  AND ((in_calculation_source_id IS NULL) OR (cs.calculation_source_id = in_calculation_source_id))
		GROUP BY cs.calculation_source_id, cs.description
		ORDER BY cs.calculation_source_id ASC;
	
END;

PROCEDURE GetBTByModeAndBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  bt_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetBTByModeAndBreakdown');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT breakdown_id, description, car_tonne_co2, bus_tonne_co2, train_tonne_co2, motorbike_tonne_co2, bike_tonne_co2, walk_tonne_co2, air_tonne_co2, 
				car_tonne_co2 + bus_tonne_co2 + train_tonne_co2 + motorbike_tonne_co2 + bike_tonne_co2 + walk_tonne_co2 + air_tonne_co2 total_tonne_co2
		  FROM
		(
			SELECT 
				b.breakdown_id, 
				b.description, 
				ROUND(SUM(car_kg_co2)/1000, 0) car_tonne_co2, 
				ROUND(SUM(bus_kg_co2)/1000, 0) bus_tonne_co2, 
				ROUND(SUM(train_kg_co2)/1000, 0) train_tonne_co2, 
				ROUND(SUM(motorbike_kg_co2)/1000, 0) motorbike_tonne_co2, 
				ROUND(SUM(bike_kg_co2)/1000, 0) bike_tonne_co2, 
				ROUND(SUM(walk_kg_co2)/1000, 0) walk_tonne_co2, 
				ROUND(SUM(air_kg_co2)/1000, 0) air_tonne_co2
			 FROM ct.bt_emissions bt
			 JOIN ct.breakdown b ON b.breakdown_id = bt.breakdown_id
			 JOIN bt_options o ON bt.app_sid = o.app_sid
			WHERE ((v_breakdown_is_null = 1) OR (bt.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			  AND bt.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
			  AND ((in_calculation_source_id IS NULL) OR (bt.calculation_source_id = in_calculation_source_id))
			GROUP BY b.breakdown_id, b.description
		)
		ORDER BY car_tonne_co2 + bus_tonne_co2 + train_tonne_co2 + motorbike_tonne_co2 + bike_tonne_co2 + walk_tonne_co2 + air_tonne_co2;
	
END;

PROCEDURE GetECEmissionsByMode (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetECEmissionsByMode');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
		
	OPEN out_cur FOR
		SELECT 
			cs.calculation_source_id, 
			cs.description,
			ROUND(SUM(car_kg_co2)/1000, 0) car_tonne_co2, 
			ROUND(SUM(bus_kg_co2)/1000, 0) bus_tonne_co2, 
			ROUND(SUM(train_kg_co2)/1000, 0) train_tonne_co2, 
			ROUND(SUM(motorbike_kg_co2)/1000, 0) motorbike_tonne_co2, 
			ROUND(SUM(bike_kg_co2)/1000, 0) bike_tonne_co2, 
			ROUND(SUM(walk_kg_co2)/1000, 0) walk_tonne_co2
		 FROM v$ec_emissions ec
		 JOIN ec_calculation_source cs ON cs.calculation_source_id = ec.calculation_source_id
		 JOIN ec_options o ON ec.app_sid = o.app_sid
		WHERE ((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
		  AND ec.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
		  AND ((in_calculation_source_id IS NULL) OR (cs.calculation_source_id = in_calculation_source_id))
		GROUP BY cs.calculation_source_id, cs.description
		ORDER BY cs.calculation_source_id ASC;
		
	
END;

PROCEDURE GetECByModeAndBreakdown (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
	v_max_calculation_source_id 	v$ec_emissions.calculation_source_id%TYPE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetECByModeAndBreakdown');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	BEGIN
		SELECT MAX(calculation_source_id) INTO v_max_calculation_source_id FROM v$ec_emissions ec;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			v_max_calculation_source_id := -1;
	END;
	
	OPEN out_cur FOR
		SELECT breakdown_id, description, car_tonne_co2, bus_tonne_co2, train_tonne_co2, motorbike_tonne_co2, bike_tonne_co2, walk_tonne_co2, 
				car_tonne_co2 + bus_tonne_co2 + train_tonne_co2 + motorbike_tonne_co2 + bike_tonne_co2 + walk_tonne_co2 total_tonne_co2
		  FROM
		(
			SELECT 
				b.breakdown_id, 
				b.description, 
				ROUND(SUM(car_kg_co2)/1000, 0) car_tonne_co2, 
				ROUND(SUM(bus_kg_co2)/1000, 0) bus_tonne_co2, 
				ROUND(SUM(train_kg_co2)/1000, 0) train_tonne_co2, 
				ROUND(SUM(motorbike_kg_co2)/1000, 0) motorbike_tonne_co2, 
				ROUND(SUM(bike_kg_co2)/1000, 0) bike_tonne_co2, 
				ROUND(SUM(walk_kg_co2)/1000, 0) walk_tonne_co2
			 FROM v$ec_emissions ec
			 JOIN breakdown b ON b.breakdown_id = ec.breakdown_id
			WHERE ((v_breakdown_is_null = 1) OR (ec.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			  AND (((in_calculation_source_id IS NULL) AND (ec.calculation_source_id = v_max_calculation_source_id)) OR (ec.calculation_source_id = in_calculation_source_id))
			GROUP BY b.breakdown_id, b.description
		)
		ORDER BY car_tonne_co2 + bus_tonne_co2 + train_tonne_co2 + motorbike_tonne_co2 + bike_tonne_co2 + walk_tonne_co2;
	
END;

PROCEDURE GetPSEmissions (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ps_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissions');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT 
			cs.calculation_source_id, 
			cs.description,
			ROUND(SUM(kg_co2)/1000, 0) tonne_co2
		 FROM ct.v$ps_emissions ps
		 JOIN ct.ps_calculation_source cs ON cs.calculation_source_id = ps.calculation_source_id
		 JOIN ps_options o ON ps.app_sid = o.app_sid
		WHERE ((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
		  AND ((in_calculation_source_id IS NULL) OR (cs.calculation_source_id = in_calculation_source_id))
		  AND ps.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
		GROUP BY cs.calculation_source_id, cs.description
		ORDER BY cs.calculation_source_id ASC;
	
END;

-- TO DO = this needs rewriting badly (or well!). Put in quickly for demo

PROCEDURE GetPSEmissionsDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ps_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissions');
	END IF;

	OPEN out_cur FOR
	SELECT cs.calculation_source_id, description, ROUND(turnover_co2,0) turnover_co2, ROUND(prod_no_exp_co2,0) prod_no_exp_co2, ROUND(apportionment_co2,0) apportionment_co2
		 FRoM (
		 SELECT calculation_source_id, 
				ROUND(SUM(turnover_co2)/1000,0) turnover_co2,
				ROUND(SUM(prod_no_exp_co2)/1000,0) prod_no_exp_co2,
				ROUND(SUM(apportionment_co2)/1000,0)  apportionment_co2
		  FROM (
		   SELECT 
			   lc.calculation_source_id, lc.CONTRIBUTION_SOURCE_ID , 
				   DECODE(lc.contribution_source_id, ct_pkg.PS_DS_TURNOVER, SUM(lc.kg_co2), 0) turnover_co2,
				   DECODE(lc.contribution_source_id, ct_pkg.PS_DS_PRODUCT_NO_EXP, SUM(lc.kg_co2), 0) prod_no_exp_co2,
				   DECODE(lc.contribution_source_id, ct_pkg.PS_DS_APPORTIONMENT, SUM(lc.kg_co2), 0) apportionment_co2
			 FROM ct.v$ps_level_contributions lc
			 JOIN ps_options o ON lc.app_sid = o.app_sid
			 
			GROUP BY lc.calculation_source_id, CONTRIBUTION_SOURCE_ID
		)  GROUP BY calculation_source_id
	) x
	JOIN ps_calculation_source cs ON x.calculation_source_id = cs.calculation_source_id
	ORDER BY cs.calculation_source_id ASC;
	
END;

PROCEDURE GetPSEmissionsByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_calculation_source_id		IN  ps_emissions_all.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissionsByEio');
	END IF;

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT eio_id, description, tonne_co2
		  FROM
		  (
			SELECT e.eio_id, e.description, ROUND(SUM(kg_co2)/1000, 0) tonne_co2
			 FROM ct.v$ps_emissions ps
			 JOIN ps_options o ON ps.app_sid = o.app_sid
			 JOIN eio e ON e.eio_id = ps.eio_id
			WHERE ((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			  AND ps.calculation_source_id = (SELECT max(calculation_source_id) FROM v$ps_emissions WHERE app_sid = security_pkg.getApp)
			  -- just pull back breakdowns we care about - as configured for ps module
			  AND ps.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
			GROUP BY e.eio_id, e.description
		  )
		  ORDER BY tonne_co2 DESC;

END;

PROCEDURE GetPSSpendAndEmissionsByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,  
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
	
	
	
	v_start_date				period.start_date%TYPE;
	v_end_date				period.end_date%TYPE; v_cnt NUMBER;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSSpendAndEmissionsByEio');
	END IF;
	
	-- we are only interested in items added that fall in the date range we care about - as defined by the period the reporting company selected in the HT
	SELECT start_date, end_date
	  INTO v_start_date, v_end_date
	  FROM period p
	  JOIN company c ON c.period_id = p.period_id
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND c.app_sid = security_pkg.getApp;
	
	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	-- TODO: support multi-eio's atm its using the highest pct eio.
	OPEN out_cur FOR
		SELECT e.eio_id, description, NVL(spend_in_dollars,0) spend_in_dollars, NVL(tonne_co2, 0) tonne_co2 
		  FROM
		  (
			SELECT pie.eio_id, 
			       ROUND(SUM(ps.spend_in_dollars*pct), 2) spend_in_dollars, 
			       ROUND(SUM(ps.kg_co2*pct)/1000,0) tonne_co2
			  FROM v$ps_item ps
			  JOIN (
				SELECT item_id, eio_id, pct/100 pct 
				  FROM ps_item_eio
				 WHERE app_sid = security_pkg.getApp
				   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  ) pie
			    ON ps.item_id = pie.item_id
			 WHERE ((v_breakdown_is_null = 1) OR (ps.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			   AND ps.app_sid = security_pkg.getApp
			   AND ps.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND ps.kg_co2 IS NOT NULL
			   AND ps.purchase_date >= v_start_date 
			   AND ps.purchase_date < v_end_date
			 GROUP BY eio_id
		  ) ps
		  JOIN eio e ON e.eio_id = ps.eio_id
		  ORDER BY tonne_co2 DESC;

END;

PROCEDURE GetPSEmissionsBySupplier (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
	
	v_start_date					DATE;
	v_end_date						DATE;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissions');
	END IF;

	GetPeriodStartEnd(v_start_date, v_end_date);

	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;

	OPEN out_cur FOR
		SELECT supplier_id, supplier_name, ROUND(tonne_co2,0) tonne_co2, spend_in_dollars, DECODE(spend_in_dollars, 0, 0, ROUND(1000*tonne_co2/spend_in_dollars, 5)) intensity_kg_co2_dollar
	      FROM 
			(
				SELECT NVL(s.supplier_id, -1) supplier_id, NVL(s.name, 'Other') supplier_name, 
						ROUND(SUM(kg_co2/1000),2) tonne_co2, 
						ROUND(SUM(spend_in_dollars), 2) spend_in_dollars
				  FROM v$ps_item ps
				  LEFT JOIN supplier s ON ps.supplier_id = s.supplier_id 
				 WHERE ((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
				   AND ps.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				   AND ps.app_sid = security_pkg.getApp
				   AND ps.purchase_date >= v_start_date
				   AND ps.purchase_date < v_end_date
				   AND kg_co2 IS NOT NULL -- not been calc'd yet ??? - better to exclude
				 GROUP BY NVL(s.supplier_id, -1), NVL(s.name, 'Other')
			)
		  ORDER BY spend_in_dollars	 DESC;

END;

PROCEDURE GetPSEmissForEioBySupp (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS,  
	in_eio_id						IN  ps_item_eio.eio_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;

	v_start_date				period.start_date%TYPE;
	v_end_date				period.end_date%TYPE; v_cnt NUMBER;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissForEioBySupp');
	END IF;
	
	-- we are only interested in items added that fall in the date range we care about - as defined by the period the reporting company selected in the HT
	SELECT start_date, end_date
	  INTO v_start_date, v_end_date
	  FROM period p
	  JOIN company c ON c.period_id = p.period_id
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND c.app_sid = security_pkg.getApp;
	
	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	-- TODO: support multi-eio's atm its using the highest pct eio.
	OPEN out_cur FOR
		SELECT s.supplier_id, name, NVL(spend_in_dollars,0) spend_in_dollars, NVL(tonne_co2, 0) tonne_co2 
		  FROM
		  (
			SELECT 	supplier_id, 
					ROUND(SUM(ps.kg_co2*pct)/1000,0) tonne_co2, 
					ROUND(SUM(spend_in_dollars*pct), 2) spend_in_dollars
			  FROM v$ps_item ps
			  JOIN (
				SELECT item_id, eio_id, pct/100 pct 
				  FROM ps_item_eio
				 WHERE app_sid = security_pkg.getApp
				   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  ) pie
			    ON ps.item_id = pie.item_id
			WHERE ((v_breakdown_is_null = 1) OR (ps.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			  AND ps.app_sid = security_pkg.getApp
			  AND ps.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  AND ps.kg_co2 IS NOT NULL
			  AND ps.purchase_date >= v_start_date 
			  AND ps.purchase_date < v_end_date
			  AND pie.eio_id = in_eio_id
			GROUP BY supplier_id
		  ) ps
		  JOIN supplier s ON s.supplier_id = ps.supplier_id
		  ORDER BY tonne_co2 DESC;
		  
END;

PROCEDURE GetPSEmissForSupplierByEio (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_supplier_id					supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;

	v_start_date				period.start_date%TYPE;
	v_end_date				period.end_date%TYPE; v_cnt NUMBER;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissForEioBySupp');
	END IF;
	
	-- we are only interested in items added that fall in the date range we care about - as defined by the period the reporting company selected in the HT
	SELECT start_date, end_date
	  INTO v_start_date, v_end_date
	  FROM period p
	  JOIN company c ON c.period_id = p.period_id
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND c.app_sid = security_pkg.getApp;
	
	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	-- TODO: support multi-eio's atm its using the highest pct eio.
	OPEN out_cur FOR
		SELECT e.eio_id, e.description, NVL(spend_in_dollars,0) spend_in_dollars, NVL(tonne_co2, 0) tonne_co2 
		  FROM
		  (
			SELECT 	eio_id, 
					ROUND(SUM(ps.kg_co2*pct)/1000,0) tonne_co2, 
					ROUND(SUM(spend_in_dollars*pct), 2) spend_in_dollars
			  FROM v$ps_item ps
			  JOIN (
				SELECT item_id, eio_id, pct/100 pct 
				  FROM ps_item_eio
				 WHERE app_sid = security_pkg.getApp
				   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  ) pie
			    ON ps.item_id = pie.item_id
			WHERE ((v_breakdown_is_null = 1) OR (ps.breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table))))
			  AND ps.app_sid = security_pkg.getApp
			  AND ps.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  AND ps.kg_co2 IS NOT NULL
			  AND ps.purchase_date >= v_start_date 
			  AND ps.purchase_date < v_end_date
			  AND supplier_id = in_supplier_id
			GROUP BY eio_id
		  ) ps
		  JOIN eio e ON e.eio_id = ps.eio_id
		  ORDER BY tonne_co2 DESC;	
END;

PROCEDURE GetPSEmissByGroupList (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 1;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetPSEmissForEioBySupp');
	END IF;
	
	-- TODO fix up the backwards logic for breakdown IDs in the other procedures
	IF(in_breakdown_ids IS NOT NULL
	   AND in_breakdown_ids.COUNT > 0
	   AND NOT(in_breakdown_ids.COUNT = 1 AND in_breakdown_ids(1) = 0)) THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 0;
	END IF;
	
	OPEN out_cur FOR
		WITH raw_data AS(       
			 SELECT eio_id, eio_description, eio_group_id, eio_group_description, tonne_co2, group_tonne_co2, eio_tonne_co2, total_tonnes_Co2, 
					CASE 
						WHEN group_tonne_co2 < total_tonnes_Co2 * 0.02 THEN 1
						ELSE 0
					END group_other, 
					CASE 
						WHEN eio_tonne_co2 < total_tonnes_Co2 * 0.02 THEN 1
						ELSE 0
					END eio_other
			   FROM (
				SELECT eg.eio_group_id, eg.eio_group_description, eg.eio_id, eg.eio_description, NVL(tonne_co2,0) tonne_co2, 
					   SUM(NVL(tonne_co2,0)) OVER (PARTITION BY eg.eio_group_description ORDER BY eg.eio_group_description) group_tonne_co2, 
					   SUM(NVL(tonne_co2,0)) OVER (PARTITION BY eg.eio_description ORDER BY eg.eio_description) eio_tonne_co2, 
						SUM(NVL(tonne_co2,0)) OVER () total_tonnes_Co2
				  FROM (
					SELECT eg.eio_group_id, eg.description eio_group_description, e.eio_id, e.description eio_description
					  FROM eio_group eg
					  JOIN eio e ON 1=1
					 WHERE hide = 0
				  ) eg LEFT JOIN
				  (
					SELECT eg.eio_group_id, e.eio_id, ROUND(SUM(kg_co2)/1000, 2) tonne_co2
					 FROM ct.v$ps_emissions ps
					 JOIN ps_options o ON ps.app_sid = o.app_sid
					 JOIN eio e ON e.eio_id = ps.eio_id
					 JOIN eio_group eg ON eg.eio_group_id = e.eio_group_id
					WHERE --((v_breakdown_is_null = 1) OR (breakdown_id IN (SELECT column_value FROM TABLE(v_breakdown_id_table)))) AND
					   ps.calculation_source_id = (SELECT max(calculation_source_id) FROM v$ps_emissions WHERE app_sid = security_pkg.getApp)
					  -- just pull back breakdowns we care about - as configured for ps module
					  AND ps.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
					GROUP BY e.eio_id, e.description, eg.eio_group_id, eg.description
				  ) x ON eg.eio_group_id = x.eio_group_id AND eg.eio_id = x.eio_id 
			   )
			   WHERE group_tonne_co2 > 0 AND eio_tonne_co2 > 0
		)
		SELECT eio_id, eio_description, eio_group_id, eio_group_description, ROUND(tonne_co2, 0) tonne_co2,
			   SUM(NVL(tonne_co2,0)) OVER (PARTITION BY eio_group_description ORDER BY eio_group_description) group_tonne_co2, 
			   SUM(NVL(tonne_co2,0)) OVER (PARTITION BY eio_description ORDER BY eio_description) eio_tonne_co2
		  FROM (
			SELECT eio_id, eio_description, eio_group_id, eio_group_description, SUM(tonne_co2) tonne_co2 
			  FROM ( 
				SELECT eio_id, eio_description, eio_group_id, eio_group_description, tonne_co2 FROM (
					SELECT eio_id, eio_description, eio_group_id, eio_group_description, tonne_co2, group_other FROM raw_data WHERE eio_other = 0
					UNION 
					SELECT -1 eio_id, 'Other EIO' eio_description, eio_group_id, eio_group_description,
							SUM(NVL(tonne_co2,0))  tonne_co2, group_other 
					  FROM raw_data WHERE eio_other = 1
					  GROUP BY eio_group_id, eio_group_description, group_other
				) WHERE group_other = 0
				UNION
				SELECT eio_id, eio_description, -1 eio_group_id, 'Other industry group 'eio_group_description, tonne_co2 FROM (
					SELECT eio_id, eio_description, eio_group_id, eio_group_description, tonne_co2, group_other FROM raw_data WHERE eio_other = 0
					UNION 
					SELECT -1 eio_id, 'Other EIO' eio_description, eio_group_id, eio_group_description,
							SUM(NVL(tonne_co2,0))  tonne_co2, group_other 
					  FROM raw_data WHERE eio_other = 1
					  GROUP BY eio_group_id, eio_group_description, group_other
				) WHERE group_other = 1
			) 
			GROUP BY eio_id, eio_description, eio_group_id, eio_group_description
		)
		ORDER BY DECODE(eio_id, -1, -1, 0) DESC, eio_tonne_co2 DESC, eio_id, group_tonne_co2 DESC, eio_group_id	   
		;
END;


-- TO DO = this needs rewriting badly (or well!). Put in quickly for demo
PROCEDURE GetScope123Emissions (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	in_breakdown_by_region			IN NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_breakdown_id_table			security.T_SID_TABLE;
	v_reg_breakdown_type_id		breakdown_type.breakdown_type_id%TYPE; -- for hotspotter
	
	v_scope_one_emissions			ct.company.scope_1%TYPE;
	v_scope_two_emissions			ct.company.scope_2%TYPE;
	
	v_scope_three_total				hotspot_result.scope_one_two_emissions%TYPE;
	
	v_pgs_emissions					hotspot_result.pg_emissions%TYPE;
	v_bt_emissions					hotspot_result.business_travel_emissions%TYPE;
	v_ec_emissions					hotspot_result.emp_comm_emissions%TYPE;
	
	v_scope_input_type_id			ct.company.scope_input_type_id%TYPE;
	v_scope_12_entered				NUMBER(1) := 0;
	v_scope_12_calcd				NUMBER(1) := 0;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetScope123Emissions');
	END IF;

	-- get the breakdown type for this 
	v_reg_breakdown_type_id := breakdown_type_pkg.GetHSRegionBreakdownTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	
	-- copied from hospot_pkg.getScopeData - TO DO - unify these a bit more sensibly
	
	-- get the caculated scope 3 emissions from the hotspotter - used to split caclulated scope 1 and 2 data aparts (proportionally to scope 3 data)
	 SELECT 
			ROUND(SUM(pg_emissions + upstream_emissions + downstream_emissions + use_emissions + waste_emissions + emp_comm_emissions + business_travel_emissions)/1000, 5) scope_three_emissions
	  INTO v_scope_three_total
	  FROM hotspot_result hr
	 WHERE breakdown_id IN (
		SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = v_reg_breakdown_type_id
	 );
	 -- use the region breakdown by default
	 
	-- ignore these values if not direct entry	
	SELECT NVL(scope_1, 0), NVL(scope_2, 0), scope_input_type_id
	  INTO v_scope_one_emissions, v_scope_two_emissions, v_scope_input_type_id 
	  FROM ct.company 
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	IF v_scope_input_type_id = hotspot_pkg.ENTER_SCOPE_12_DIRECTLY OR v_scope_input_type_id = hotspot_pkg.ENTER_SCOPE_12_CONSUMP THEN
		v_scope_12_entered := 1;
		v_scope_12_calcd := 0;	
	ELSE
		v_scope_12_entered := 0;
		v_scope_12_calcd := 1;	
	END IF;
	   
	IF in_breakdown_by_region = 0 THEN
	
		-- get the bt, pg and ec emissions - the best quality we have
		SELECT NVL(ROUND(SUM(kg_co2), 2),0)  
		  INTO v_pgs_emissions
		  FROM v$ps_emissions ps
		  JOIN ps_options o ON ps.app_sid = o.app_sid
		 WHERE ps.app_sid = security_pkg.GetApp
		   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM v$ps_emissions WHERE app_sid = security_pkg.GetApp)
		   -- just pull back breakdowns we care about - as configured for ps module
		   AND ps.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id);
		   
		SELECT NVL(ROUND(SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 2),0) 
		  INTO v_ec_emissions
		  FROM v$ec_emissions ec
		  JOIN ec_options o ON ec.app_sid = o.app_sid
		 WHERE ec.app_sid = security_pkg.GetApp
		   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM v$ec_emissions WHERE app_sid = security_pkg.GetApp)
		   -- just pull back breakdowns we care about - as configured for ps module
		   AND ec.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id);
		   
		SELECT NVL(ROUND(SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2+air_kg_co2), 2),0)
		  INTO v_bt_emissions
		  FROM bt_emissions bt
		  JOIN bt_options o ON bt.app_sid = o.app_sid
		 WHERE bt.app_sid = security_pkg.GetApp
		   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM bt_emissions WHERE app_sid = security_pkg.GetApp)
		   -- just pull back breakdowns we care about - as configured for ps module
		   AND bt.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id);
		   
		OPEN out_cur FOR
			-- if entered directly ammortize the scope1, 2 by scope3/totalscope3 ratio
			SELECT 	v_scope_one_emissions scope_one_emissions, v_scope_two_emissions scope_two_emissions, 
					scope_one_two_emissions scope_one_two_emissions, -- this should always sum to scope 1+ 2 emissions - no matter how we store the data 
					scope_three_emissions
			  FROM
			(
				SELECT 	scope_one_two_emissions * v_scope_12_calcd scope_one_two_emissions, scope_three_emissions
				  FROM (
					SELECT 	 
							ROUND(SUM(scope_one_two_emissions)/1000, 5) scope_one_two_emissions, 
							ROUND((SUM(upstream_emissions + downstream_emissions + use_emissions + waste_emissions)+v_pgs_emissions+v_bt_emissions+v_ec_emissions)/1000, 5) scope_three_emissions 
					  FROM hotspot_result hr
					 WHERE app_sid = security_pkg.GetApp
					   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   -- just pull back regions stuff for modules with no config  to say what they are broken down by
					   AND hr.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = v_reg_breakdown_type_id)
					)
			);
	ELSE
		OPEN out_cur FOR
			SELECT 	region_id, description, scope_one_emissions, scope_two_emissions, 
					scope_one_two_emissions, -- this should always sum to scope 1+ 2 emissions - no matter how we store the data 
					scope_three_emissions
			  FROM
			(
				SELECT 	region_id, description, scope_three_emissions, scope_one_two_emissions,
						ROUND(v_scope_one_emissions * (scope_three_emissions/(SUM(scope_three_emissions) OVER ())),5) scope_one_emissions,
						ROUND(v_scope_two_emissions * (scope_three_emissions/(SUM(scope_three_emissions) OVER ())),5) scope_two_emissions
				  FROM (
					SELECT 	r.region_id, description,
							ROUND(SUM(scope_one_two_emissions)/1000, 5) scope_one_two_emissions, 
							ROUND(SUM(upstream_emissions + downstream_emissions + use_emissions + waste_emissions + ps.ps_emissions + ec.ec_emissions + bt.bt_emissions)/1000, 5) scope_three_emissions 
					  FROM (
						SELECT 	app_sid, region_id, 
								SUM(pg_emissions) pg_emissions, 
								SUM(scope_one_two_emissions) scope_one_two_emissions, 
								SUM(upstream_emissions) upstream_emissions, 
								SUM(downstream_emissions) downstream_emissions, 
								SUM(use_emissions) use_emissions, 
								SUM(waste_emissions) waste_emissions, 
								SUM(emp_comm_emissions) emp_comm_emissions, 
								SUM(business_travel_emissions) business_travel_emissions
						 FROM hotspot_result hr
						WHERE hr.app_sid = security_pkg.GetApp
						  AND hr.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
							-- just pull back regions stuff for modules with no config  to say what they are broken down by
					      AND hr.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = v_reg_breakdown_type_id)
						GROUP BY app_sid, region_id
					  )  hr
					  JOIN region r ON hr.region_id = r.region_id
					  JOIN (
							SELECT region_id, ROUND(SUM(kg_co2), 2) ps_emissions 
							  FROM v$ps_emissions ps
							  JOIN ps_options o ON ps.app_sid = o.app_sid
							 WHERE ps.app_sid = security_pkg.GetApp 
							   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM v$ps_emissions WHERE app_sid = security_pkg.GetApp) 
							   -- just pull back breakdowns we care about - as configured for ps module
							   AND ps.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
							 GROUP BY region_id
							) ps 
						ON hr.region_id = ps.region_id
					  JOIN (
							SELECT region_id, ROUND(SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 2) ec_emissions 
							  FROM v$ec_emissions ec
							  JOIN ec_options o ON ec.app_sid = o.app_sid
							 WHERE ec.app_sid = security_pkg.GetApp 
							   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM v$ec_emissions WHERE app_sid = security_pkg.GetApp) 
							   -- just pull back breakdowns we care about - as configured for ec module
							   AND ec.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
							 GROUP BY region_id
							) ec 
						ON hr.region_id = ec.region_id
					  JOIN (
							SELECT region_id, ROUND(SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2+air_kg_co2), 2) bt_emissions 
							  FROM bt_emissions bt
							  JOIN bt_options o ON bt.app_sid = o.app_sid							  
							 WHERE bt.app_sid = security_pkg.GetApp 
							   AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM bt_emissions WHERE app_sid = security_pkg.GetApp)
							   -- just pull back breakdowns we care about - as configured for bt module
							   AND bt.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
							 GROUP BY region_id
							) bt 
						ON hr.region_id = bt.region_id
					 GROUP BY r.region_id, description
					)
			);
	END IF;
END;

-- TO DO = this needs rewriting badly (or well!). Put in quickly for demo
PROCEDURE GetScope3EmissionsByDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, 
	in_normalised					IN  NUMBER,
	in_unstacked					IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_reg_breakdown_type_id			breakdown_type.breakdown_type_id%TYPE; -- region breakdown type for hotspotter

	v_breakdown_id_table			security.T_SID_TABLE;
	v_breakdown_is_null				NUMBER := 0;
	
	v_ps_low						NUMBER:= 0;
	v_ps_adequate					NUMBER:= 0;	
	v_ps_good						NUMBER:= 0;	
	v_ps_excellent					NUMBER:= 0;
	
	v_ec_low						NUMBER:= 0;
	v_ec_adequate					NUMBER:= 0;	
	v_ec_good						NUMBER:= 0;	
	v_ec_excellent					NUMBER:= 0;
	
	v_utd_emissions               	NUMBER:= 0;
	v_waste_emissions             	NUMBER:= 0;
	v_bt_emissions               	NUMBER:= 0;
	v_dtd_emissions         	    NUMBER:= 0;
	v_up_emissions                  NUMBER:= 0;
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetScope123Emissions');
	END IF;

	IF in_unstacked = 1 AND in_normalised = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'An unstacked normalised graph is not supported - or meaningful');
	END IF;
	
	IF in_breakdown_ids IS NOT NULL THEN
		v_breakdown_id_table := security_pkg.SidArrayToTable(in_breakdown_ids);
		v_breakdown_is_null := 1;
	END IF;
	
	v_reg_breakdown_type_id := breakdown_type_pkg.GetHSRegionBreakdownTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

	BEGIN
		SELECT 
			round(SUM(upstream_emissions)/1000,0),         
			round(SUM(waste_emissions)/1000,0),       
			round(SUM(downstream_emissions)/1000,0),         
			round(SUM(use_emissions)/1000 ,0)          
			INTO 
			v_utd_emissions,         
			v_waste_emissions,         
			v_dtd_emissions,         
			v_up_emissions           
		FROM hotspot_result 
	   WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	     AND breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = v_reg_breakdown_type_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	BEGIN
		SELECT ROUND(SUM(turnover_co2),0), ROUND(SUM(prod_no_exp_co2),0), ROUND(SUM(apportionment_co2),0), 0 excellent -- TO DO - this is missing a level - no prod extrapolation
		  INTO v_ps_low, v_ps_adequate, v_ps_good, v_ps_excellent 
		  FROM (
		 SELECT calculation_source_id, 
				ROUND(SUM(turnover_co2)/1000, 2) turnover_co2,
				ROUND(SUM( prod_no_exp_co2)/1000, 2)    prod_no_exp_co2,
				--ROUND(SUM(prod_exp_co2)/1000, 2)  prod_exp_co2,
				ROUND(SUM(apportionment_co2)/1000, 2)   apportionment_co2
		  FROM (
			   SELECT 
				   lc.calculation_source_id, lc.CONTRIBUTION_SOURCE_ID , 
					   DECODE(lc.contribution_source_id, 1, SUM(lc.kg_co2), 0) turnover_co2,
					   DECODE(lc.contribution_source_id, 3, SUM(lc.kg_co2), 0) prod_no_exp_co2,
					   DECODE(lc.contribution_source_id, 4, SUM(lc.kg_co2), 0) apportionment_co2
				 FROM ct.v$ps_level_contributions lc
				 JOIN ps_options o ON lc.app_sid = o.app_sid
				 -- just pull back breakdowns we care about - as configured for ps module
				GROUP BY lc.calculation_source_id, CONTRIBUTION_SOURCE_ID
		)  GROUP BY calculation_source_id
	) x  WHERE x.calculation_source_id = (select max (calculation_source_id) FROM v$ps_emissions) GROUP BY calculation_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;


	BEGIN
			SELECT 	round(SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2 + air_kg_co2)/1000, 0)
			 INTO v_bt_emissions
			  FROM bt_emissions bt 
			  JOIN bt_options o ON bt.app_sid = o.app_sid
			 WHERE bt.app_sid = security_pkg.getApp
			  AND calculation_source_id = (SELECT MAX(calculation_source_id) FROM bt_emissions WHERE app_sid = security_pkg.getApp)
			  AND bt.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id);	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	
	BEGIN
        SELECT ROUND(SUM(fte_based_co2),0), ROUND(SUM(profile_co2),0), ROUND(SUM(survey_no_exp_co2),0), ROUND(SUM(survey_co2),0)
		  INTO v_ec_low, v_ec_adequate, v_ec_good, v_ec_excellent
          FROM (
			 SELECT calculation_source_id, 
					ROUND(SUM(fte_based_co2)/1000, 2) fte_based_co2, ROUND(SUM(profile_co2)/1000, 2) profile_co2, ROUND(SUM(survey_no_exp_co2)/1000, 2) survey_no_exp_co2, ROUND(SUM(survey_co2)/1000, 2) survey_co2
			  FROM (
				   SELECT 
					   lc.calculation_source_id, lc.CONTRIBUTION_SOURCE_ID , 
						   DECODE(lc.contribution_source_id, 1, SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2), 0) fte_based_co2,
						   DECODE(lc.contribution_source_id, 2, SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2), 0) profile_co2,
						   DECODE(lc.contribution_source_id, 3, SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2), 0) survey_no_exp_co2,
						   DECODE(lc.contribution_source_id, 4, SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2), 0) survey_co2
					 FROM ct.v$ec_level_contributions lc
					 JOIN ec_options o ON lc.app_sid = o.app_sid
					GROUP BY lc.calculation_source_id, CONTRIBUTION_SOURCE_ID
				)  
				GROUP BY calculation_source_id
			) x  
			WHERE x.calculation_source_id = (SELECT MAX (calculation_source_id) FROM v$ec_emissions) GROUP BY calculation_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;


	-- TO DO
	-- tonnes co2 or %
	IF in_normalised = 1 THEN
		-- TO DO - this will blow if if there's no emissions for a category
		
		-- use the decode as an inline div 0 guard (if sum=0, then all vals=0 so div 1 is valid)
        OPEN out_cur FOR
			SELECT  series_label, 
					ROUND(pgs_emissions / DECODE(SUM(pgs_emissions) OVER (), 0, 1, SUM(pgs_emissions) OVER ()) * 100, 0) pgs_emissions, 
					ROUND(utd_emissions / DECODE(SUM(utd_emissions) OVER (), 0, 1, SUM(utd_emissions) OVER ()) * 100, 0) utd_emissions, 
					ROUND(waste_emissions / DECODE(SUM(waste_emissions) OVER (), 0, 1, SUM(waste_emissions) OVER ()) * 100, 0) waste_emissions, 
					ROUND(bt_emissions / DECODE(SUM(bt_emissions) OVER (), 0, 1, SUM(bt_emissions) OVER ()) * 100, 0) bt_emissions, 
					ROUND(ec_commute_emissions / DECODE(SUM(ec_commute_emissions) OVER (), 0, 1, SUM(ec_commute_emissions) OVER ()) * 100, 0) ec_commute_emissions, 
					ROUND(dtd_emissions / DECODE(SUM(dtd_emissions) OVER (), 0, 1, SUM(dtd_emissions) OVER ()) * 100, 0) dtd_emissions, 
					ROUND(up_emissions / DECODE(SUM(up_emissions) OVER (), 0, 1, SUM(up_emissions) OVER ()) * 100, 0) up_emissions 
			FROM (
				SELECT 1 pos, ct_pkg.DQ_DESC_LOW series_label, v_ps_low pgs_emissions, v_utd_emissions utd_emissions, v_waste_emissions waste_emissions, 0 bt_emissions, v_ec_low ec_commute_emissions, v_dtd_emissions dtd_emissions, v_up_emissions up_emissions FROM dual
				UNION
				SELECT 2 pos, ct_pkg.DQ_DESC_ADEQUATE series_label, v_ps_adequate pgs_emissions, 0 utd_emissions, 0 waste_emissions, v_bt_emissions bt_emissions, v_ec_adequate ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
				UNION
				SELECT 3 pos, ct_pkg.DQ_DESC_GOOD series_label, v_ps_good pgs_emissions, 0 utd_emissions, 0 waste_emissions, 0 bt_emissions, v_ec_good ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
				UNION
				SELECT 4 pos, ct_pkg.DQ_DESC_EXCELLENT series_label, v_ps_excellent pgs_emissions, 0 utd_emissions, 0 waste_emissions, 0 bt_emissions, v_ec_excellent ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
			) ORDER BY pos ASC;
	ELSE 
		IF in_unstacked = 1 THEN
			OPEN out_cur FOR
				SELECT v_ps_low + v_ps_adequate + v_ps_good + v_ps_excellent pgs_emissions, 
					   v_utd_emissions utd_emissions, 
					   v_waste_emissions waste_emissions, 
					   v_bt_emissions bt_emissions, 
					   v_ec_low + v_ec_adequate + v_ec_good + v_ec_excellent ec_commute_emissions, 
					   v_dtd_emissions dtd_emissions, 
					   v_up_emissions up_emissions 
				  FROM dual;
		ELSE
			OPEN out_cur FOR
				SELECT series_label, pgs_emissions, utd_emissions, waste_emissions, bt_emissions, ec_commute_emissions, dtd_emissions, up_emissions 
				  FROM
				  (
					SELECT 1 pos, ct_pkg.DQ_DESC_LOW series_label, v_ps_low pgs_emissions, v_utd_emissions utd_emissions, v_waste_emissions waste_emissions, 0 bt_emissions, v_ec_low ec_commute_emissions, v_dtd_emissions dtd_emissions, v_up_emissions up_emissions FROM dual
					UNION
					SELECT 2 pos, ct_pkg.DQ_DESC_ADEQUATE series_label, v_ps_adequate pgs_emissions, 0 utd_emissions, 0 waste_emissions, v_bt_emissions bt_emissions, v_ec_adequate ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
					UNION
					SELECT 3 pos, ct_pkg.DQ_DESC_GOOD series_label, v_ps_good pgs_emissions, 0 utd_emissions, 0 waste_emissions, 0 bt_emissions, v_ec_good ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
					UNION
					SELECT 4 pos, ct_pkg.DQ_DESC_EXCELLENT series_label, v_ps_excellent pgs_emissions, 0 utd_emissions, 0 waste_emissions, 0 bt_emissions, v_ec_excellent ec_commute_emissions, 0 dtd_emissions, 0 up_emissions FROM dual
				) ORDER BY pos ASC;
		END IF;
	END IF;
END;

PROCEDURE GetECEmissionsDQ (
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- only for future proofing
	in_calculation_source_id		IN  v$ec_emissions.calculation_source_id%TYPE, 
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN

	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetECEmissions');
	END IF;

	OPEN out_cur FOR
	SELECT cs.calculation_source_id, description, ROUND(fte_co2,0) fte_co2, ROUND(profile_co2,0) profile_co2, ROUND(survey_extrap_co2,0) survey_extrap_co2, ROUND(survey_no_extrap_co2,0) survey_no_extrap_co2
		 FRoM (
		 SELECT calculation_source_id, 
				ROUND(SUM(fte_co2)/1000,0) fte_co2,
				ROUND(SUM(profile_co2)/1000,0) profile_co2,
				ROUND(SUM(survey_extrap_co2)/1000,0) survey_extrap_co2,
				ROUND(SUM(survey_no_extrap_co2)/1000,0)  survey_no_extrap_co2
		  FROM (
		   SELECT 
			   lc.calculation_source_id, lc.CONTRIBUTION_SOURCE_ID , 
				   DECODE(lc.contribution_source_id, ct_pkg.EC_DS_TURNOVER, SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 0) fte_co2,
				   DECODE(lc.contribution_source_id, ct_pkg.EC_DS_PROFILE, SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 0) profile_co2,
				   DECODE(lc.contribution_source_id, ct_pkg.EC_DS_SURVEY_EXP, SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 0) survey_extrap_co2,
				   DECODE(lc.contribution_source_id, ct_pkg.EC_DS_SURVEY_NO_EXP, SUM(car_kg_co2+bus_kg_co2+train_kg_co2+motorbike_kg_co2+bike_kg_co2+walk_kg_co2), 0) survey_no_extrap_co2
			 FROM ct.v$ec_level_contributions lc
			 JOIN ec_options o ON lc.app_sid = o.app_sid
			GROUP BY lc.calculation_source_id, contribution_source_id
		)  GROUP BY calculation_source_id
	) x
	JOIN ec_calculation_source cs ON x.calculation_source_id = cs.calculation_source_id
	ORDER BY cs.calculation_source_id ASC;
	
END;

FUNCTION ConvertToCubicMeter(
	in_amount		IN	ht_consumption.amount%TYPE,
	in_unit_id      IN  volume_unit.volume_unit_id%TYPE,
	in_unit_type    IN  NUMBER 	--either consumption_pkg.VOLUME_UNIT OR MASS_UNIT
) RETURN ht_consumption.amount%TYPE
AS 
	v_sq_meter_id 		NUMBER := consumption_pkg.CUBIC_METER_ID;
	v_converted_value	ht_consumption.amount%TYPE; 
BEGIN
	IF in_unit_type = consumption_pkg.MASS_UNIT THEN
		v_converted_value := in_amount; -- by convention, we consider 1 tonne = 1 cubic meter
		RETURN v_converted_value;
	END IF;
		
	SELECT in_amount * v2.conversion_to_litres / v1.conversion_to_litres
	  INTO v_converted_value
	  FROM ct.volume_unit v1, ct.volume_unit v2
	 WHERE v1.volume_unit_id = v_sq_meter_id
	   AND v2.volume_unit_id = in_unit_id;
	   
	RETURN v_converted_value;

END;

PROCEDURE GetConsumptionSourceBreakdowns( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetConsumptionSourceBreakdowns');
	END IF;
	--Get water and waste consumption breakdown values (or the default consumption when breakdowns do not exist)
	OPEN out_cur FOR	
		SELECT value_chain_report_pkg.ConvertToCubicMeter(w.amount, w.unit_id, w.unit_type) as amount, w.source_description as description
		  FROM v$ht_water_waste w
		 WHERE w.app_sid = security_pkg.getApp
		   AND w.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND w.category_id = in_consumption_category_id
		   AND w.type_id = in_consumption_type_id
		 ORDER BY amount DESC;  
END;

PROCEDURE GetTotalWasteBreakdowns( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetConsumptionSourceBreakdowns');
	END IF;
	--Get water and waste consumption breakdown values (or the default consumption when breakdowns do not exist)
	OPEN out_cur FOR	
		SELECT value_chain_report_pkg.ConvertToCubicMeter(SUM(w.amount), w.unit_id, w.unit_type) as amount, w.source_description as description
		  FROM v$ht_water_waste w
		 WHERE w.app_sid = security_pkg.getApp
		   AND w.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND w.category_id = consumption_pkg.WASTE
		 GROUP BY w.source_description, w.unit_id, w.unit_type --by convention the sources (and their measure) are the same for haz, non haz, otherwise a total waste chart will not have a meaning
		 ORDER BY amount DESC;
END;

FUNCTION SumProductsBySupplier(
	in_supplier_id      IN  supplier.supplier_id%TYPE
) RETURN v$ps_item.spend_in_dollars%TYPE
AS
	v_spend_in_dollars	v$ps_item.spend_in_dollars%TYPE;
	v_start_date	date;
	v_end_date      date;
BEGIN
	GetPeriodStartEnd(v_start_date, v_end_date);

	SELECT SUM(spend_in_dollars)
	  INTO v_spend_in_dollars
	  FROM v$ps_item
	 WHERE supplier_id = in_supplier_id
	   AND purchase_date >= v_start_date
	   AND purchase_date < v_end_date;
	 
	RETURN v_spend_in_dollars;
END;

FUNCTION ApportionSupplierBreakdown(
	in_cons_source_id			IN  ht_cons_source.ht_cons_source_id%TYPE,
	in_suppplier_company_sid	IN  company.company_sid%TYPE,
	in_supplier_id				IN	supplier.supplier_id%TYPE, 
	in_turnover					IN  company.turnover%TYPE,
	in_currency_id				IN  company.currency_id%TYPE,
	in_period_id				IN  company.period_id%TYPE	
) RETURN NUMBER
AS
	v_breakdown_amount		ht_cons_source_breakdown.amount%TYPE;
	v_unit_id          		volume_unit.volume_unit_id%TYPE;
	v_unit_type        		NUMBER; --either consumption_pkg.VOLUME_UNIT OR MASS_UNIT
	v_supplier_cons_amount  NUMBER;
	v_sum_of_products		NUMBER;
	v_supplier_turnover		NUMBER;
	v_apportioned_amount	NUMBER;
BEGIN
	--Selects consumption source amount for this source_id (unique per supplier company sid)
	BEGIN
		SELECT amount, unit_id, unit_type
		  INTO v_breakdown_amount, v_unit_id, v_unit_type
		  FROM v$ht_water_waste
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = in_suppplier_company_sid
		   AND source_id = in_cons_source_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;
	
	v_supplier_cons_amount	:= value_chain_report_pkg.ConvertToCubicMeter(v_breakdown_amount, v_unit_id, v_unit_type);--consumption amount of supplier's company
	v_sum_of_products	    := value_chain_report_pkg.SumProductsBySupplier(in_supplier_id); --sum of products (in dollars) purchased from the supplier in company's reporting period
	v_supplier_turnover     := in_turnover * util_pkg.GetConversionToDollar(in_currency_id, in_period_id); --suppliers turnover in dollars
	
	BEGIN
		IF v_sum_of_products > v_supplier_turnover THEN --normalize v_sum_of_products not to exceed v_supplier_turnover
			v_sum_of_products := v_supplier_turnover;
		END IF;
		v_apportioned_amount :=	 v_supplier_cons_amount *  v_sum_of_products / v_supplier_turnover;
	EXCEPTION
		WHEN ZERO_DIVIDE THEN
			RETURN 0;
	END;
	
	RETURN NVL(ROUND(v_apportioned_amount, 5), 0);
END;

PROCEDURE GetWaterApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetWaterApportBySupplier');
	END IF;
	
	--Get water consumption breakdown values (or the default water consumption when breakdowns do not exist)
	OPEN out_cur FOR	
		SELECT s.supplier_id,
			   s.name supplier_name,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.MAINS_WATER, s.company_sid,  s.supplier_id, c.turnover, c.currency_id, c.period_id) mains_water,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.SURFACE_WATER, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) surface_water,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.GROUNDWATER, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) groundwater,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.RAINWATER, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) rainwater,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.OTHER_WATER, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) other_water
		  FROM supplier s
		  JOIN company c ON (s.company_sid = c.company_sid) --s.company_sid = supplier's company
		 WHERE s.app_sid = security_pkg.getApp
		   AND s.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')--s.owner_company_sid = our compnay
		 ORDER BY mains_water + surface_water + groundwater + rainwater + other_water DESC;
		   
END;

PROCEDURE GetWasteWaterApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetWasteWaterApportBySupplier');
	END IF;
	
	--Get waste consumption breakdown values (or the default consumption when breakdowns do not exist)
	OPEN out_cur FOR	
		SELECT s.supplier_id,
			   s.name supplier_name,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.DOMESTIC_WASTEWATER, s.company_sid,  s.supplier_id, c.turnover, c.currency_id, c.period_id) domestic_wastewater,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.TRADE_EFFLUENT, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) trade_effluent,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.SURFACE_DRAINAGE, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) surface_drainage,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.DISCHARGE_TO_SURFACE_WATER, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) discharge_to_surface_water,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.EVAPORATION, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) evaporation,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.WATER_IN_PRODUCT, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) water_in_product,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.WATER_IN_WASTE, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) water_in_waste,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.OTHER_WATER_LOSSES, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) other_water_losses
		  FROM supplier s
		  JOIN company c ON (s.company_sid = c.company_sid) --s.company_sid = supplier's company
		 WHERE s.app_sid = security_pkg.getApp
		   AND s.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')--s.owner_company_sid = our compnay
		 ORDER BY domestic_wastewater + trade_effluent + surface_drainage + discharge_to_surface_water + evaporation + water_in_product + water_in_waste + other_water_losses DESC;
		   
END;

PROCEDURE GetWasteApportBySupplier( 
	in_breakdown_ids				IN  security_pkg.T_SID_IDS, -- not used - just for consistency of report interface
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for report data - GetWasteApportBySupplier');
	END IF;
	
	--Get TOTAL waste (nonHaz + Haz) consumption breakdown values (or the default consumption when breakdowns do not exist)
	OPEN out_cur FOR	
		SELECT s.supplier_id,
			   s.name supplier_name,
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.NH_RECYCLING, s.company_sid,  s.supplier_id, c.turnover, c.currency_id, c.period_id) +
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.H_RECYCLING, s.company_sid,  s.supplier_id, c.turnover, c.currency_id, c.period_id) recycling,
			   
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.NH_INCLUDING_ENERGY_RECOVERY, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) +
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.H_INCLUDING_ENERGY_RECOVERY, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) including_energy_recovery,
			   
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.NH_EXCLUDING_ENERGY_RECOVERY, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) +
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.H_EXCLUDING_ENERGY_RECOVERY, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) excluding_energy_recovery,
			   
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.NH_LANDFILL, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) +
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.H_LANDFILL, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) landfill,
			   
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.NH_OTHER_NON_HAZ, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) +
			   value_chain_report_pkg.ApportionSupplierBreakdown(consumption_pkg.H_OTHER_HAZ, s.company_sid, s.supplier_id, c.turnover, c.currency_id, c.period_id) other_haz
		  FROM supplier s
		  JOIN company c ON (s.company_sid = c.company_sid) --s.company_sid = supplier's company
		 WHERE s.app_sid = security_pkg.getApp
		   AND s.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')--s.owner_company_sid = our compnay
		 ORDER BY recycling + including_energy_recovery + excluding_energy_recovery	 + landfill + other_haz DESC;
		   
END;


END  value_chain_report_pkg;
/
