CREATE OR REPLACE PACKAGE BODY ct.consumption_pkg AS

PROCEDURE Internal_DeleteBreakdownsByCat(
	in_consumption_type_id			IN  ht_cons_source_breakdown.ht_consumption_type_id%TYPE,
	in_consumption_category_id		IN  ht_cons_source_breakdown.ht_consumption_category_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting Hotspot consumption source breakdown data');
	END IF;

	DELETE FROM ht_cons_source_breakdown
     WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND ht_consumption_type_id = in_consumption_type_id 
	   AND ht_consumption_category_id = in_consumption_category_id;
END;

PROCEDURE DeleteConsSourceBreakdown(
	in_consumption_type_id			IN  ht_cons_source_breakdown.ht_consumption_type_id%TYPE,
	in_consumption_category_id		IN  ht_cons_source_breakdown.ht_consumption_category_id%TYPE,
	in_cons_source_id				IN  ht_cons_source_breakdown.ht_cons_source_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting Hotspot consumption source breakdown data');
	END IF;

	DELETE FROM ht_cons_source_breakdown
     WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND ht_consumption_type_id = in_consumption_type_id 
	   AND ht_consumption_category_id = in_consumption_category_id
	   AND ht_cons_source_id = in_cons_source_id;
END;

PROCEDURE SetConsSourceBreakdown(
	in_consumption_type_id			IN  ht_cons_source_breakdown.ht_consumption_type_id%TYPE,
	in_consumption_category_id		IN  ht_cons_source_breakdown.ht_consumption_category_id%TYPE,
	in_cons_source_id				IN  ht_cons_source_breakdown.ht_cons_source_id%TYPE,
	in_amount						IN  ht_cons_source_breakdown.amount%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') || ' when setting Hotspot consumption source breakdown.');
	END IF;
	
	BEGIN
		INSERT INTO ht_cons_source_breakdown (app_sid, company_sid, ht_consumption_type_id, ht_consumption_category_id, ht_cons_source_id, amount)
			VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_consumption_type_id, in_consumption_category_id, in_cons_source_id, in_amount); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ht_cons_source_breakdown
			   SET amount = in_amount
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND ht_consumption_type_id = in_consumption_type_id 
			   AND ht_consumption_category_id = in_consumption_category_id
			   AND ht_cons_source_id = in_cons_source_id; 
	END;	
END;

PROCEDURE DeleteConsumptionRegion(
	in_consumption_type_id			IN  ht_consumption_region.ht_consumption_type_id%TYPE,
	in_region_id					IN  ht_consumption_region.region_id%TYPE,
	in_consumption_category_id		IN  ht_consumption_region.ht_consumption_category_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting Hotspot consumption region data');
	END IF;

	DELETE FROM ht_consumption_region
		WHERE app_sid = security_pkg.getApp
		  AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	      AND ht_consumption_type_id = in_consumption_type_id 
	      AND region_id = in_region_id
	      AND ht_consumption_category_id = in_consumption_category_id; 
END;

PROCEDURE SetConsumptionRegion(
	in_consumption_type_id			IN  ht_consumption_region.ht_consumption_type_id%TYPE,
	in_region_id					IN  ht_consumption_region.region_id%TYPE,
	in_consumption_category_id		IN  ht_consumption_region.ht_consumption_category_id%TYPE,
	in_amount						IN  ht_consumption_region.amount%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') || ' when setting Hotspot consumption region.');
	END IF;
	
	BEGIN
		INSERT INTO ht_consumption_region (app_sid, company_sid, ht_consumption_type_id, region_id, ht_consumption_category_id, amount)
			VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_consumption_type_id, in_region_id, in_consumption_category_id, in_amount); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ht_consumption_region
			   SET amount = in_amount
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND ht_consumption_type_id = in_consumption_type_id 
			   AND region_id = in_region_id
			   AND ht_consumption_category_id = in_consumption_category_id; 
	END;	
END;

PROCEDURE DeleteConsumption(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting Hotspot consumption data');
	END IF;
	
	CASE in_consumption_category_id
		--If Consumption Category is Electricity and is going to be deleted => initially, delete all country breakdowns (consumption_regions)
		WHEN ELECTRICITY THEN 
			DELETE FROM ht_consumption_region
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND ht_consumption_type_id = in_consumption_type_id 
			   AND ht_consumption_category_id = in_consumption_category_id; 
		WHEN WATER THEN 			
			Internal_DeleteBreakdownsByCat(in_consumption_type_id, in_consumption_category_id);
		WHEN WASTE THEN 			
			Internal_DeleteBreakdownsByCat(in_consumption_type_id, in_consumption_category_id);
		ELSE
			NULL; --no breakdowns for fuel, fugitive category
	END CASE;
	
	--Delete record
	DELETE FROM ht_consumption
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND ht_consumption_type_id = in_consumption_type_id 
	   AND ht_consumption_category_id = in_consumption_category_id; 
END;

PROCEDURE SetConsumption(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	in_amount						IN ht_consumption.amount%TYPE,	
	in_mass_unit_id					IN ht_consumption.mass_unit_id%TYPE,	
	in_power_unit_id				IN ht_consumption.power_unit_id%TYPE,	
	in_volume_unit_id				IN ht_consumption.volume_unit_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing Hotspot consumption data');
	END IF;
	
	BEGIN
		--Insert new values, update amount and unit fields in old ones
	    INSERT INTO ht_consumption (app_sid, company_sid, ht_consumption_type_id, ht_consumption_category_id, amount, mass_unit_id, power_unit_id, volume_unit_id)
			VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_consumption_type_id, in_consumption_category_id, in_amount, in_mass_unit_id, in_power_unit_id, in_volume_unit_id);
	EXCEPTION
	    WHEN DUP_VAL_ON_INDEX THEN
		   UPDATE ht_consumption
			  SET amount = in_amount, mass_unit_id = in_mass_unit_id, power_unit_id = in_power_unit_id, volume_unit_id = in_volume_unit_id
			WHERE app_sid = security_pkg.getApp
			  AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  AND ht_consumption_type_id = in_consumption_type_id 
			  AND ht_consumption_category_id = in_consumption_category_id; 
	END; 

END;

PROCEDURE GetConsumptionsByTypeAndCat(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,	
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,		
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT c.ht_consumption_type_id, c.ht_consumption_category_id, ct.description as consumption_description, c.amount, c.mass_unit_id, c.power_unit_id, c.volume_unit_id, co2_factor 
	  FROM v$ht_consumption c 
	  JOIN ht_consumption_type ct ON (c.ht_consumption_type_id = ct.ht_consumption_type_id AND c.ht_consumption_category_id = ct.ht_consumption_category_id)
	 WHERE c.app_sid = security_pkg.getApp
	   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (in_consumption_type_id IS NULL OR c.ht_consumption_type_id = in_consumption_type_id)
	   AND c.ht_consumption_category_id = in_consumption_category_id;
    
END;

PROCEDURE GetConsumptionsByCategory(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetConsumptionsByTypeAndCat(NULL, in_consumption_category_id, out_cur);
    
END;

PROCEDURE GetConsumptionTypesByCategory(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT ht_consumption_type_id, ht_consumption_category_id, description
	  FROM ht_consumption_type
	 WHERE ht_consumption_category_id = in_consumption_category_id;
    
END;

PROCEDURE GetConsumptionTypeUnitsByCat(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetConsumptionTypeUnits(NULL, in_consumption_category_id, out_cur);
END;

PROCEDURE GetConsumptionTypeUnits(
	in_consumption_type_id 			IN ht_consumption_type.ht_consumption_type_id%TYPE,
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT ht_consumption_type_id, ht_consumption_category_id, unit_id, unit_description, unit_symbol, unit_category, is_default
	  FROM
	   (
		 SELECT ht_consumption_type_id, ht_consumption_category_id, cmu.mass_unit_id as unit_id, description as unit_description, symbol as unit_symbol, MASS_UNIT as unit_category, cmu.is_default
		   FROM ht_consumption_type_mass_unit cmu 
		   JOIN mass_unit mu ON (cmu.mass_unit_id = mu.mass_unit_id)		  
		  UNION ALL		
		 SELECT ht_consumption_type_id, ht_consumption_category_id, tpu.power_unit_id as unit_id, description as unit_description, symbol as unit_symbol, POWER_UNIT as unit_category, tpu.is_default
		   FROM ht_consumption_type_power_unit tpu 
		   JOIN power_unit pu ON (tpu.power_unit_id = pu.power_unit_id)		  
		  UNION ALL		
		 SELECT ht_consumption_type_id, ht_consumption_category_id, vu.volume_unit_id as unit_id, description as unit_description, symbol as unit_symbol, VOLUME_UNIT as unit_category, tvu.is_default
		   FROM ht_consumption_type_vol_unit tvu 
		   JOIN volume_unit vu ON (tvu.volume_unit_id = vu.volume_unit_id)
	   )
     WHERE (in_consumption_type_id IS NULL OR ht_consumption_type_id = in_consumption_type_id)
	   AND ht_consumption_category_id = in_consumption_category_id
     ORDER BY unit_symbol;	 
END;


PROCEDURE GetConsumptionsRegionsByCateg(
	in_consumption_category_id 		IN ht_consumption_type.ht_consumption_category_id%TYPE,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT cr.ht_consumption_type_id, cr.ht_consumption_category_id, cr.region_id, r.description, r.country, cr.amount, CASE WHEN cr.region_id =0 THEN 1 ELSE 0 END as is_remainder 
	  FROM ht_consumption_region cr 
	  JOIN region r ON (cr.region_id = r.region_id)
	 WHERE cr.app_sid = security_pkg.getApp
	   AND cr.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND cr.ht_consumption_category_id = in_consumption_category_id;
    
END;

PROCEDURE GetConsumptionSources(
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT cs.ht_cons_source_id, cs.ht_consumption_type_id, cs.ht_consumption_category_id, cs.description, cs.is_remainder
	  FROM ht_cons_source cs 
	 WHERE cs.ht_consumption_category_id = in_consumption_category_id
	   AND cs.ht_consumption_type_id = in_consumption_type_id;
    
END;

PROCEDURE GetConsumptionSourceBreakdowns( 
	in_consumption_category_id 		IN ht_cons_source.ht_consumption_category_id%TYPE,	
	in_consumption_type_id			IN ht_cons_source.ht_consumption_type_id%TYPE,  	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
	SELECT csb.ht_cons_source_id, csb.ht_consumption_type_id, csb.ht_consumption_category_id, csb.amount, cs.description, cs.is_remainder
	  FROM ht_cons_source_breakdown csb 
	  JOIN ht_cons_source cs ON (cs.ht_cons_source_id = csb.ht_cons_source_id)
	 WHERE csb.app_sid = security_pkg.getApp
	   AND csb.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND csb.ht_consumption_category_id = in_consumption_category_id
	   AND csb.ht_consumption_type_id = in_consumption_type_id
	 ORDER BY cs.is_remainder DESC;
    
END;

END consumption_pkg;
/
