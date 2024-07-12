CREATE OR REPLACE PACKAGE BODY CSR.DELEG_REPORT_PKG AS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE GetDelegReport(
	in_deleg_report_sid		IN	deleg_report.deleg_report_sid%TYPE,
	out_deleg_report_cur	OUT	SYS_REFCURSOR,
	out_deleg_plan_cur		OUT	SYS_REFCURSOR,
	out_region_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_deleg_report_cur FOR
		SELECT deleg_report_sid, name, deleg_report_type_id, start_dtm, end_dtm,
			   period_set_id, period_interval_id
		  FROM deleg_report
		 WHERE deleg_report_sid = in_deleg_report_sid;
		 
	OPEN out_deleg_plan_cur FOR
		SELECT deleg_plan_sid
		  FROM deleg_report_deleg_plan
		 WHERE deleg_report_sid = in_deleg_report_sid;
		 
	OPEN out_region_cur FOR
		SELECT root_region_sid
		  FROM deleg_report_region
		 WHERE deleg_report_sid = in_deleg_report_sid;
END;

PROCEDURE GetDelegReportList(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT deleg_report_sid, name
		  FROM deleg_report;
END;

PROCEDURE INTERNAL_SaveReportPlans(
	in_deleg_report_sid		IN	security_pkg.T_SID_ID,
	in_deleg_plan_sids		IN	security_pkg.T_SID_IDS
)
AS
	t_plan_sids		security.T_SID_TABLE;
BEGIN
	t_plan_sids := security_pkg.SidArrayToTable(in_deleg_plan_sids);
	
	DELETE FROM deleg_report_deleg_plan WHERE deleg_report_sid = in_deleg_report_sid;
	
	INSERT INTO deleg_report_deleg_plan (deleg_report_sid, deleg_plan_sid)
	SELECT in_deleg_report_sid, column_value
	  FROM TABLE(t_plan_sids);
END;

PROCEDURE INTERNAL_SaveReportRegions(
	in_deleg_report_sid		IN	security_pkg.T_SID_ID,
	in_root_region_sids		IN	security_pkg.T_SID_IDS
)
AS
	t_region_sids		security.T_SID_TABLE;
BEGIN
	t_region_sids := security_pkg.SidArrayToTable(in_root_region_sids);
	
	DELETE FROM deleg_report_region WHERE deleg_report_sid = in_deleg_report_sid;
	
	INSERT INTO deleg_report_region (deleg_report_sid, root_region_sid)
	SELECT in_deleg_report_sid, column_value
	  FROM TABLE(t_region_sids);
END;

PROCEDURE SaveDelegReport(
	in_name					IN	deleg_report.name%TYPE,
	in_deleg_rpt_type_id	IN	deleg_report.deleg_report_type_id%TYPE,
	in_start_dtm			IN	deleg_report.start_dtm%TYPE,
	in_end_dtm				IN	deleg_report.end_dtm%TYPE,
	in_period_set_id		IN	deleg_report.period_set_id%TYPE,
	in_period_interval_id	IN	deleg_report.period_interval_id%TYPE,
	in_deleg_plan_sids		IN	security_pkg.T_SID_IDS,
	in_region_sids			IN	security_pkg.T_SID_IDS,
	in_overwrite			IN	NUMBER,
	out_deleg_rpt_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_act	security.security_pkg.T_ACT_ID := security_pkg.GetACT;
	v_app	security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF in_overwrite = 0 THEN
		group_pkg.CreateGroupWithClass(v_act, security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Delegation Reports'), security_pkg.GROUP_TYPE_SECURITY,
			Replace(in_name,'/','\'), class_pkg.getClassID('CSRDelegationReport'), out_deleg_rpt_sid); --'
		
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(out_deleg_rpt_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, out_deleg_rpt_sid, security_pkg.PERMISSION_STANDARD_READ);

		INSERT INTO deleg_report(app_sid, deleg_report_sid, name, deleg_report_type_id, start_dtm, end_dtm, period_set_id, period_interval_id)
		VALUES (v_app, out_deleg_rpt_sid, in_name, in_deleg_rpt_type_id, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id);

		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app, out_deleg_rpt_sid,
			'Created "{0}"', in_name);
	ELSE
		SELECT deleg_report_sid
		  INTO out_deleg_rpt_sid
		  FROM deleg_report
		 WHERE name = in_name;
		 
		UPDATE deleg_report
		   SET deleg_report_type_id = in_deleg_rpt_type_id,
			   start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   period_set_id = in_period_set_id,
			   period_interval_id = in_period_interval_id
		 WHERE deleg_report_sid = out_deleg_rpt_sid;
	END IF;
		
	INTERNAL_SaveReportPlans(out_deleg_rpt_sid, in_deleg_plan_sids);
	INTERNAL_SaveReportRegions(out_deleg_rpt_sid, in_region_sids);
END;

PROCEDURE UpdateDelegReport(
	in_deleg_report_sid		IN	security_pkg.T_SID_ID,
	in_name					IN	deleg_report.name%TYPE,
	in_deleg_rpt_type_id	IN	deleg_report.deleg_report_type_id%TYPE,
	in_start_dtm			IN	deleg_report.start_dtm%TYPE,
	in_end_dtm				IN	deleg_report.end_dtm%TYPE,
	in_period_set_id		IN	deleg_report.period_set_id%TYPE,
	in_period_interval_id	IN	deleg_report.period_interval_id%TYPE,
	in_deleg_plan_sids		IN	security_pkg.T_SID_IDS,
	in_region_sids			IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	UPDATE deleg_report
	   SET name = in_name,
		   deleg_report_type_id = in_deleg_rpt_type_id,
		   start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   period_set_id = period_set_id,
		   period_interval_id = in_period_interval_id
	 WHERE deleg_report_sid = in_deleg_report_sid;
	 
	INTERNAL_SaveReportPlans(in_deleg_report_sid, in_deleg_plan_sids);
	INTERNAL_SaveReportRegions(in_deleg_report_sid, in_region_sids);
END;

PROCEDURE INTERNAL_GetStatusNames(
	t_deleg_plans	IN security.T_SID_TABLE,
	out_cur			OUT SYS_REFCURSOR
)
AS
	v_max_status	NUMBER;
	t_statuses	security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT MAX(max_status) INTO v_max_status
	  FROM (
			SELECT dp.deleg_plan_sid, dp.name, count(*) max_status
			  FROM deleg_plan dp
			  JOIN deleg_plan_role dpr ON dp.deleg_plan_sid = dpr.deleg_plan_sid
			 WHERE dp.deleg_plan_sid IN (SELECT column_value FROM TABLE (t_deleg_plans))
			 GROUP BY dp.deleg_plan_sid, dp.name
			);

	t_statuses.extend(v_max_status + 1);
	FOR i IN 0 .. v_max_status LOOP
		t_statuses(i+1) := i;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT column_value status,
			   -- Hard-coded with values for Heineken for now
			   CASE column_value WHEN 0 THEN 'Closed' ELSE 'Pending Tier ' || column_value END label
		  FROM TABLE(t_statuses);
END;

PROCEDURE GetStatusesByDelegPlan(
	in_start_dtm		IN deleg_report.start_dtm%TYPE,
	in_end_dtm			IN deleg_report.end_dtm%TYPE,
	in_root_region_sids	IN security_pkg.T_SID_IDS,
	in_deleg_plan_sids	IN security_pkg.T_SID_IDS,
	out_data_cur		OUT SYS_REFCURSOR,
	out_labels_cur		OUT SYS_REFCURSOR
)
AS
	t_root_regions	security.T_SID_TABLE;
	t_deleg_plans	security.T_SID_TABLE;
	v_max_status	NUMBER;	
BEGIN
	t_root_regions := security_pkg.SidArrayToTable(in_root_region_sids);
	t_deleg_plans := security_pkg.SidArrayToTable(in_deleg_plan_sids);

	INTERNAL_GetStatusNames(t_deleg_plans, out_labels_cur);
	
	OPEN out_data_cur FOR
		WITH dp AS (
				SELECT dp.deleg_plan_sid, dp.name, dp.max_status, dpdrd.maps_to_root_deleg_sid
				  FROM (
						SELECT dp.deleg_plan_sid, dp.name, count(*) max_status
						  FROM deleg_plan dp
						  JOIN deleg_plan_role dpr ON dp.deleg_plan_sid = dpr.deleg_plan_sid
						 WHERE dp.deleg_plan_sid IN (SELECT column_value FROM TABLE (t_deleg_plans))
						 GROUP BY dp.deleg_plan_sid, dp.name
						) dp
				  JOIN deleg_plan_col dpc ON dp.deleg_plan_sid = dpc.deleg_plan_sid
				  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region dpdr ON dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpdr.region_sid = dpdrd.region_sid
				 WHERE dpdr.region_sid IN (
						SELECT region_sid
						  FROM region
							START WITH region_sid IN (SELECT column_value FROM TABLE (t_root_regions))
							CONNECT BY parent_sid = PRIOR region_sid
						)
				)
			SELECT deleg_plan_sid id, name description, status, count(*) sheet_count
			  FROM (
					SELECT dp.deleg_plan_sid, dp.name, sla.start_dtm, sla.end_dtm,
						   MAX(
							CASE
								WHEN sla.last_action_id IN (csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_SUBMITTED) THEN 0
								ELSE 1
							END * d.tier) status
					  FROM dp
					  JOIN (
							SELECT CONNECT_BY_ROOT(delegation_sid) root_delegation_sid, LEVEL tier, delegation_sid
							  FROM delegation
								START WITH delegation_sid in (SELECT maps_to_root_deleg_sid FROM dp)
								CONNECT BY parent_sid = PRIOR delegation_sid
							) d ON dp.maps_to_root_deleg_sid = d.root_delegation_sid AND dp.max_status >= d.tier
					  JOIN sheet_with_last_action sla ON d.delegation_sid = sla.delegation_sid AND start_dtm >= in_start_dtm AND end_dtm <= in_end_dtm
					 GROUP BY dp.deleg_plan_sid, dp.name, sla.start_dtm, sla.end_dtm, dp.maps_to_root_deleg_sid
					)
			 GROUP BY deleg_plan_sid, name, status;
END;

PROCEDURE GetStatusesByRegion(
	in_start_dtm		IN deleg_report.start_dtm%TYPE,
	in_end_dtm			IN deleg_report.end_dtm%TYPE,
	in_root_region_sids	IN security_pkg.T_SID_IDS,
	in_deleg_plan_sids	IN security_pkg.T_SID_IDS,
	out_data_cur		OUT SYS_REFCURSOR,
	out_labels_cur		OUT SYS_REFCURSOR
)
AS
	t_root_regions	security.T_SID_TABLE;
	t_deleg_plans	security.T_SID_TABLE;
	v_max_status	NUMBER;
BEGIN
	t_root_regions := security_pkg.SidArrayToTable(in_root_region_sids);
	t_deleg_plans := security_pkg.SidArrayToTable(in_deleg_plan_sids);

	INTERNAL_GetStatusNames(t_deleg_plans, out_labels_cur);
	
	OPEN out_data_cur FOR
		WITH dp AS (
				SELECT dp.deleg_plan_sid, dp.name, dp.max_status, dpdr.region_sid, dpdrd.maps_to_root_deleg_sid
				  FROM (
						SELECT dp.deleg_plan_sid, dp.name, count(*) max_status
						  FROM deleg_plan dp
						  JOIN deleg_plan_role dpr ON dp.deleg_plan_sid = dpr.deleg_plan_sid
						 WHERE dp.deleg_plan_sid IN (SELECT column_value FROM TABLE (t_deleg_plans))
						 GROUP BY dp.deleg_plan_sid, dp.name
						) dp
				  JOIN deleg_plan_col dpc ON dp.deleg_plan_sid = dpc.deleg_plan_sid
				  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region dpdr ON dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpdr.region_sid = dpdrd.region_sid
				 WHERE dpdr.region_sid IN (
						SELECT region_sid
						  FROM region
							START WITH region_sid IN (SELECT column_value FROM TABLE (t_root_regions))
							CONNECT BY parent_sid = PRIOR region_sid
						)
				)
			SELECT root_region_sid id, description, status, count(*) sheet_count
			  FROM (
					SELECT r.root_region_sid, r.description, sla.start_dtm, sla.end_dtm,
						   MAX(
							CASE
								WHEN sla.last_action_id IN (csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_SUBMITTED) THEN 0
								ELSE 1
							END * d.tier) status
					  FROM dp
					  JOIN (
							SELECT CONNECT_BY_ROOT(region_sid) root_region_sid, CONNECT_BY_ROOT(description) description, r.region_sid
							  FROM v$region r
								START WITH region_sid IN (SELECT column_value FROM TABLE (t_root_regions))
								CONNECT BY parent_sid = PRIOR region_sid
							) r ON dp.region_sid = r.region_sid
					  JOIN (
							SELECT CONNECT_BY_ROOT(delegation_sid) root_delegation_sid, LEVEL tier, delegation_sid
							  FROM delegation
								START WITH delegation_sid in (SELECT maps_to_root_deleg_sid FROM dp)
								CONNECT BY parent_sid = PRIOR delegation_sid
							) d ON dp.maps_to_root_deleg_sid = d.root_delegation_sid AND dp.max_status >= d.tier
					  JOIN sheet_with_last_action sla ON d.delegation_sid = sla.delegation_sid AND start_dtm >= in_start_dtm AND end_dtm <= in_end_dtm
					 GROUP BY r.root_region_sid, r.description, sla.start_dtm, sla.end_dtm, dp.maps_to_root_deleg_sid
					)
			 GROUP BY root_region_sid, description, status;
END;

END;
/