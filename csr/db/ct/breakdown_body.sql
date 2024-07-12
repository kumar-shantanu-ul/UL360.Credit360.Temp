CREATE OR REPLACE PACKAGE BODY ct.breakdown_pkg AS

PROCEDURE GetBreakdown(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdowns(in_company_sid, in_breakdown_id, null, out_cur);
END;

PROCEDURE GetRegionBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdowns(in_company_sid, null, breakdown_type_pkg.GetHSRegionBreakdownTypeId(in_company_sid), out_cur);
END;

PROCEDURE GetBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdowns(in_company_sid, null, in_breakdown_type, out_cur);
END;

PROCEDURE GetBreakdowns(
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdowns(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), null, in_breakdown_type, out_cur);
END;
	
PROCEDURE GetBreakdowns(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_breakdown_type			IN  breakdown.breakdown_type_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_breakdown_type_id			breakdown.breakdown_type_id%TYPE DEFAULT in_breakdown_type;
BEGIN
	IF v_breakdown_type_id = 0 THEN
		v_breakdown_type_id := NULL;
	END IF;
	
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_cur FOR 
		SELECT app_sid, breakdown_id, breakdown_type_id, company_sid, description, fte, turnover, 
		       fte_travel, is_remainder, region_id
		  FROM breakdown
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND breakdown_id = NVL(in_breakdown_id, breakdown_id)
		   AND breakdown_type_id = NVL(v_breakdown_type_id, breakdown_type_id)
	     ORDER BY breakdown_id;
END;

PROCEDURE GetBreakdownRegions(
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	in_is_hotspot				IN  breakdown_type.is_hotspot%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
		
	OPEN out_cur FOR 
		SELECT br.app_sid, 
		       br.breakdown_id,
		       br.region_id,
		       br.pct,
			   CASE WHEN bt.is_region = 1 THEN r.description ELSE b.description || ' - ' || r.description END as full_description,
			   b.description breakdown_description,
			   r.description,
			   b.breakdown_type_id,
			   b.is_remainder is_breakdown_remainder,
			   b.fte * (br.pct/100) fte, 
			   NVL(spend, 0) spend, 
			   br.fte_travel
		  FROM breakdown_region br, breakdown b, region r, breakdown_type bt, ps_spend_breakdown psb
		 WHERE br.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND br.breakdown_id = NVL(in_breakdown_id, br.breakdown_id)
		   AND br.breakdown_id = b.breakdown_id
		   AND br.region_id = r.region_id
		   AND b.breakdown_type_id = bt.breakdown_type_id
		   AND br.breakdown_id = psb.breakdown_id (+)
		   AND br.region_id = psb.region_id (+)
		   AND bt.is_hotspot = NVL(in_is_hotspot, bt.is_hotspot)
		ORDER BY region_id;
END;

PROCEDURE GetHSBreakdownRegions(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdownRegions(null, 1, out_cur);
END; 

PROCEDURE GetBreakdownRegions(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdownRegions(null, 0, out_cur);
END; 

PROCEDURE GetBreakdownRegions(
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBreakdownRegions(in_breakdown_id, null, out_cur);
END;

PROCEDURE GetBreakdownEios(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	OPEN out_cur FOR
		SELECT be.breakdown_id, be.eio_id, be.region_id, eio.description, be.pct, be.fte, be.turnover
		  FROM breakdown_region_eio be
		  JOIN eio eio 
		    ON be.eio_id = eio.eio_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND be.breakdown_id = in_breakdown_id
		   AND be.region_id = in_region_id
	  ORDER BY breakdown_id;
END;

PROCEDURE GetTotalFteTravel(
	out_total_fte_travel		OUT breakdown.fte_travel%TYPE
)
AS
	v_region_breakdown_type_id	v$hs_breakdown_type.breakdown_type_id%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	v_region_breakdown_type_id := breakdown_type_pkg.GetHSRegionBreakdownTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	
	SELECT SUM(fte_travel) 
	  INTO out_total_fte_travel
	  FROM breakdown
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND breakdown_type_id = v_region_breakdown_type_id;
END;

PROCEDURE SetGroupRegionEios (
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region.region_id%TYPE
)
AS
BEGIN	
	-- Copy eio region breakdowns from country breakdown, if they exist
	BEGIN
		FOR r IN (
			SELECT eio_id, pct
			  FROM breakdown_region_eio
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_id = in_region_id				
			   AND breakdown_id IN (
					SELECT b.breakdown_id
					  FROM breakdown b
					  JOIN v$hs_breakdown_type bt
						ON b.breakdown_type_id = bt.breakdown_type_id
					 WHERE bt.is_region = 1
					   AND b.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   AND b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
		) LOOP		
			BEGIN
				INSERT INTO breakdown_region_eio (app_sid, breakdown_id, eio_id, region_id, pct, fte, turnover)
				     VALUES	(SYS_CONTEXT('SECURITY', 'APP'), in_breakdown_id, r.eio_id, in_region_id, r.pct, 0, 0); -- TEMP - fte, turnover is temp - TO DO - see notes in UpdateBreakdownRegionsAndEio
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE breakdown_region_eio
					   SET pct = r.pct
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
					   AND breakdown_id = in_breakdown_id 
					   AND region_id = in_region_id
					   AND eio_id = r.eio_id;	
			END;
		END LOOP;
	END;

	-- If they don't exist, create eio breakdown region based on their main company eio
	INSERT INTO breakdown_region_eio (app_sid, breakdown_id, eio_id, region_id, pct, fte, turnover)(
		SELECT app_sid, in_breakdown_id, eio_id, in_region_id, 100, 0, 0 -- TEMP - fte, turnover is temp - TO DO - see notes in UpdateBreakdownRegionsAndEio
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND in_region_id NOT IN(
				SELECT region_id
				  FROM breakdown_region_eio
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_id = in_region_id
				   AND breakdown_id = in_breakdown_id
			)
	);
END;

PROCEDURE UpdateAllGroupRegionEios
AS
BEGIN
	FOR r IN (
		SELECT br.breakdown_id, br.region_id
		  FROM breakdown_region br, breakdown b, v$hs_breakdown_type bt
		 WHERE br.breakdown_id = b.breakdown_id
		   AND b.breakdown_type_id = bt.breakdown_type_id
		   AND bt.is_region = 0
		   AND br.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	) LOOP		
		BEGIN
			DeleteBreakdownEio(r.breakdown_id, null, r.region_id);	
			SetGroupRegionEios(r.breakdown_id, r.region_id);
			UpdateBreakdownRegionsAndEio(r.breakdown_id);
		END;
	END LOOP;
END;
	
PROCEDURE SetBreakdownRegion (
	in_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region.region_id%TYPE,
	in_pct						IN  breakdown_region.pct%TYPE
)
AS
	v_is_region					v$hs_breakdown_type.is_region%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	BEGIN
		INSERT INTO breakdown_region (app_sid, breakdown_id, region_id, pct, fte_travel)
		     VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_breakdown_id, in_region_id, in_pct, 0); -- fte_travel - TEMP - TO DO - see notes in UpdateBreakdownRegionsAndEio
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE breakdown_region
			   SET pct = in_pct
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND breakdown_id = in_breakdown_id 
			   AND region_id = in_region_id;	
	END;
	
	SELECT bt.is_region INTO v_is_region
	  FROM v$hs_breakdown_type bt
	  JOIN breakdown b
	    ON bt.breakdown_type_id = b.breakdown_type_id
	 WHERE b.breakdown_id = in_breakdown_id;
	
	IF v_is_region = 0 THEN
		SetGroupRegionEios(in_breakdown_id, in_region_id);
	END IF;
	
	UpdateBreakdownRegionsAndEio(in_breakdown_id);
END;

PROCEDURE SetBreakdown (
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_description				IN  breakdown.description%TYPE,
	in_fte						IN  breakdown.fte%TYPE,
	in_turnover					IN  breakdown.turnover%TYPE,
	in_fte_travel				IN  breakdown.fte_travel%TYPE,
	in_is_remainder				IN  breakdown.is_remainder%TYPE,
	in_region_id				IN  breakdown.region_id%TYPE,
	out_breakdown_id			OUT breakdown.breakdown_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	v_company_sid := COALESCE(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

	IF in_breakdown_id IS NULL THEN
		INSERT INTO breakdown (app_sid, breakdown_id, breakdown_type_id, company_sid, description, 
		            fte, turnover, fte_travel, is_remainder, region_id)
		     VALUES (SYS_CONTEXT('SECURITY', 'APP'), breakdown_id_seq.NEXTVAL, in_breakdown_type_id,
		            v_company_sid, in_description, in_fte, in_turnover, in_fte_travel, in_is_remainder, in_region_id)
		  RETURNING breakdown_id INTO out_breakdown_id;
	ELSE
		UPDATE breakdown
		   SET breakdown_type_id = in_breakdown_type_id,
			   company_sid = v_company_sid,
			   description = in_description,
			   fte = in_fte,
			   turnover = in_turnover,
			   fte_travel = in_fte_travel,
			   is_remainder = in_is_remainder,
			   region_id = in_region_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_id = in_breakdown_id;
		
		out_breakdown_id := in_breakdown_id;
	 END IF;
	 
	UpdateBreakdownRegionsAndEio(out_breakdown_id);
	
	supplier_pkg.SetSupplierStatus(in_company_sid, ct_pkg.SS_COMPLETEDBYSUPPLIER);
END;

PROCEDURE SetBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	in_pct						IN  breakdown_region_eio.pct%TYPE
)
AS
	v_is_region					v$hs_breakdown_type.is_region%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	BEGIN
		INSERT INTO breakdown_region_eio (app_sid, breakdown_id, eio_id, region_id, pct, fte, turnover)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_breakdown_id, in_eio_id, in_region_id, in_pct, 0, 0); -- TEMP - fte, turnover is temp - TO DO - see notes in UpdateBreakdownRegionsAndEio
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE breakdown_region_eio
			   SET pct = in_pct
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND breakdown_id = in_breakdown_id 
			   AND eio_id = in_eio_id
			   AND region_id = in_region_id;
	END;
	
	SELECT bt.is_region INTO v_is_region
	  FROM v$hs_breakdown_type bt
	  JOIN breakdown b
	    ON bt.breakdown_type_id = b.breakdown_type_id
	 WHERE b.breakdown_id = in_breakdown_id;
	
	IF v_is_region = 1 THEN
		UpdateAllGroupRegionEios();
	END IF;

	UpdateBreakdownRegionsAndEio(in_breakdown_id);
END;

PROCEDURE DeleteBreakdown(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE
)
AS
BEGIN
	DeleteBreakdown(in_breakdown_id, 1);
END;

PROCEDURE DeleteBreakdown(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_do_recalc				IN  NUMBER
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	FOR b IN (
		SELECT breakdown_id, region_id
		  FROM breakdown_region
		 WHERE breakdown_id = in_breakdown_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		DeleteBreakdownRegion(b.breakdown_id, b.region_id, in_do_recalc);
	END LOOP;
	
	DELETE FROM worksheet_value_map_breakdown
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id;

	DELETE FROM breakdown
	      WHERE breakdown_id = in_breakdown_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteBreakdownRegion(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE
)
AS
BEGIN
	DeleteBreakdownRegion(in_breakdown_id, in_region_id, 1);
END;

PROCEDURE DeleteBreakdownRegion(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	in_do_recalc				IN  NUMBER
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	FOR b IN (
		SELECT breakdown_id, eio_id, region_id
		  FROM breakdown_region_eio
		 WHERE breakdown_id = in_breakdown_id
		   AND region_id = in_region_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		DeleteBreakdownEio(b.breakdown_id, b.eio_id, b.region_id, in_do_recalc);
	END LOOP;
	
	DELETE FROM breakdown_region_group
	      WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	        AND breakdown_id = in_breakdown_id
	        AND region_id = in_region_id;

	DELETE FROM bt_emissions
	      WHERE breakdown_id  = in_breakdown_id
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');	
			
	DELETE FROM ec_emissions_all
	      WHERE breakdown_id  = in_breakdown_id
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			
	DELETE FROM ps_emissions_all
	      WHERE breakdown_id  = in_breakdown_id
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM ec_questionnaire_answers
	 WHERE (app_sid,company_sid,ec_questionnaire_id) IN (
	    SELECT app_sid,company_sid,ec_questionnaire_id
	      FROM ct.ec_questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_id = in_breakdown_id
		   AND region_id = in_region_id
	    );
	
	DELETE FROM ec_questionnaire
	      WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	        AND breakdown_id = in_breakdown_id
	        AND region_id = in_region_id;

	DELETE FROM ps_item_eio
	 WHERE (app_sid, company_sid, item_id) IN (
	    SELECT app_sid, company_sid, item_id
	      FROM ps_item
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_id = in_breakdown_id
		   AND region_id = in_region_id
	    );
			
	DELETE FROM ps_item
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;

	DELETE FROM ps_spend_breakdown
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;
			
	DELETE FROM bt_air_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;
	
	DELETE FROM bt_bus_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;	

	DELETE FROM bt_cab_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;
	
	DELETE FROM bt_car_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;
	
	DELETE FROM bt_motorbike_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;
			
	DELETE FROM bt_train_trip
	 	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND breakdown_id = in_breakdown_id
		    AND region_id = in_region_id;

	DELETE FROM breakdown_region
	      WHERE breakdown_id  = in_breakdown_id
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE
)
AS
BEGIN
	DeleteBreakdownEio(in_breakdown_id, in_eio_id, in_region_id, 1);
END;

PROCEDURE DeleteBreakdownEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE,
	in_eio_id					IN  breakdown_region_eio.eio_id%TYPE,
	in_region_id				IN  breakdown_region_eio.region_id%TYPE,
	in_do_recalc				IN  NUMBER
)
AS
	v_is_region					v$hs_breakdown_type.is_region%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	DELETE FROM hotspot_result
	      WHERE breakdown_id = in_breakdown_id
	        AND eio_id = NVL(in_eio_id, eio_id)
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM breakdown_region_eio
	      WHERE breakdown_id  = in_breakdown_id
	        AND eio_id = NVL(in_eio_id, eio_id)
	        AND region_id = in_region_id
	        AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF in_do_recalc <> 0 THEN
		SELECT bt.is_region INTO v_is_region
		  FROM breakdown_type bt
		  JOIN breakdown b
			ON bt.breakdown_type_id = b.breakdown_type_id
		 WHERE b.breakdown_id = in_breakdown_id;

		-- For region breakdowns, we then need to update corresponding group eio breakdowns
		IF v_is_region = 1 THEN	
			UpdateAllGroupRegionEios();
		END IF;

		UpdateBreakdownRegionsAndEio(in_breakdown_id);
	END IF;
END;

-- TEMP - duping Fte/travel_pct/turnover down structure 
-- filling in the fte_travel on breakdown_region and the fte and turnover on breakdown_region_eio based on %
PROCEDURE UpdateBreakdownRegionsAndEio(
	in_breakdown_id				IN  breakdown.breakdown_id%TYPE
)
AS
	v_breakdown_fte_travel		breakdown.fte_travel%TYPE;
	v_breakdown_turnover		breakdown.turnover%TYPE;	
	v_breakdown_fte				breakdown.fte%TYPE;
BEGIN
	SELECT fte_travel, turnover, fte
	  INTO v_breakdown_fte_travel, v_breakdown_turnover, v_breakdown_fte
	  FROM breakdown
	 WHERE breakdown_id = in_breakdown_id
	   AND app_sid = security_pkg.GetApp;

	-- TEMP - duping Fte/travel_pct/turnover down structure 
	-- update breakdown_region_eio fte, turnover too
	FOR br IN (
		SELECT region_id, pct 
		  FROM breakdown_region
		 WHERE breakdown_id = in_breakdown_id
	)
	LOOP
	
		UPDATE breakdown_region
		   SET fte_travel = ROUND((br.pct/100) * v_breakdown_fte_travel, 10)
		 WHERE breakdown_id = in_breakdown_id
		   AND region_id = br.region_id;
	
		FOR bre IN (
			SELECT eio_id, pct 
			  FROM breakdown_region_eio 
			 WHERE breakdown_id = in_breakdown_id
			   AND region_id = br.region_id
		)
		LOOP
		   UPDATE breakdown_region_eio
			  SET 
				  fte = ROUND((br.pct/100) * (bre.pct/100) * v_breakdown_fte,10),-- TEMP - this will be whole nums soon
				  turnover = ROUND((br.pct/100) * (bre.pct/100) * v_breakdown_turnover, 10) -- TEMP - this will be whole nums soon
			WHERE breakdown_id = in_breakdown_id
			  AND region_id = br.region_id
			  AND eio_id = bre.eio_id
			  AND app_sid = security_pkg.GetApp;
		END LOOP;	
	END LOOP;
END;

PROCEDURE UpdateGroupBreakdownTurnover (
	in_turnover_change			IN  breakdown.turnover%TYPE
)
AS
	v_pool_value				NUMBER(25);
	v_new_pool_value			NUMBER(25);
	v_old_sum					NUMBER(25);
	v_new_sum					NUMBER(25);
	v_lowest_turnover			NUMBER(25);
	v_max_reduction				NUMBER(25);
	v_remainder					NUMBER(25);
BEGIN
	-- FOREACH GROUP BREAKDOWN
	FOR bt IN (
		SELECT breakdown_type_id
		  FROM v$hs_breakdown_type
		 WHERE is_region = 0
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		SELECT turnover 
		  INTO v_pool_value
		  FROM breakdown
	     WHERE breakdown_type_id = bt.breakdown_type_id
		   AND is_remainder = 1
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		v_new_pool_value := v_pool_value + in_turnover_change;
		
		-- IF WE CAN TAKE FROM THE POOL, DO IT, ELSE 
		-- EMPTY POOL AND SCALE OTHER BREAKDOWNS
		IF v_new_pool_value >= 0 THEN
			UPDATE breakdown
			   SET turnover = v_new_pool_value
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 1
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		ELSE
			--IF POOL EMPTY WITH MORE TO TAKE
			UPDATE breakdown
			   SET turnover = 0
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 1
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
			--SCALE REMAINING VALUES
			SELECT SUM(turnover) INTO v_old_sum
			  FROM breakdown
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');			
			
			-- SET VALUE TO MAINTAIN PERCENTAGE WITH NEW TOTAL
			UPDATE breakdown
			   SET turnover = floor((turnover / v_old_sum) * (v_old_sum + v_new_pool_value))
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 0
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			   
			-- GET THE REMAINDER AS WE USED FLOORS ABOVE TO KEEP INTEGERS
			SELECT SUM(turnover), MIN(turnover) INTO v_new_sum, v_lowest_turnover
			  FROM breakdown
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND turnover != 0
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			   
			v_remainder := (v_old_sum + v_new_pool_value) - v_new_sum;
			
			-- APPLY REMAINDER TO BREAKDOWNS
			FOR b IN (
				SELECT breakdown_id, turnover
				  FROM breakdown
				 WHERE breakdown_type_id = bt.breakdown_type_id
			  ORDER BY turnover DESC
			)
			LOOP			
				v_max_reduction := floor(b.turnover / v_lowest_turnover);
				
				IF v_remainder <= v_max_reduction THEN			
					UPDATE breakdown
					   SET turnover = b.turnover + v_remainder
					 WHERE breakdown_id = b.breakdown_id
					   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
					   
					v_remainder := 0;
				ELSE
					UPDATE breakdown
					   SET turnover = b.turnover + v_max_reduction
					 WHERE breakdown_id = b.breakdown_id
					   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
					   
					v_remainder := v_remainder - v_max_reduction;
				END IF;
				
				EXIT WHEN v_remainder <= 0;
			END LOOP;			
		END IF;
	END LOOP;			
END;

PROCEDURE UpdateGroupBreakdownFte (
	in_fte_change				IN  breakdown.fte%TYPE
)
AS
	v_pool_value				NUMBER(25);
	v_new_pool_value			NUMBER(25);
	v_old_sum					NUMBER(25);
	v_new_sum					NUMBER(25);
	v_lowest_fte				NUMBER(25);
	v_max_reduction				NUMBER(25);
	v_remainder					NUMBER(25);
BEGIN
	-- FOREACH GROUP BREAKDOWN
	FOR bt IN (
		SELECT breakdown_type_id
		  FROM v$hs_breakdown_type
		 WHERE is_region = 0
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		SELECT fte INTO v_pool_value
		  FROM breakdown
	     WHERE breakdown_type_id = bt.breakdown_type_id
		   AND is_remainder = 1
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		v_new_pool_value := v_pool_value + in_fte_change;
		
		-- IF WE CAN TAKE FROM THE POOL, DO IT, ELSE 
		-- EMPTY POOL AND SCALE OTHER BREAKDOWNS
		IF v_new_pool_value >= 0 THEN
			UPDATE breakdown
			   SET fte = v_new_pool_value
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 1
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		ELSE
			--IF POOL EMPTY WITH MORE TO TAKE
			UPDATE breakdown
			   SET fte = 0
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 1
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
			--SCALE REMAINING VALUES
			SELECT SUM(fte) INTO v_old_sum
			  FROM breakdown
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');			
			
			-- SET VALUE TO MAINTAIN PERCENTAGE WITH NEW TOTAL
			UPDATE breakdown
			   SET fte = floor((fte / v_old_sum) * (v_old_sum + v_new_pool_value))
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND is_remainder = 0
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			   
			-- GET THE REMAINDER AS WE USED FLOORS ABOVE TO KEEP INTEGERS
			SELECT SUM(fte), MIN(fte) INTO v_new_sum, v_lowest_fte
			  FROM breakdown
			 WHERE breakdown_type_id = bt.breakdown_type_id
			   AND fte != 0
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			   
			v_remainder := (v_old_sum + v_new_pool_value) - v_new_sum;
			
			-- APPLY REMAINDER TO BREAKDOWNS
			FOR b IN (
				SELECT breakdown_id, fte
				  FROM breakdown
				 WHERE breakdown_type_id = bt.breakdown_type_id
			  ORDER BY fte DESC
			)
			LOOP			
				v_max_reduction := floor(b.fte / v_lowest_fte);
				
				IF v_remainder <= v_max_reduction THEN			
					UPDATE breakdown
					   SET fte = b.fte + v_remainder
					 WHERE breakdown_id = b.breakdown_id
					   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
					   
					v_remainder := 0;
				ELSE
					UPDATE breakdown
					   SET fte = b.fte + v_max_reduction
					 WHERE breakdown_id = b.breakdown_id
					   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
					   
					v_remainder := v_remainder - v_max_reduction;
				END IF;
				
				EXIT WHEN v_remainder <= 0;
			END LOOP;			
		END IF;
	END LOOP;			
END;
	
END breakdown_pkg;
/
