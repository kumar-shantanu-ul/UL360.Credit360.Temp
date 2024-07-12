CREATE OR REPLACE PACKAGE BODY CSR.target_dashboard_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
) AS
BEGIN	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		UPDATE target_dashboard
		   SET name = in_new_name
		 WHERE target_dashboard_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
) AS
BEGIN
	DELETE FROM target_dashboard_ind_member
	 WHERE target_dashboard_sid = in_sid_id;

	DELETE FROM target_dashboard_reg_member
	 WHERE target_dashboard_sid = in_sid_id;

	DELETE FROM target_dashboard_value
	 WHERE target_dashboard_sid = in_sid_id;

	DELETE FROM target_dashboard
	 WHERE target_dashboard_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE target_dashboard
	   SET parent_sid = in_new_parent_sid_id 
	 WHERE target_dashboard_sid = in_sid_id;
END;

PROCEDURE CreateDashboard(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	target_dashboard.name%TYPE,
	in_start_dtm					IN	target_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	target_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	target_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	target_dashboard.period_interval_id%TYPE,
	in_use_root_region_sid			IN	target_dashboard.use_root_region_sid%TYPE,
	out_dashboard_sid_id			OUT security_pkg.T_SID_ID
)
AS
BEGIN				 
	SecurableObject_Pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.getClassID('CSRDashboard'), REPLACE(in_name,'/','\'), out_Dashboard_sid_id); --'
	INSERT INTO target_dashboard 
		(target_dashboard_sid, parent_sid, name, start_dtm, end_dtm,
		 period_set_id, period_interval_id, use_root_region_sid)
	VALUES 
		(out_dashboard_sid_id, in_parent_sid, in_name, in_start_dtm, in_end_dtm,
		 in_period_set_id, in_period_interval_id, in_use_root_region_sid);
END;

PROCEDURE AmendDashboard(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	target_dashboard.name%TYPE,
	in_start_dtm					IN	target_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	target_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	target_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	target_dashboard.period_interval_id%TYPE,
	in_use_root_region_sid			IN	target_dashboard.use_root_region_sid%TYPE
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;
	UPDATE target_dashboard
	   SET start_dtm = in_start_dtm,
	   	   end_dtm = in_end_dtm,
	   	   period_set_id = in_period_set_id,
	   	   period_interval_id = in_period_interval_id,
		   name = in_name,
		   use_root_region_sid = in_use_root_region_sid
	 WHERE target_dashboard_sid = in_dashboard_sid;
	 
	 securableobject_pkg.RenameSO(in_act_id, in_dashboard_sid, REPLACE(in_name,'/','\')); --'
END;

PROCEDURE ClearMembers(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;

	-- bit drastic but makes it easier to update
	-- might need to change in future if we put in some FK constraints!!
	DELETE FROM target_dashboard_ind_member
	 WHERE target_dashboard_sid = in_dashboard_sid;
	DELETE FROM target_dashboard_reg_member
	 WHERE target_dashboard_sid = in_dashboard_sid;
END;

PROCEDURE GetIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;

	-- should we be checking the security on the indicators?
	OPEN out_cur FOR	 
		SELECT i.description, m.name measure_name, i.measure_sid, i.active, tdim.pos,
			   NVL(i.format_mask, m.format_mask) format_mask, 
			   NVL(i.scale, m.scale) scale,
			   i.divisibility actual_divisibility,
			   NVL(i.divisibility, m.divisibility) divisibility,
			   calc_start_dtm_adjustment, calc_end_dtm_adjustment, pct_lower_tolerance, pct_upper_tolerance, tolerance_type,
			   i.target_direction,	TO_CHAR(i.last_modified_dtm,'yyyy-mm-dd hh24:mi:ss') last_modified,
			   m.description measure_description, i.ind_sid, i.name,
			   i.calc_xml, i.ind_type,
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, 
			   i.calc_description, i.aggregate, i.parent_sid,
			   extract(i.info_xml,'/').getClobVal() info_xml, 
			   i.start_month, i.gri,
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid,
			   i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key,
			   i.calc_output_round_dp
		  FROM target_dashboard_ind_member tdim, v$ind i, measure m
		 WHERE tdim.target_dashboard_sid = in_dashboard_sid
		   AND tdim.app_sid = i.app_sid AND tdim.ind_sid = i.ind_sid
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		 ORDER BY tdim.pos;
END;

PROCEDURE GetRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
    CURSOR check_perm_cur IS
        SELECT region_sid
          FROM target_dashboard_reg_member
         WHERE target_dashboard_sid = in_dashboard_sid
           AND security_pkg.sql_IsAccessAllowedSID(in_act_id, region_sid, security_pkg.PERMISSION_READ) = 0;
    v_region_sid number(10);
BEGIN							   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;

    -- Check the permissions on all the regions in this range. We want to throw an exception rather 
    -- than return missing regions which would only confuse the users.
    OPEN check_perm_cur;
    FETCH check_perm_cur INTO v_region_sid;
    IF check_perm_cur%FOUND THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
        	'Read access denied on the rarget dashboard with sid '||in_dashboard_sid||' and region with sid '||v_region_sid);
    END IF;

	OPEN out_cur FOR
		SELECT tdrm.region_sid, r.parent_sid, tdrm.pos, r.description, r.active, r.name, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, 
			   r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM target_dashboard_reg_member tdrm, v$region r
		 WHERE tdrm.target_dashboard_sid = in_dashboard_sid
		   AND tdrm.app_sid = r.app_sid AND tdrm.region_sid = r.region_sid
		 ORDER BY tdrm.pos;
END;

-- set association between and indicator and the relevant target indicator
PROCEDURE AddIndTargetSid(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_target_sid					IN	security_pkg.T_SID_ID
)
AS
	v_max_pos						target_dashboard_ind_member.pos%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;	
			
	SELECT NVL(MAX(pos),0)
	  INTO v_max_pos 
	  FROM target_dashboard_ind_member
	 WHERE target_dashboard_sid = in_dashboard_sid;
	
	INSERT INTO target_dashboard_ind_member
		(target_dashboard_sid, ind_sid, target_ind_sid, pos)
	VALUES 
		(in_dashboard_sid, in_ind_sid, in_target_sid, v_max_pos + 1);
END;

PROCEDURE AddRegion(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID
)	
AS						
	v_max_pos	NUMBER; 
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;	
			
	SELECT NVL(MAX(pos),0)
	  INTO v_max_pos
	  FROM target_dashboard_reg_member 
	 WHERE target_dashboard_sid = in_dashboard_sid;
		
	INSERT INTO target_dashboard_reg_member 
		(target_dashboard_sid, region_sid, pos)
	VALUES 
		(in_dashboard_sid, in_region_sid, v_max_pos + 1);
END;

PROCEDURE GetTargetSid(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_target_ind_sid				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;

	BEGIN	
		SELECT target_ind_sid
		  INTO out_target_ind_sid
		  FROM target_dashboard_ind_member
		 WHERE target_dashboard_sid = in_dashboard_sid
		   AND ind_sid = in_ind_sid
		   AND target_ind_sid IS NOT NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_target_ind_sid := -1;
	END;
END;

PROCEDURE GetTargetSids(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ti.ind_sid, ti.target_ind_sid, i.description
		  FROM target_dashboard_ind_member ti, v$ind i
		 WHERE ti.target_dashboard_sid = in_dashboard_sid 
		   AND ti.app_sid = i.app_sid
		   AND ti.target_ind_sid = i.ind_sid;
END;

PROCEDURE GetDashboard(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,	 
	out_cur							OUT SYS_REFCURSOR
) 
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT name, start_dtm, end_dtm, period_set_id, period_interval_id, use_root_region_sid
		  FROM target_dashboard
		 WHERE target_dashboard_sid = in_dashboard_sid;	
END;

PROCEDURE GetDashboardTargetsForInd(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid	 					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
) 
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;

	OPEN out_cur FOR
		SELECT val_number, region_sid 
		  FROM target_dashboard_value
		 WHERE target_dashboard_sid = in_dashboard_sid 
	 	   AND ind_sid = in_ind_sid;	
END;

PROCEDURE GetDashboardList(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_parent_sid					IN 	security_pkg.T_SID_ID,	 
	in_order_by						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
) 
AS
	v_order_by						VARCHAR2(1000);
	v_parent_sid					security_pkg.T_SID_ID;
	v_children						security.T_SO_TABLE;
BEGIN
	v_parent_sid := COALESCE(in_parent_sid, securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Dashboards'));

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'List contents access denied on the folder dashboard with sid '||v_parent_sid);
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'name,start_dtm,end_dtm,interval');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	v_children := securableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_parent_sid, 1);
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM target_dashboard td, TABLE(v_children) soc
	 WHERE td.target_dashboard_sid = soc.sid_id;

	OPEN out_cur FOR
		'SELECT * '||
		  'FROM ('||
				'SELECT rownum rn, x.* '||
				
				  'FROM ('||
						'SELECT td.target_dashboard_sid, td.name, td.start_dtm, td.end_dtm, '||
							   'td.period_set_id, td.period_interval_id, td.use_root_region_sid '||
						  'FROM target_dashboard td, TABLE(:1) soc '||
						 'WHERE td.target_dashboard_sid = soc.sid_id' || 
						 v_order_by ||
					   ') x '||
				 'WHERE rownum <= :v_limit'||
			    ')'||
		 'WHERE rn > :v_start_row'
	USING v_children, in_start_row + in_page_size, in_start_row;
END;

PROCEDURE SetDashboardTarget(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid	 					IN	security_pkg.T_SID_ID,
	in_region_sid	 				IN	security_pkg.T_SID_ID,
	in_val_number	 				IN	target_dashboard_value.val_number%TYPE
) 
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the target dashboard with sid '||in_dashboard_sid);
	END IF;
	
	IF in_val_number IS NULL THEN
		DELETE FROM target_dashboard_value
		 WHERE target_dashboard_sid = in_dashboard_sid
		   AND ind_sid = in_ind_sid
		   AND region_sid = in_region_sid;
	ELSE
		BEGIN
			INSERT INTO target_dashboard_value 
				(target_dashboard_sid, ind_sid, region_sid, val_number)
			VALUES
				(in_dashboard_sid, in_ind_sid, in_region_sid, in_val_number);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE target_dashboard_value
				   SET val_number = in_val_number
				 WHERE target_dashboard_sid = in_dashboard_sid
				   AND ind_sid = in_ind_sid
				   AND region_sid = in_region_sid; 
		END;
	END IF;
END;

END;
/
