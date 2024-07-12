CREATE OR REPLACE PACKAGE BODY ct.breakdown_group_pkg AS

PROCEDURE CheckAdminSecurityByGroupKey(
	in_group_key				IN  breakdown_group.group_key%TYPE
)
AS
	v_capability				ct_pkg.T_CAPABILITY;
BEGIN
	CASE in_group_key
		WHEN 'EC' THEN
			v_capability := ct_pkg.ADMIN_EMPLOYEE_COMMUTING;
		WHEN 'BT' THEN
			v_capability := ct_pkg.ADMIN_BUSINESS_TRAVEL;
		WHEN 'PS' THEN	
			v_capability := ct_pkg.ADMIN_PRODUCTS_SERVICES;
		WHEN 'UP' THEN	
			v_capability := ct_pkg.ADMIN_USE_PHASE;
	END CASE;

	IF NOT csr.csr_data_pkg.CheckCapability(v_capability) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify '||in_group_key||' data');
	END IF;
END;

PROCEDURE CheckEditSecurityByGroupKey(
	in_group_key				IN  breakdown_group.group_key%TYPE
)
AS
	v_capability				ct_pkg.T_CAPABILITY;
BEGIN
	CASE in_group_key
		WHEN 'EC' THEN
			v_capability := ct_pkg.EDIT_EMPLOYEE_COMMUTING;
		WHEN 'BT' THEN
			v_capability := ct_pkg.EDIT_BUSINESS_TRAVEL;
		WHEN 'PS' THEN	
			v_capability := ct_pkg.EDIT_PRODUCTS_SERVICES;
		WHEN 'UP' THEN	
			v_capability := ct_pkg.EDIT_USE_PHASE;
	END CASE;

	IF NOT csr.csr_data_pkg.CheckCapability(v_capability) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify '||in_group_key||' data');
	END IF;
END;

FUNCTION GetKeyFromGroupId(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE
) RETURN VARCHAR2
AS
	v_ret			VARCHAR2(40);
BEGIN	
	SELECT group_key
	  INTO v_ret
	  FROM breakdown_group
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND breakdown_group_id = in_breakdown_group_id;

	RETURN v_ret;
END;

PROCEDURE CheckAdminSecurityByGroupId(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE
)
AS
BEGIN
	CheckAdminSecurityByGroupKey(GetKeyFromGroupId(in_breakdown_group_id));
END;

PROCEDURE CheckEditSecurityByGroupId(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE
)
AS
BEGIN
	CheckEditSecurityByGroupKey(GetKeyFromGroupId(in_breakdown_group_id));
END;

PROCEDURE GetBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckEditSecurityByGroupId(in_breakdown_group_id);

	OPEN out_cur FOR
		SELECT breakdown_group_id,
		       breakdown_type_id,
			   is_default,
			   name, 
			   company_sid
		  FROM breakdown_group
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetBreakdownGroups(
	in_group_key				IN  breakdown_group.group_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	--CheckEditSecurityByGroupKey(in_group_key);
	-- TO DO - pus this back - edit permission seems wrong for read operation
	
	OPEN out_cur FOR
		SELECT breakdown_group_id,
		       breakdown_type_id,
			   is_default,
			   name
		  FROM breakdown_group
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND group_key = in_group_key
		   AND deleted = 0;
END;

PROCEDURE GetGroupBreakdownRegions(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckEditSecurityByGroupId(in_breakdown_group_id);

	OPEN out_cur FOR
		SELECT brg.breakdown_group_id,
		       brg.breakdown_id,
		       brg.region_id,
			   CASE WHEN bt.is_region = 1 THEN r.description ELSE b.description || ' - ' || r.description END as full_description,
			   b.description breakdown_description,
			   r.description,
			   b.breakdown_type_id, 
			   br.pct,
			   b.fte * br.pct / 100 fte,
			   br.fte_travel
		  FROM breakdown_region_group brg, breakdown_region br, breakdown b, region r, breakdown_group bg, breakdown_type bt
		 WHERE brg.app_sid = security_pkg.getApp
		   AND brg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')		   
		   AND brg.region_id = br.region_id
		   AND brg.breakdown_id = br.breakdown_id
		   AND brg.breakdown_group_id = in_breakdown_group_id
		   AND brg.breakdown_id = b.breakdown_id
		   AND brg.region_id = r.region_id
		   AND brg.breakdown_group_id = bg.breakdown_group_id
		   AND bg.breakdown_type_id = bt.breakdown_type_id;
END;

PROCEDURE SetBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	in_breakdown_type_id		IN  breakdown_group.breakdown_type_id%TYPE,
	in_is_default				IN  breakdown_group.is_default%TYPE,
	in_name						IN  breakdown_group.name%TYPE,
	in_group_key				IN  breakdown_group.group_key%TYPE,
	out_breakdown_group_id		OUT breakdown_group.breakdown_group_id%TYPE
)
AS
BEGIN
	CheckAdminSecurityByGroupKey(in_group_key);
	
	IF in_breakdown_group_id IS NULL THEN
		INSERT INTO breakdown_group (app_sid, company_sid, breakdown_group_id, breakdown_type_id, is_default, name, group_key)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), 
				     breakdown_group_id_seq.NEXTVAL, in_breakdown_type_id, in_is_default, in_name, in_group_key)
		  RETURNING breakdown_group_id INTO out_breakdown_group_id;

	ELSE
		UPDATE breakdown_group
		   SET breakdown_type_id = in_breakdown_type_id,
			   is_default = in_is_default,
			   name = in_name,
			   group_key = in_group_key
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		out_breakdown_group_id := in_breakdown_group_id;
	 END IF;

END;

PROCEDURE SetGroupBreakdownRegion(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	in_breakdown_id				IN  breakdown_region_group.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_group.breakdown_id%TYPE
)
AS
BEGIN
	CheckAdminSecurityByGroupId(in_breakdown_group_id);
	
	BEGIN
		INSERT INTO breakdown_region_group (app_sid, company_sid, breakdown_group_id, breakdown_id, region_id)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), 
				     in_breakdown_group_id, in_breakdown_id, in_region_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Do nothing, as data is already there
			NULL;
	END;
END;

PROCEDURE DeleteBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE
)
AS
BEGIN
	DeleteBreakdownGroup(in_breakdown_group_id, 0);
END;

PROCEDURE DeleteBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	in_delete_fully				IN  NUMBER
)
AS
BEGIN
	IF in_delete_fully <> 1 THEN
	
		CheckAdminSecurityByGroupId(in_breakdown_group_id);
		
		UPDATE breakdown_group
		   SET deleted = 1
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
	
	ELSE
	
		DELETE FROM ct.breakdown_region_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
				   
		DELETE FROM ct.bt_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.ec_bus_entry
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.ec_car_entry
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.ec_motorbike_entry
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.ec_train_entry
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.ec_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
		
		DELETE FROM ct.breakdown_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND breakdown_group_id = in_breakdown_group_id;
	
	END IF;
END;

PROCEDURE DeleteGroupBreakdownRegion(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	in_breakdown_id				IN  breakdown_region_group.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_group.breakdown_id%TYPE
)
AS
BEGIN
	CheckAdminSecurityByGroupId(in_breakdown_group_id);
	
	DELETE FROM breakdown_region_group
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND breakdown_group_id = in_breakdown_group_id
			AND breakdown_id = in_breakdown_id
			AND region_id = in_region_id;
END;

END breakdown_group_pkg;
/
