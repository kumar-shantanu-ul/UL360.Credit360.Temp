CREATE OR REPLACE PACKAGE BODY ct.breakdown_type_pkg AS

FUNCTION GetHSRegionBreakdownTypeId (
	in_company_sid			IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN	

	BEGIN
		SELECT breakdown_type_id
		  INTO v_ret
		  FROM v$hs_breakdown_type	  
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = in_company_sid
		   AND is_region = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;

	RETURN v_ret;
END;

FUNCTION GetVCRegionBreakdownTypeId (
	in_company_sid			IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN	

	BEGIN
		SELECT breakdown_type_id
		  INTO v_ret
		  FROM v$breakdown_type	  
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = in_company_sid
		   AND is_region = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;

	RETURN v_ret;
END;

PROCEDURE GetHSBreakdownTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetHSBreakdownTypes(null, out_cur);
END;

PROCEDURE GetHSBreakdownTypes(
	in_company_sid					IN  company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetHSBreakdownTypes(in_company_sid, 0, out_cur);
END;

PROCEDURE GetHSBreakdownTypes(
	in_company_sid					IN  company.company_sid%TYPE,
	in_ignore_region				IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN

	OPEN out_cur FOR
		SELECT breakdown_type_id, company_sid, singular, plural, is_region
		  FROM v$hs_breakdown_type
		 WHERE app_sid = security_pkg.getApp
		   AND breakdown_type_id IN (SELECT breakdown_type_id FROM breakdown WHERE app_sid = security_pkg.getApp AND company_sid = NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND (is_region = 0 OR in_ignore_region = 0)
		   AND company_sid = NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		 ORDER BY is_region DESC, plural; 
END;

PROCEDURE GetHSRegionBreakdownType(
	in_company_sid					IN  company.company_sid%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_breakdown_type_id	v$hs_breakdown_type.breakdown_type_id%TYPE;
BEGIN
	v_region_breakdown_type_id := GetHSRegionBreakdownTypeId(in_company_sid);

	GetHSBreakdownType(v_region_breakdown_type_id, out_cur);
END;

PROCEDURE GetHSBreakdownType(
	in_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM v$hs_breakdown_type
	 WHERE breakdown_type_id = in_breakdown_type_id;

	IF v_company_sid IS NOT NULL OR in_breakdown_type_id <> GetHSRegionBreakdownTypeId(v_company_sid) THEN
		IF NOT chain.capability_pkg.CheckCapability(v_company_sid, chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||v_company_sid);
		END IF;
	END IF;
	
	OPEN out_cur FOR 
		SELECT breakdown_type_id, company_sid, singular, plural, by_turnover, by_fte, is_region, rest_of
		  FROM v$hs_breakdown_type
		 WHERE breakdown_type_id = in_breakdown_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  ORDER BY breakdown_type_id;
END;

PROCEDURE GetBreakdownType(
	in_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: add security for value chain, doesn't really fall under employee commute/business travel
	
	OPEN out_cur FOR 
		SELECT breakdown_type_id, company_sid, singular, plural, by_turnover, by_fte, is_region, rest_of
		  FROM v$breakdown_type
		 WHERE breakdown_type_id = in_breakdown_type_id
		   AND app_sid = security_pkg.getApp
	  ORDER BY breakdown_type_id;
END;

PROCEDURE GetBreakdownTypes(
	in_ignore_region				IN  NUMBER,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: add security for value chain, doesn't really fall under employee commute/business travel
	
	OPEN out_cur FOR
		SELECT breakdown_type_id, company_sid, singular, plural, by_turnover, by_fte, is_region, rest_of
		  FROM v$breakdown_type
		 WHERE app_sid = security_pkg.getApp
		   AND breakdown_type_id IN (SELECT breakdown_type_id FROM breakdown WHERE app_sid = security_pkg.getApp AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND (is_region = 0 OR in_ignore_region = 0)
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY is_region DESC, plural; 
END;

PROCEDURE SetHSBreakdownType(
	in_breakdown_type_id		IN  v$hs_breakdown_type.breakdown_type_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_singular					IN  v$hs_breakdown_type.singular%TYPE,
	in_plural					IN  v$hs_breakdown_type.plural%TYPE,
	in_by_turnover				IN  v$hs_breakdown_type.by_turnover%TYPE,
	in_by_fte					IN  v$hs_breakdown_type.by_fte%TYPE,
	in_is_region				IN  v$hs_breakdown_type.is_region%TYPE,
	in_rest_of					IN  v$hs_breakdown_type.rest_of%TYPE,
	out_breakdown_type_id		OUT v$hs_breakdown_type.breakdown_type_id%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	IF in_breakdown_type_id IS NULL THEN
		INSERT INTO breakdown_type (app_sid, company_sid, breakdown_type_id, singular, plural, by_turnover, by_fte, is_region, rest_of, is_hotspot)
		     VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_company_sid, breakdown_type_id_seq.NEXTVAL, in_singular,
			        in_plural, in_by_turnover, in_by_fte, in_is_region, in_rest_of, 1)
		  RETURNING breakdown_type_id INTO out_breakdown_type_id;
	ELSE
		UPDATE breakdown_type
		   SET breakdown_type_id = in_breakdown_type_id,
			   company_sid = in_company_sid,
			   singular = in_singular,
			   plural = in_plural,
			   by_turnover = in_by_turnover,
			   by_fte = in_by_fte,
			   is_region = in_is_region,
			   rest_of = in_rest_of, 
			   is_hotspot = 1
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND breakdown_type_id = in_breakdown_type_id;
		
		out_breakdown_type_id := in_breakdown_type_id;
	 END IF;
END;

PROCEDURE DeleteBreakdownType(
	in_breakdown_type_id		IN  v$hs_breakdown_type.breakdown_type_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM breakdown_type
		 WHERE breakdown_type_id = in_breakdown_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- we'll let this fall through as it won't actually affect anything 
			-- in the end and is probably due to someone else having changed the same thing
			-- at the same time
			RETURN;
	END;
	
	IF NOT chain.capability_pkg.CheckCapability(v_company_sid, chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||v_company_sid);
	END IF;
	
	FOR r IN (
		SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = in_breakdown_type_id
	) LOOP
		breakdown_pkg.DeleteBreakdown(r.breakdown_id, 0);
	END LOOP;
	
	FOR r IN (
		SELECT breakdown_group_id FROM breakdown_group WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND breakdown_type_id = in_breakdown_type_id
	) LOOP
		breakdown_group_pkg.DeleteBreakdownGroup(r.breakdown_group_id, 1);
	END LOOP;	
	
	DELETE FROM ct.ec_bus_entry
	 WHERE (app_sid,company_sid,breakdown_group_id) IN (
	    SELECT app_sid,company_sid,breakdown_group_id
	      FROM ct.ec_profile
	     WHERE (app_sid,company_sid,breakdown_group_id) IN (
	        SELECT app_sid,company_sid,breakdown_group_id
	          FROM ct.breakdown_group
	         WHERE (app_sid,breakdown_type_id) IN (
	            SELECT app_sid,breakdown_type_id	
		          FROM ct.breakdown_type
	             WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	               AND breakdown_type_id = in_breakdown_type_id
	        )
	    )
	);
	
	DELETE FROM ct.ec_car_entry
	 WHERE (app_sid,company_sid,breakdown_group_id) IN (
	    SELECT app_sid,company_sid,breakdown_group_id
	      FROM ct.ec_profile
	     WHERE (app_sid,company_sid,breakdown_group_id) IN (
	        SELECT app_sid,company_sid,breakdown_group_id
	          FROM ct.breakdown_group
	         WHERE (app_sid,breakdown_type_id) IN (
	            SELECT app_sid,breakdown_type_id	
		          FROM ct.breakdown_type
	             WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	               AND breakdown_type_id = in_breakdown_type_id
	        )
	    )
	);
	
	DELETE FROM ct.ec_motorbike_entry
	 WHERE (app_sid,company_sid,breakdown_group_id) IN (
	    SELECT app_sid,company_sid,breakdown_group_id
	      FROM ct.ec_profile
	     WHERE (app_sid,company_sid,breakdown_group_id) IN (
	        SELECT app_sid,company_sid,breakdown_group_id
	          FROM ct.breakdown_group
	         WHERE (app_sid,breakdown_type_id) IN (
	            SELECT app_sid,breakdown_type_id	
	              FROM ct.breakdown_type
	             WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	               AND breakdown_type_id = in_breakdown_type_id
	        )
	    )
	);
	
	DELETE FROM ct.ec_train_entry
	 WHERE (app_sid,company_sid,breakdown_group_id) IN (
	    SELECT app_sid,company_sid,breakdown_group_id
	      FROM ct.ec_profile
	     WHERE (app_sid,company_sid,breakdown_group_id) IN (
	        SELECT app_sid,company_sid,breakdown_group_id
	          FROM ct.breakdown_group
	         WHERE (app_sid,breakdown_type_id) IN (
	            SELECT app_sid,breakdown_type_id	
   		          FROM ct.breakdown_type
	             WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	               AND breakdown_type_id = in_breakdown_type_id
	        )
	    )
	);
	
	DELETE FROM ct.bt_options
	 WHERE (app_sid,breakdown_type_id) IN (
	    SELECT app_sid,breakdown_type_id
	      FROM ct.breakdown_type
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND breakdown_type_id = in_breakdown_type_id
	);
	
	DELETE FROM ct.ec_options
	 WHERE (app_sid,breakdown_type_id) IN (
	    SELECT app_sid,breakdown_type_id
	      FROM ct.breakdown_type
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND breakdown_type_id = in_breakdown_type_id
	);
	
	DELETE FROM ct.ps_options
	 WHERE (app_sid,breakdown_type_id) IN (
	    SELECT app_sid,breakdown_type_id
	      FROM ct.breakdown_type
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND breakdown_type_id = in_breakdown_type_id
	);
	
	DELETE FROM ct.up_options
	 WHERE (app_sid,breakdown_type_id) IN (
	    SELECT app_sid,breakdown_type_id
	      FROM ct.breakdown_type
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND breakdown_type_id = in_breakdown_type_id
	);
	
	DELETE FROM ct.breakdown_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND breakdown_type_id = in_breakdown_type_id;

END;
	
END breakdown_type_pkg;
/
