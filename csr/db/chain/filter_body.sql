CREATE OR REPLACE PACKAGE BODY chain.filter_pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);


PROCEDURE DeleteFilter_UNSEC (in_filter_id IN filter.filter_id%TYPE, in_app_sid IN security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP'));
PROCEDURE DeleteFilterField_UNSEC (in_filter_field_id IN filter_field.filter_field_id%TYPE, in_app_sid IN security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP'));
PROCEDURE DeleteCompoundFilter_UNSEC (in_compound_filter_id IN compound_filter.compound_filter_id%TYPE, in_app_sid IN security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP'));

-- store user date so we don't have to fetch a user's timezone per row in a query
m_user_date			DATE;
m_user_timezone		VARCHAR2(100);

/*********************************************************************************/
/**********************   SO PROCS   *********************************************/
/*********************************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Only require ACLs to lock down this method, or do we?
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
BEGIN
	IF in_new_name IS NOT NULL THEN
		UPDATE saved_filter
		   SET name = in_new_name
		 WHERE saved_filter_sid = in_sid_id;
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
	v_grp_by_compound_filter_id	compound_filter.compound_filter_id%TYPE;
BEGIN
	-- No security as ACLs will already have been checked before getting here
	
	SELECT compound_filter_id, group_by_compound_filter_id
	  INTO v_compound_filter_id, v_grp_by_compound_filter_id
	  FROM saved_filter
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM filter_value
	 WHERE saved_filter_sid_value = in_sid_id;
	
	DELETE FROM saved_filter_sent_alert
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM saved_filter_alert_subscriptn
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM saved_filter_alert
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM saved_filter_aggregation_type
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM saved_filter_region
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM saved_filter_column
	 WHERE saved_filter_sid = in_sid_id;
	
	DELETE FROM csr.approval_dashboard_tpl_tag
	 WHERE (app_sid, tpl_report_sid, tag) IN (
		SELECT trt.app_sid, trt.tpl_report_sid, trt.tag
		  FROM csr.tpl_report_tag trt, csr.tpl_report_tag_logging_form trtlf
		 WHERE trt.app_sid = trtlf.app_sid AND trt.tpl_report_tag_logging_form_id = trtlf.tpl_report_tag_logging_form_id
		   AND trtlf.saved_filter_sid = in_sid_id);
		   
	DELETE FROM csr.tpl_report_tag
	 WHERE (app_sid, tpl_report_tag_logging_form_id) IN (
		SELECT app_sid, tpl_report_tag_logging_form_id
		  FROM csr.tpl_report_tag_logging_form 
	     WHERE saved_filter_sid = in_sid_id);

	DELETE FROM csr.tpl_report_tag_logging_form
	 WHERE saved_filter_sid = in_sid_id;

	DELETE FROM csr.tpl_report_tag
	 WHERE (app_sid, tpl_report_tag_dataview_id) IN (
		SELECT app_sid, tpl_report_tag_dataview_id
		  FROM csr.tpl_report_tag_dataview
	     WHERE saved_filter_sid = in_sid_id);

	DELETE FROM csr.tpl_report_tag_dataview
	 WHERE saved_filter_sid = in_sid_id;
	
	 FOR r IN (
 		SELECT compound_filter_id
 		  FROM compound_filter
 		 WHERE read_only_saved_filter_sid = in_sid_id
 	) LOOP
 		DeleteCompoundFilter_UNSEC(r.compound_filter_id);
 	END LOOP;
	
	DELETE FROM saved_filter
	 WHERE saved_filter_sid = in_sid_id;
	
	DeleteCompoundFilter_UNSEC(v_compound_filter_id);
	DeleteCompoundFilter_UNSEC(v_grp_by_compound_filter_id);

END;


PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE saved_filter
	   SET parent_sid = in_new_parent_sid_id
	 WHERE saved_filter_sid = in_sid_id;
END;

/**********************************************************************************/
/********************** Session callbacks *****************************************/
/**********************************************************************************/
PROCEDURE OnSessionMigrated (
	in_old_act_id					IN security_pkg.T_ACT_ID,
	in_new_act_id					IN security_pkg.T_ACT_ID
) AS
BEGIN
	UPDATE compound_filter
	   SET act_id = in_new_act_id
	 WHERE act_id = in_old_act_id;
END;

PROCEDURE OnSessionDeleted (
	in_old_act_id					IN security_pkg.T_ACT_ID
) AS
BEGIN
	-- TODO: What security checks can we do to know it's the session tidying up?
	FOR r IN (
		SELECT c.compound_filter_id, c.app_sid
		  FROM compound_filter c
		  LEFT JOIN filter_value fv ON c.compound_filter_id = fv.compound_filter_id_value
		 WHERE c.act_id = in_old_act_id
		 ORDER BY CASE WHEN fv.compound_filter_id_value IS NULL THEN 0 ELSE 1 END
		 
	) LOOP
		DeleteCompoundFilter_UNSEC(r.compound_filter_id, r.app_sid);
	END LOOP;
END;

/**********************************************************************************/
/********************** Clean up filters ******************************************/
/**********************************************************************************/

PROCEDURE DeleteFiltersForTabSid (
	in_act 						IN	security_pkg.T_ACT_ID,
	in_tab_sid 					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Delete any saved filters for tab
	FOR r IN (
		SELECT sv.saved_filter_sid
		  FROM chain.saved_filter sv
		  JOIN cms.tab_column tc ON sv.cms_id_column_sid = tc.column_sid AND sv.app_sid = tc.app_sid
		 WHERE tc.tab_sid = in_tab_sid
	) LOOP
		securableobject_pkg.DeleteSO(in_act, r.saved_filter_sid);
	END LOOP;
	
	-- Delete any session filters for tab
	-- We don't know what filters relate to what tabs, but we do know what fields
	-- relate to what columns
	FOR r IN (
		SELECT ff.filter_field_id
		  FROM filter_field ff 
		  JOIN cms.tab_column tc ON ff.column_sid = tc.column_sid AND ff.app_sid = tc.app_sid
		 WHERE tc.tab_sid = in_tab_sid
	) LOOP
		DeleteFilterField_UNSEC(r.filter_field_id);
	END LOOP;
	
END;

/*********************************************************************************/
/**********************   LOGGING			     *********************************/
/*********************************************************************************/

FUNCTION StartDebugLog(
	in_label							IN  debug_log.label%TYPE,
	in_object_id						IN  debug_log.object_id%TYPE DEFAULT NULL
) RETURN NUMBER
AS
	v_debug_log_id						debug_log.debug_log_id%TYPE;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	-- no security, any session can log
	
	-- only log when they have a row in debug_act
	FOR r IN (
		SELECT act_id
		  FROM debug_act
		 WHERE act_id = security.security_pkg.GetAct
	) LOOP
		INSERT INTO debug_log (debug_log_id, label, object_id)
			 VALUES (debug_log_id_seq.NEXTVAL, in_label, in_object_id)
		  RETURNING debug_log_id INTO v_debug_log_id;
	END LOOP;

	COMMIT;

	RETURN v_debug_log_id;
END;

PROCEDURE EndDebugLog(
	in_debug_log_id					IN  debug_log.debug_log_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	-- no security, any session can log
	UPDATE debug_log
	   SET end_dtm = SYSTIMESTAMP
	 WHERE debug_log_id = in_debug_log_id;

	COMMIT;
END;

PROCEDURE DebugACT
AS
BEGIN
	-- no security, any session can be debugged
	BEGIN
		INSERT INTO debug_act (app_sid, act_id)
		     VALUES (security_pkg.GetApp, security_pkg.GetACT);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; -- already active
	END;
END;

/**********************************************************************************/
/********************** Configuration *********************************************/
/**********************************************************************************/

-- Register a filter type in the system
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
)
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
	v_card_id				card.card_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateFilterType can only be run as BuiltIn/Administrator');
	END IF;
	
	v_card_id := card_pkg.GetCardId(in_js_class_type);
	
	BEGIN
		INSERT INTO filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			filter_type_id_seq.NEXTVAL,
			in_description,
			in_helper_pkg,
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE filter_type
			   SET description = in_description,
			       helper_pkg = in_helper_pkg
			 WHERE card_id = v_card_id;
	END;
END;

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id = card_pkg.GetCardId(in_js_class_type);
	
	RETURN v_filter_type_id;
END;

FUNCTION GetFilterTypeId (
	in_card_group_id	card_group.card_group_id%TYPE,
	in_class_type		card.class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	-- TODO: What if there is more than one? i.e. 2 JS class types sharing 1 C# class type for one card group
	--       This would break, but there's no other way of distinguising filter_type_id from C#
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id IN (
		SELECT c.card_id
		  FROM card_group_card cgc
		  JOIN card c ON cgc.card_id = c.card_id
		 WHERE cgc.app_sid = security_pkg.GetApp
		   AND cgc.card_group_id = in_card_group_id
		   AND c.class_type = in_class_type);
	
	RETURN v_filter_type_id;
END;

/**********************************************************************************/
/********************** Building up a Filter **************************************/
/**********************************************************************************/

PROCEDURE CheckCompoundFilterAccess (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_access					IN	NUMBER
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_saved_filter_sid			security_pkg.T_SID_ID;
	v_parent_compound_filter_id	compound_filter.compound_filter_id%TYPE;
	v_batch_job_id				csr.batch_job.batch_job_id%TYPE;
BEGIN
	
	IF NVL(in_compound_filter_id, 0) != 0 THEN
	
		SELECT cf.act_id, sf.saved_filter_sid, feb.batch_job_id
		  INTO v_act_id, v_saved_filter_sid, v_batch_job_id
		  FROM compound_filter cf
		  LEFT JOIN saved_filter sf ON cf.compound_filter_id IN (sf.compound_filter_id, sf.group_by_compound_filter_id)
		  LEFT JOIN filter_export_batch feb ON cf.compound_filter_id = feb.compound_filter_id
		 WHERE cf.compound_filter_id = in_compound_filter_id;
		
		IF v_act_id IS NULL AND v_saved_filter_sid IS NULL AND v_batch_job_id IS NULL THEN
			BEGIN
				-- see if this filter is on another saved filter, if so check access on that
				SELECT f.compound_filter_id
				  INTO v_parent_compound_filter_id
				  FROM filter f 
				  JOIN filter_field ff ON f.filter_id = ff.filter_id
				  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
				 WHERE fv.compound_filter_id_value = in_compound_filter_id;				 
				
				CheckCompoundFilterAccess(v_parent_compound_filter_id, in_access);
			EXCEPTION
				WHEN no_data_found OR too_many_rows THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
			END;
		END IF;
		
		IF v_act_id IS NOT NULL AND v_act_id != security_pkg.GetAct THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
		END IF;
		
		IF v_saved_filter_sid IS NOT NULL AND NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_saved_filter_sid, in_access) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
		END IF;
	
	END IF;
	
END;

PROCEDURE CheckCompoundFilterForCycles (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE
)
AS
	v_has_cycle						NUMBER;
BEGIN
	-- Check to see if the compound filter contains a saved filter that references this compound filter
	SELECT MAX(connect_by_iscycle)
	  INTO v_has_cycle
	  FROM filter f
	  JOIN filter_field ff ON f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
	  JOIN saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
	  START WITH f.compound_filter_id = in_compound_filter_id
	  CONNECT BY NOCYCLE PRIOR sf.compound_filter_id = f.compound_filter_id;
	
	IF NVL(v_has_cycle, 0) = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Infinite loop detected in compound filter: '||in_compound_filter_id);
	END IF;	
END;

PROCEDURE CreateCompoundFilter (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	CreateCompoundFilter(security_pkg.GetAct, in_card_group_id, out_compound_filter_id);
END;

PROCEDURE CreateCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_is_session_state_set	NUMBER := 1;
BEGIN
	IF in_act_id IS NOT NULL AND in_act_id != security_pkg.GetAct THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_act_id must be NULL or the ACT of the logged on user');
	END IF;
	
	INSERT INTO compound_filter (compound_filter_id, card_group_id, act_id)
	VALUES (compound_filter_id_seq.NEXTVAL, in_card_group_id, in_act_id)
	RETURNING compound_filter_id INTO out_compound_filter_id;
	
	IF in_act_id IS NOT NULL THEN
		SELECT DECODE(COUNT(*), 0, 0, 1) 
		  INTO v_is_session_state_set
		  FROM security.sessionstate
		 WHERE session_id = in_act_id;

		IF v_is_session_state_set = 1 THEN
			security.session_pkg.RegisterCallbacks(in_act_id, 'begin chain.filter_pkg.OnSessionDeleted(:1); end;', 'begin chain.filter_pkg.OnSessionMigrated(:1, :2); end;');
		END IF;
	END IF;
END;

PROCEDURE CopyCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_card_group_id				card_group.card_group_id%TYPE;
	v_filter_id					filter.filter_id%TYPE;
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	
	SELECT card_group_id
	  INTO v_card_group_id
	  FROM compound_filter
	 WHERE app_sid = security_pkg.GetApp
	   AND compound_filter_id = in_compound_filter_id;
	
	CreateCompoundFilter(in_act_id, v_card_group_id, out_new_compound_filter_id);
	
	FOR r IN (
		SELECT f.filter_id, f.filter_type_id, operator_type, ft.helper_pkg
		  FROM filter f
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		INSERT INTO filter (filter_id, filter_type_id, compound_filter_id, operator_type)
		VALUES (filter_id_seq.NEXTVAL, r.filter_type_id, out_new_compound_filter_id, r.operator_type)
		RETURNING filter_id INTO v_filter_id;
		
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.CopyFilter(:from_filter_id, :to_filter_id);END;') USING r.filter_id, v_filter_id;
	END LOOP;
END;

FUNCTION IsFilterEmpty(
	in_filter_id				IN  filter.filter_id%TYPE
) RETURN NUMBER
AS
	v_filter_value_count		NUMBER;
BEGIN
	-- check for filter values (excluding embedded filters)
	SELECT COUNT(*)
	  INTO v_filter_value_count
	  FROM filter_value fv
	  JOIN filter_field ff ON fv.filter_field_id = ff.filter_field_id
	 WHERE fv.compound_filter_id_value IS NULL
	   AND ff.filter_id = in_filter_id;
	
	IF v_filter_value_count > 0 THEN
		RETURN 0;
	END IF;

	-- check embedded compound filters
	FOR r IN (	
		SELECT fv.compound_filter_id_value
		  FROM filter_value fv
		  JOIN filter_field ff ON fv.filter_field_id = ff.filter_field_id
		 WHERE filter_id = in_filter_id
	) LOOP		
		IF IsCompoundFilterEmpty(r.compound_filter_id_value) = 0 THEN
			RETURN 0;
		END IF;
	END LOOP;		

	RETURN 1;
END;

FUNCTION IsCompoundFilterEmpty(
	in_compound_filter_id		IN  compound_filter.compound_filter_id%TYPE
) RETURN NUMBER
AS
	v_is_filter_empty			NUMBER;
BEGIN
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM filter f
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		BEGIN
			EXECUTE IMMEDIATE ('BEGIN :result := ' || r.helper_pkg || '.IsFilterEmpty(:filter_id);END;') USING OUT v_is_filter_empty, IN r.filter_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				v_is_filter_empty := IsFilterEmpty(r.filter_id);
		END;
		
		IF v_is_filter_empty = 0 THEN
			RETURN 0;
		END IF;
	END LOOP;

	RETURN 1;
END;

-- Gets Public filters root.
FUNCTION GetSharedParentSid (
	in_card_group_id			IN	card_group.card_group_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	IF in_card_group_id IN (FILTER_TYPE_COMPANIES) THEN
		-- For company filters, get a filters node from the logged on user's company
		RETURN securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.TrySetCompany(SYS_CONTEXT('SECURITY','CHAIN_COMPANY')), chain_pkg.COMPANY_FILTERS);
	ELSE
		-- Get a global filters node
		RETURN securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Dataviews');
	END IF;
END;

-- Gets user's filters root.
FUNCTION GetPrivateFiltersRoot RETURN security_pkg.T_SID_ID
AS
	v_root_sid		security_pkg.T_SID_ID;
BEGIN
	 v_root_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetSid, 'Charts');
	 
	 RETURN v_root_sid;
END;

FUNCTION IsFilterEnabled (
	in_card_group_id			IN  card_group.card_group_id%TYPE
) RETURN NUMBER
AS
	v_card_count				NUMBER;
BEGIN
	SELECT COUNT(*) 
	  INTO v_card_count
	  FROM card_group_card cgc
	  JOIN filter_type ft ON cgc.card_id = ft.card_id
	 WHERE cgc.card_group_id = in_card_group_id;
	 
	IF v_card_count > 0 THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE GetExportManagerType (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE,
	out_card_group_id			OUT	card_group.card_group_id%TYPE
)
AS
BEGIN
	-- No permission check, only called by batch jobs.
	SELECT DISTINCT card_group_id
	  INTO out_card_group_id
	  FROM filter_export_batch
	 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE CleanupBatchExport (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE
)
AS
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
BEGIN
	-- No permission check, only called by batch jobs.
	FOR r IN (
		SELECT compound_filter_id, filter_type
		  FROM filter_export_batch
		 WHERE batch_job_id = in_batch_job_id
	) LOOP
		DELETE FROM filter_export_batch
		 WHERE batch_job_id = in_batch_job_id
		   AND filter_type = r.filter_type;
		   
		IF r.compound_filter_id IS NOT NULL THEN
			DeleteCompoundFilter_UNSEC(r.compound_filter_id);
		END IF;
	END LOOP;
END;

PROCEDURE LinkToBatchJob (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE,
	in_filter_type				IN	NUMBER,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE
)
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE := NULL;
BEGIN
	-- No permission check, only called when creating batch jobs.
	IF in_compound_filter_id > 0 THEN
		v_compound_filter_id := in_compound_filter_id;
	END IF;
	
	INSERT INTO filter_export_batch (batch_job_id, filter_type, compound_filter_id, card_group_id)
	VALUES (in_batch_job_id, in_filter_type, v_compound_filter_id, in_card_group_id);
END;

PROCEDURE CloneCompoundFilterForBatchJob (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	-- No permission check, only called when creating batch jobs.

	CopyCompoundFilter(security_pkg.GetAct, in_compound_filter_id, out_compound_filter_id);
	
	-- Remove act on cloned filters, cloned filters can't have acts otherwise they'd be cleaned up when the act expires
	UPDATE compound_filter
	   SET act_id = NULL
	 WHERE compound_filter_id IN (out_compound_filter_id);
	
	-- Remove act on embedded filters on the newly cloned filter
	UPDATE compound_filter
	   SET act_id = NULL
	 WHERE compound_filter_id IN (
		SELECT fv.compound_filter_id_value
		  FROM filter_value fv
		  JOIN filter_field ff ON fv.filter_field_id = ff.filter_field_id
		  JOIN filter f ON ff.filter_id = f.filter_id
		 WHERE fv.compound_filter_id_value IS NOT NULL
		 START WITH f.compound_filter_id = out_compound_filter_id
         CONNECT BY PRIOR fv.compound_filter_id_value = f.compound_filter_id
	 );
	
	-- check that what we have done hasn't created any infinite cycles
	IF out_compound_filter_id > 0 THEN
		CheckCompoundFilterForCycles(out_compound_filter_id);
	END IF;

END;

PROCEDURE CloneBreadcrumbsForBatchJob (
	in_breadcrumb				IN	security_pkg.T_SID_IDS,
	out_gp_compound_filter		OUT SYS_REFCURSOR,
	out_breadcrumb				OUT SYS_REFCURSOR
)
AS
	v_breadcrumb				security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_breadcrumb);
	v_old_gp_comp_filter_id		compound_filter.compound_filter_id%TYPE;
	v_new_gp_comp_filter_id		compound_filter.compound_filter_id%TYPE;
	v_fvm_tbl					T_FILTER_VALUE_MAP_TABLE;
BEGIN
	-- No permission check, only called when creating batch jobs.
	
	SELECT DISTINCT compound_filter_id
	  INTO v_old_gp_comp_filter_id
	  FROM v$filter_value fv
	  JOIN TABLE(v_breadcrumb) b ON fv.filter_value_id = b.sid_id;
	
	CloneCompoundFilterForBatchJob(v_old_gp_comp_filter_id,v_new_gp_comp_filter_id);
	
	SELECT T_FILTER_VALUE_MAP_ROW(old_filter_value_id, new_filter_value_id)
	  BULK COLLECT INTO v_fvm_tbl
	  FROM (SELECT old_filter_value_id, new_filter_value_id FROM tt_filter_value_map);
	  
	OPEN out_gp_compound_filter FOR
		SELECT v_new_gp_comp_filter_id compound_filter_id FROM DUAL;

	OPEN out_breadcrumb FOR
		SELECT old_filter_value_id, new_filter_value_id
		  FROM TABLE(v_fvm_tbl) map
		  JOIN TABLE(v_breadcrumb) b ON map.old_filter_value_id = b.sid_id
		  JOIN filter_value fv ON map.old_filter_value_id = fv.filter_value_id
		  JOIN filter_field ff ON ff.filter_field_id = fv.filter_field_id
		 ORDER BY ff.group_by_index;
END;

PROCEDURE SaveCompoundFilter (
	in_saved_filter_sid			IN 	security_pkg.T_SID_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_search_text				IN	saved_filter.search_text%TYPE,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_grp_by_cmpnd_filter_id	IN	compound_filter.compound_filter_id%TYPE,
	in_aggregation_types		IN	security_pkg.T_SID_IDS,
	in_name						IN	saved_filter.name%TYPE,
	in_folder_sid				IN	security_pkg.T_SID_ID,
	in_region_column_id			IN	saved_filter.region_column_id%TYPE,
	in_date_column_id			IN	saved_filter.date_column_id%TYPE,
	in_group_key				IN	saved_filter.group_key%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_list_page_url			IN	saved_filter.list_page_url%TYPE,
	in_exclude_from_reports		IN	saved_filter.exclude_from_reports%TYPE,
	in_region_sids				IN	security_pkg.T_SID_IDS,
	in_dual_axis				IN	saved_filter.dual_axis%TYPE,
	in_ranking_mode				IN	saved_filter.ranking_mode%TYPE,
	in_colour_by				IN	saved_filter.colour_by%TYPE,
	in_colour_range_id			IN	saved_filter.colour_range_id%TYPE,
	in_order_by					IN  saved_filter.order_by%TYPE DEFAULT NULL,	
	in_order_direction			IN  saved_filter.order_direction%TYPE DEFAULT NULL,
	in_results_per_page			IN  saved_filter.results_per_page%TYPE DEFAULT NULL,
	in_map_colour_by			IN  saved_filter.map_colour_by%TYPE DEFAULT NULL,
	in_map_cluster_bias			IN  saved_filter.map_cluster_bias%TYPE DEFAULT NULL,
	in_column_names_to_keep		IN  security_pkg.T_VARCHAR2_ARRAY,
	in_hide_empty				IN	saved_filter.hide_empty%TYPE DEFAULT 0,
	out_saved_filter_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
	v_grp_by_cmpnd_filter_id	compound_filter.compound_filter_id%TYPE;
	v_old_compound_filter_id	compound_filter.compound_filter_id%TYPE;
	v_old_grb_by_cmpnd_fltr_id	compound_filter.compound_filter_id%TYPE;
	v_aggregation_types			security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_aggregation_types);
	v_region_sids				security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_region_sids);
	v_region_column_id			saved_filter.region_column_id%TYPE;
	v_date_column_id			saved_filter.date_column_id%TYPE;
	v_cms_region_column_sid		saved_filter.cms_region_column_sid%TYPE;
	v_cms_date_column_sid		saved_filter.cms_date_column_sid%TYPE;
	v_column_names_to_keep		security.T_VARCHAR2_TABLE := security_pkg.Varchar2ArrayToTable(in_column_names_to_keep);
	v_current_parent_sid		security_pkg.T_SID_ID;
BEGIN
	IF in_saved_filter_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on saved filter with sid: '||in_saved_filter_sid);
		END IF;
	END IF;
	
	out_saved_filter_sid := in_saved_filter_sid;
	
	IF out_saved_filter_sid IS NULL THEN
		-- Save over existing filter of the same name with same parent
		-- If two people try to save a filter of the same name at the same time
		-- at worst it will fail the constraint for one and roll back
		SELECT MIN(saved_filter_sid), MIN(compound_filter_id), MIN(group_by_compound_filter_id)
		  INTO out_saved_filter_sid, v_old_compound_filter_id, v_old_grb_by_cmpnd_fltr_id
		  FROM saved_filter
		 WHERE LOWER(name) = LOWER(LTRIM(RTRIM(in_name)))
		   AND card_group_id = in_card_group_id
		   AND saved_filter_sid IN (
			SELECT sid_id
			  FROM TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
				in_folder_sid, security_pkg.PERMISSION_WRITE))
			);
	END IF;
	
	-- Copy the filters to be persisted.
	-- Temporarily set act to current act for new compound filter so copying security checks pass
	IF in_compound_filter_id > 0 THEN
		CopyCompoundFilter(security_pkg.GetAct, in_compound_filter_id, v_compound_filter_id);
	END IF;
	
	IF in_grp_by_cmpnd_filter_id > 0 THEN
		CopyCompoundFilter(security_pkg.GetAct, in_grp_by_cmpnd_filter_id, v_grp_by_cmpnd_filter_id);
	END IF;
	
	IF in_card_group_id = FILTER_TYPE_CMS THEN
		v_cms_region_column_sid := in_region_column_id;
		v_cms_date_column_sid := in_date_column_id;
	ELSE
		v_region_column_id := in_region_column_id;
		v_date_column_id := in_date_column_id;
	END IF;
	
	IF out_saved_filter_sid IS NOT NULL THEN
		SELECT parent_sid
		  INTO v_current_parent_sid
		  FROM saved_filter
		 WHERE saved_filter_sid = out_saved_filter_sid;

		UPDATE saved_filter
		   SET compound_filter_id = v_compound_filter_id,
			   group_by_compound_filter_id = v_grp_by_cmpnd_filter_id,
		       parent_sid = in_folder_sid,
		       search_text = in_search_text,
		       region_column_id = v_region_column_id,
		       date_column_id = v_date_column_id,
		       cms_region_column_sid = v_cms_region_column_sid,
		       cms_date_column_sid = v_cms_date_column_sid,
		       group_key = in_group_key,
			   cms_id_column_sid = in_cms_id_column_sid,
			   list_page_url = in_list_page_url,
			   exclude_from_reports = in_exclude_from_reports,
			   dual_axis = in_dual_axis,
			   ranking_mode = in_ranking_mode,
			   colour_by = in_colour_by,
			   colour_range_id = in_colour_range_id,
			   order_by = in_order_by,
			   order_direction = in_order_direction,
			   results_per_page = in_results_per_page,
			   map_colour_by = in_map_colour_by,
			   map_cluster_bias = in_map_cluster_bias,
			   hide_empty = in_hide_empty
		 WHERE saved_filter_sid = out_saved_filter_sid;
		
		-- Delete old filter - this should trigger cascade deletes. Could use helper_pkg instead.
		DeleteCompoundFilter_UNSEC(v_old_compound_filter_id);
		DeleteCompoundFilter_UNSEC(v_old_grb_by_cmpnd_fltr_id);
		
		-- Delete read only filters in users sessions to force them to reload
		FOR r IN (
			SELECT compound_filter_id
			  FROM compound_filter
			 WHERE read_only_saved_filter_sid = out_saved_filter_sid
		) LOOP
			DeleteCompoundFilter_UNSEC(r.compound_filter_id);
		END LOOP;
		
		DELETE FROM saved_filter_aggregation_type
		 WHERE saved_filter_sid = out_saved_filter_sid
		   AND (aggregation_type, pos) NOT IN (
			SELECT sid_id, pos
			  FROM TABLE(v_aggregation_types)
		   );
		   
		DELETE FROM saved_filter_region
		 WHERE saved_filter_sid = out_saved_filter_sid
		   AND region_sid NOT IN (
			SELECT sid_id
			  FROM TABLE(v_region_sids)
		   );
		   
		DELETE FROM saved_filter_column
		 WHERE saved_filter_sid = out_saved_filter_sid
		   AND column_name NOT IN (
			SELECT value
			  FROM TABLE(v_column_names_to_keep)
		   );
		
		security.securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), out_saved_filter_sid, LTRIM(RTRIM(in_name)));

		IF in_folder_sid != v_current_parent_sid THEN
			security.securableobject_pkg.MoveSO(
				in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_sid_id			=> out_saved_filter_sid,
				in_new_parent_sid	=> in_folder_sid
			);
		END IF;
	ELSE
		SecurableObject_pkg.CreateSO(security_pkg.GetAct, in_folder_sid, 
		   class_pkg.GetClassID('ChainCompoundFilter'), TRIM(REGEXP_REPLACE(TRANSLATE(in_name, '.,-()\/''', '        '), '  +', ' ')), out_saved_filter_sid);
	
		INSERT INTO saved_filter (saved_filter_sid, search_text, compound_filter_id,
			group_by_compound_filter_id, card_group_id, parent_sid, name, region_column_id, date_column_id,
			cms_region_column_sid, cms_date_column_sid, group_key, cms_id_column_sid, list_page_url,
			exclude_from_reports, dual_axis, ranking_mode, colour_by, colour_range_id, order_by, order_direction, 
			results_per_page, map_colour_by, map_cluster_bias, hide_empty)
		VALUES (out_saved_filter_sid, in_search_text, v_compound_filter_id,
			v_grp_by_cmpnd_filter_id, in_card_group_id, in_folder_sid, LTRIM(RTRIM(in_name)),
			v_region_column_id, v_date_column_id, v_cms_region_column_sid, v_cms_date_column_sid, 
			in_group_key, in_cms_id_column_sid, in_list_page_url, in_exclude_from_reports, in_dual_axis,
			in_ranking_mode, in_colour_by, in_colour_range_id, in_order_by, in_order_direction,
			in_results_per_page, in_map_colour_by, in_map_cluster_bias, in_hide_empty);
	END IF;
	
	INSERT INTO saved_filter_aggregation_type (saved_filter_sid, aggregation_type, customer_aggregate_type_id, pos)
	SELECT out_saved_filter_sid, CASE WHEN cat.customer_aggregate_type_id IS NULL THEN at.sid_id END,
		   cat.customer_aggregate_type_id, at.pos
	  FROM TABLE(v_aggregation_types) at
	  LEFT JOIN customer_aggregate_type cat ON at.sid_id = cat.customer_aggregate_type_id
	 MINUS
	SELECT out_saved_filter_sid, aggregation_type, customer_aggregate_type_id, pos
	  FROM saved_filter_aggregation_type
	 WHERE saved_filter_sid = out_saved_filter_sid;
	 
	INSERT INTO saved_filter_region (saved_filter_sid, region_sid)
	SELECT out_saved_filter_sid, r.sid_id
	  FROM TABLE(v_region_sids) r
	 MINUS
	SELECT saved_filter_sid, region_sid
	  FROM saved_filter_region
	 WHERE saved_filter_sid = out_saved_filter_sid;
	
	-- Remove act on saved filters, saved filters can't have acts otherwise they'd be cleaned up when the act expires
	UPDATE compound_filter
	   SET act_id = NULL
	 WHERE compound_filter_id IN (v_compound_filter_id, v_grp_by_cmpnd_filter_id);
	
	-- Remove act on embedded filters on the newly saved filter
	UPDATE compound_filter
	   SET act_id = NULL
	 WHERE compound_filter_id IN (
		SELECT fv.compound_filter_id_value
		  FROM filter_value fv
		  JOIN filter_field ff ON fv.filter_field_id = ff.filter_field_id
		  JOIN filter f ON ff.filter_id = f.filter_id
		 WHERE fv.compound_filter_id_value IS NOT NULL
		 START WITH f.compound_filter_id = v_compound_filter_id
         CONNECT BY PRIOR fv.compound_filter_id_value = f.compound_filter_id
	 );
	
	-- check that what we have done hasn't created any infinite cycles
	IF v_compound_filter_id > 0 THEN
		CheckCompoundFilterForCycles(v_compound_filter_id);
	END IF;
	
	IF v_grp_by_cmpnd_filter_id > 0 THEN
		CheckCompoundFilterForCycles(v_grp_by_cmpnd_filter_id);
	END IF;
END;

PROCEDURE SaveCompoundFilterColumn (
	in_saved_filter_sid			IN 	security_pkg.T_SID_ID,
	in_column_name				IN  saved_filter_column.column_name%TYPE,
	in_pos						IN  saved_filter_column.pos%TYPE,
	in_width					IN  saved_filter_column.width%TYPE,
	in_label					IN  saved_filter_column.label%TYPE
)
AS
	v_label						saved_filter_column.label%TYPE := SUBSTR(in_label, 0, 1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on saved filter with sid: '||in_saved_filter_sid);
	END IF;
	
	BEGIN
		INSERT INTO saved_filter_column (saved_filter_sid, column_name, pos, width, label)
		     VALUES (in_saved_filter_sid, in_column_name, in_pos, in_width, v_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE saved_filter_column
 			   SET pos = in_pos,
			       width = in_width,
				   label = v_label
			 WHERE saved_filter_sid = in_saved_filter_sid
			   AND column_name = in_column_name;
	END;
END;

PROCEDURE GetSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_query					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_shared_sid				security_pkg.T_SID_ID;
	v_personal_sid				security_pkg.T_SID_ID;
BEGIN
	v_shared_sid := GetSharedParentSid(in_card_group_id);
	
	BEGIN
		v_personal_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetSid, 'Filters');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_personal_sid := security_pkg.GetSid;
	END;
	
	-- trim results based on security, get global and personal filters
	OPEN out_cur FOR
		SELECT sf.saved_filter_sid, sf.name, sf.region_column_id, sf.date_column_id, sf.exclude_from_reports
		  FROM saved_filter sf
		  JOIN compound_filter cf ON sf.compound_filter_id = cf.compound_filter_id
		  JOIN (
				SELECT sid_id
				  FROM TABLE(SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_shared_sid, security_pkg.PERMISSION_READ))
				UNION
				SELECT sid_id
				  FROM TABLE(SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_personal_sid, security_pkg.PERMISSION_READ))
			   ) so ON sf.saved_filter_sid = so.sid_id
		 WHERE LOWER(sf.name) LIKE NVL(LOWER(in_query), '')||'%'
		   AND cf.card_group_id = in_card_group_id
		 ORDER BY LOWER(sf.name);
END;

FUNCTION HasSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE
) RETURN NUMBER
AS
BEGIN
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT *
			  FROM saved_filter
			 WHERE app_sid = security_pkg.GetApp
			   AND card_group_id = NVL(in_card_group_id, card_group_id)
		 )
	) LOOP
		RETURN 1;
	END LOOP;
	
	RETURN 0;
END;


PROCEDURE GetAggregateDetails (
	in_card_group_id				IN  NUMBER,
	in_aggregation_types			IN  security.T_ORDERED_SID_TABLE,
	in_parent_id					IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR,
	out_aggregate_threshold_cur		OUT SYS_REFCURSOR
)
AS
	PROC_NOT_FOUND					EXCEPTION;
	PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);
	v_helper_pkg_called				BOOLEAN := FALSE;
	v_agg_types						T_FILTER_AGG_TYPE_TABLE;
	v_agg_threshold_types			T_FILTER_AGG_TYPE_THRES_TABLE;
	v_all_agg_types					T_FILTER_AGG_TYPE_TABLE := T_FILTER_AGG_TYPE_TABLE();
	v_all_agg_threshold_types		T_FILTER_AGG_TYPE_THRES_TABLE := T_FILTER_AGG_TYPE_THRES_TABLE();
BEGIN	
	-- no security on the base data
	
	FOR r IN (
		SELECT card_group_id, helper_pkg
		  FROM chain.card_group
		 WHERE card_group_id = in_card_group_id
		    OR (in_card_group_id IS NULL
		   AND card_group_id IN (
				SELECT cgc.card_group_id
				  FROM filter_type ft
				  JOIN card_group_card cgc ON ft.card_id = cgc.card_id
			))
	) LOOP
		v_helper_pkg_called := FALSE;
		v_agg_types := T_FILTER_AGG_TYPE_TABLE();
		v_agg_threshold_types := T_FILTER_AGG_TYPE_THRES_TABLE();
		
		IF r.helper_pkg IS NOT NULL THEN
			BEGIN
				EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.GetAggregateDetails(:aggregation_types, :parent_id, :out_agg_types, :out_aggregate_thresholds );END;') 
				  USING in_aggregation_types, in_parent_id, OUT v_agg_types, OUT v_agg_threshold_types;
				v_helper_pkg_called := TRUE;
			EXCEPTION
				WHEN PROC_NOT_FOUND THEN
					NULL;
			END;
		END IF;
		
		IF NOT v_helper_pkg_called THEN 	
			SELECT T_FILTER_AGG_TYPE_ROW(card_group_id, aggregate_type_id, description, null, null, 0, null, null, null)
			  BULK COLLECT INTO v_agg_types
			  FROM TABLE(in_aggregation_types) sat
			  JOIN aggregate_type at ON sat.sid_id = at.aggregate_type_id
			 WHERE card_group_id = r.card_group_id
			 ORDER BY sat.pos;
		
			v_agg_threshold_types := T_FILTER_AGG_TYPE_THRES_TABLE();
		END IF;
		
		v_all_agg_types := v_all_agg_types MULTISET UNION v_agg_types;
		v_all_agg_threshold_types := v_all_agg_threshold_types MULTISET UNION v_agg_threshold_types;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT aat.card_group_id, aat.aggregate_type_id, NVL(atc.label, aat.description) description,
			   aat.format_mask, aat.filter_page_ind_interval_id, aat.accumulative,
			   aat.aggregate_group, aat.unit_of_measure, aat.normalize_by_aggregate_type_id
		  FROM TABLE(v_all_agg_types) aat
		  LEFT JOIN aggregate_type_config atc
		    ON aat.card_group_id = atc.card_group_id
		   AND aat.aggregate_type_id = atc.aggregate_type_id
		   AND atc.session_prefix IS NULL -- Don't use labels specific to plugins
		   AND atc.path IS NULL;
	
	OPEN out_aggregate_threshold_cur FOR
		SELECT aggregate_type_id, max_value, label, icon_url, icon_data,
			   text_colour, background_colour, bar_colour
		  FROM TABLE(v_all_agg_threshold_types) aatt;
END;

PROCEDURE GetSavedFilterAggregateTypes (
	in_saved_filter_sid			IN	security_pkg.T_SID_ID,
	out_agg_types				OUT	SYS_REFCURSOR
)
AS
	v_card_group_id				saved_filter.card_group_id%TYPE;
	v_cms_id_column_sid			saved_filter.cms_id_column_sid%TYPE;
	v_aggregation_types			security.T_ORDERED_SID_TABLE;
	v_dummy						SYS_REFCURSOR;
BEGIN
	SELECT card_group_id, cms_id_column_sid
	  INTO v_card_group_id, v_cms_id_column_sid
	  FROM saved_filter
	 WHERE saved_filter_sid = in_saved_filter_sid;

	SELECT security.T_ORDERED_SID_ROW(NVL(sfat.customer_aggregate_type_id, sfat.aggregation_type), sfat.pos)
	  BULK COLLECT INTO v_aggregation_types
	  FROM saved_filter sf
	  JOIN saved_filter_aggregation_type sfat ON sf.saved_filter_sid = sfat.saved_filter_sid
	 WHERE sf.saved_filter_sid = in_saved_filter_sid
	 ORDER BY sfat.pos;
	 
	GetAggregateDetails(v_card_group_id, v_aggregation_types, v_cms_id_column_sid, out_agg_types, v_dummy);		 
END;

PROCEDURE INTERNAL_GetSavedFilterDetails(
	in_saved_filter_sid				IN	security_pkg.T_SID_ID, 
	in_compound_filter_id 			IN  compound_filter.compound_filter_id%TYPE, 
	in_group_by_compound_filter_id	IN  compound_filter.compound_filter_id%TYPE, 
	out_fil_cur						OUT SYS_REFCURSOR,
	out_agg_types					OUT SYS_REFCURSOR,
	out_region_sids					OUT SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
)
AS
	v_max_group_by_index		filter_field.group_by_index%TYPE;
BEGIN
	SELECT MAX(group_by_index)
	  INTO v_max_group_by_index
	  FROM v$filter_field
	 WHERE compound_filter_id = in_group_by_compound_filter_id;
	
	OPEN out_fil_cur FOR
		SELECT sf.saved_filter_sid, in_compound_filter_id compound_filter_id, in_group_by_compound_filter_id group_by_compound_filter_id, 
			   sf.search_text, sf.card_group_id, v_max_group_by_index max_group_by_index,
			   NVL(sf.list_page_url, cg.list_page_url) list_page_url, sf.group_key,
			   NVL(sf.cms_region_column_sid, region_column_id) region_column_id,
			   NVL(sf.cms_date_column_sid, date_column_id) date_column_id,
			   sf.exclude_from_reports, fpic.cnt filter_page_ind_count, sf.cms_id_column_sid, sf.dual_axis,
			   sf.ranking_mode, sf.colour_by, sf.colour_range_id, sf.order_by, sf.order_direction, sf.results_per_page,
			   sf.map_colour_by, sf.map_cluster_bias, sf.hide_empty, sf.name
		  FROM saved_filter sf
		  JOIN card_group cg ON sf.card_group_id = cg.card_group_id
		  LEFT JOIN (
			SELECT COUNT(*) cnt, fpi.card_group_id
			  FROM filter_page_ind fpi
			 GROUP BY fpi.card_group_id
			) fpic ON sf.card_group_id = fpic.card_group_id
		 WHERE sf.saved_filter_sid = in_saved_filter_sid;

	GetSavedFilterAggregateTypes(in_saved_filter_sid, out_agg_types);
	
	OPEN out_region_sids FOR
		SELECT saved_filter_sid, region_sid
		  FROM saved_filter_region
		 WHERE saved_filter_sid = in_saved_filter_sid;
		 
	OPEN out_columns FOR
		SELECT saved_filter_sid, column_name, pos, width, label
		  FROM saved_filter_column
		 WHERE saved_filter_sid = in_saved_filter_sid;
END;

PROCEDURE INTERNAL_GetReadOnlyCompFltrs (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	out_compound_filter_id			OUT compound_filter.compound_filter_id%TYPE,
	out_group_by_comp_filter_id		OUT compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT MAX(compound_filter_id)
		  INTO out_compound_filter_id
		  FROM compound_filter
		 WHERE read_only_saved_filter_sid = in_saved_filter_sid
		   AND act_id = security_pkg.GetAct
		   AND is_read_only_group_by = 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	BEGIN
		SELECT MAX(compound_filter_id)
		  INTO out_group_by_comp_filter_id
		  FROM compound_filter
		 WHERE read_only_saved_filter_sid = in_saved_filter_sid
		   AND act_id = security_pkg.GetAct
		   AND is_read_only_group_by = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE INTERNAL_LoadSavedFilter (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_load_as_read_only			IN	NUMBER,
	out_fil_cur						OUT	SYS_REFCURSOR,
	out_agg_types					OUT	SYS_REFCURSOR,
	out_breadcrumb					OUT	SYS_REFCURSOR,
	out_region_sids					OUT	SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
)
AS
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
	v_grp_by_cmpnd_filter_id		compound_filter.compound_filter_id%TYPE;
	v_new_compound_filter_id		compound_filter.compound_filter_id%TYPE;
	v_new_grp_by_cmpnd_filter_id	compound_filter.compound_filter_id%TYPE;
	v_fvm_tbl						T_FILTER_VALUE_MAP_TABLE;
	v_breadcrumb					security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_breadcrumb);
BEGIN
	-- CopyCompoundFilter does security checks	
	
	-- First check to see if the saved filter is already loaded in the users session as a read-only
	-- filter. If it is, copy that one (as any breadcrumb ids will be based on it), otherwise
	-- copy from the saved filter directly
	INTERNAL_GetReadOnlyCompFltrs(in_saved_filter_sid, v_compound_filter_id, v_grp_by_cmpnd_filter_id);
	
	IF v_compound_filter_id IS NULL AND v_grp_by_cmpnd_filter_id IS NULL THEN
		SELECT compound_filter_id, group_by_compound_filter_id
		  INTO v_compound_filter_id, v_grp_by_cmpnd_filter_id
		  FROM saved_filter 
		 WHERE saved_filter_sid = in_saved_filter_sid;
	END IF;

	IF v_compound_filter_id IS NOT NULL THEN
		CopyCompoundFilter(security_pkg.GetAct, v_compound_filter_id, v_new_compound_filter_id);
	END IF;

	IF v_grp_by_cmpnd_filter_id IS NOT NULL THEN
		CopyCompoundFilter(security_pkg.GetAct, v_grp_by_cmpnd_filter_id, v_new_grp_by_cmpnd_filter_id);
	END IF;
	
	IF in_load_as_read_only = 1 THEN
		UPDATE compound_filter
		   SET read_only_saved_filter_sid = in_saved_filter_sid,
		       is_read_only_group_by = 0
		 WHERE compound_filter_id = v_new_compound_filter_id;

		UPDATE compound_filter
		   SET read_only_saved_filter_sid = in_saved_filter_sid,
		       is_read_only_group_by = 1
		 WHERE compound_filter_id = v_new_grp_by_cmpnd_filter_id;
	END IF;
	
	INTERNAL_GetSavedFilterDetails(in_saved_filter_sid, v_new_compound_filter_id, v_new_grp_by_cmpnd_filter_id, out_fil_cur, out_agg_types, out_region_sids, out_columns);

	-- we get ORA-08103 if v_breadcrumb is empty and we join it to a temp table
	IF v_breadcrumb IS NULL OR v_breadcrumb.COUNT = 0 THEN
		OPEN out_breadcrumb FOR
			SELECT NULL group_by_index, NULL filter_field_id, NULL name,
				   NULL filter_value_id, NULL description
			  FROM dual
			 WHERE 1 = 2;
	ELSE
		SELECT T_FILTER_VALUE_MAP_ROW(old_filter_value_id, new_filter_value_id)
		  BULK COLLECT INTO v_fvm_tbl
		  FROM (SELECT old_filter_value_id, new_filter_value_id FROM tt_filter_value_map);
	  
		OPEN out_breadcrumb FOR
			SELECT ff.group_by_index, ff.filter_field_id, ff.name,
				   CASE WHEN b.sid_id < 0 THEN -ff.filter_field_id ELSE fv.filter_value_id END filter_value_id,
				   CASE WHEN b.pos < 0 THEN 'Other' ELSE fv.description END description,
				   fv.start_dtm_value, fv.end_dtm_value, fv.period_set_id, fv.period_interval_id, fv.start_period_id
			  FROM v$filter_field ff
			  LEFT JOIN TABLE(v_breadcrumb) b
				ON ff.group_by_index = b.pos
			  LEFT JOIN TABLE(v_fvm_tbl) map ON map.old_filter_value_id = b.sid_id
			  LEFT JOIN v$filter_value fv
				ON ff.app_sid = fv.app_sid
			   AND ff.filter_field_id = fv.filter_field_id
			   AND map.new_filter_value_id = fv.filter_value_id
			 WHERE ff.compound_filter_id = v_new_grp_by_cmpnd_filter_id
			 ORDER BY ff.group_by_index;
	END IF;
END;

PROCEDURE LoadSavedFilter (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	out_fil_cur						OUT	SYS_REFCURSOR,
	out_agg_types					OUT	SYS_REFCURSOR,
	out_breadcrumb					OUT	SYS_REFCURSOR,
	out_region_sids					OUT	SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_LoadSavedFilter(in_saved_filter_sid, in_breadcrumb, 0, out_fil_cur, out_agg_types, out_breadcrumb, out_region_sids, out_columns);
END;

PROCEDURE LoadReadOnlySavedFilter (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	out_fil_cur						OUT	SYS_REFCURSOR,
	out_agg_types					OUT	SYS_REFCURSOR,
	out_breadcrumb					OUT	SYS_REFCURSOR,
	out_region_sids					OUT	SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
)
AS
	v_breadcrumb					security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_breadcrumb);
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
	v_group_by_compound_filter_id	compound_filter.compound_filter_id%TYPE;
	v_session_comp_filter_id		compound_filter.compound_filter_id%TYPE;
	v_session_group_comp_filter_id	compound_filter.compound_filter_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on saved filter with sid: '||in_saved_filter_sid);
	END IF;
	
	SELECT compound_filter_id, group_by_compound_filter_id
	  INTO v_compound_filter_id, v_group_by_compound_filter_id
	  FROM saved_filter
	 WHERE saved_filter_sid = in_saved_filter_sid;
	 
	INTERNAL_GetReadOnlyCompFltrs(in_saved_filter_sid, v_session_comp_filter_id, v_session_group_comp_filter_id);
	
	IF (v_session_comp_filter_id IS NULL AND v_compound_filter_id IS NOT NULL) OR
	   (v_session_group_comp_filter_id IS NULL AND v_group_by_compound_filter_id IS NOT NULL) THEN
		-- copy a new one into session
		INTERNAL_LoadSavedFilter(in_saved_filter_sid, in_breadcrumb, 1, out_fil_cur, out_agg_types, out_breadcrumb, out_region_sids, out_columns);
	ELSE
		-- use session filters
		INTERNAL_GetSavedFilterDetails(in_saved_filter_sid, v_session_comp_filter_id, v_session_group_comp_filter_id, out_fil_cur, out_agg_types, out_region_sids, out_columns);
	
		OPEN out_breadcrumb FOR
			SELECT ff.group_by_index, ff.filter_field_id, ff.name, b.sid_id filter_value_id,
				   CASE WHEN b.sid_id < 0 THEN 'Other' ELSE fv.description END description,
				   fv.start_dtm_value, fv.end_dtm_value, fv.period_set_id, fv.period_interval_id, fv.start_period_id
			  FROM v$filter_field ff
			  LEFT JOIN TABLE(v_breadcrumb) b
				ON ff.group_by_index = b.pos
			  LEFT JOIN v$filter_value fv
				ON ff.app_sid = fv.app_sid
			   AND ff.filter_field_id = fv.filter_field_id
			   AND b.sid_id = fv.filter_value_id
			 WHERE ff.compound_filter_id = v_session_group_comp_filter_id
			 ORDER BY ff.group_by_index;
	END IF;
END;

-- Replaced by above for generic reporting, but still used by issues chart portlet
FUNCTION LoadReadOnlySavedFilter (
	in_saved_filter_sid			IN	security_pkg.T_SID_ID
) RETURN compound_filter.compound_filter_id%TYPE
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
BEGIN
	-- CopyCompoundFilter does security checks
	SELECT compound_filter_id
	  INTO v_compound_filter_id
	  FROM saved_filter
	 WHERE saved_filter_sid = in_saved_filter_sid;
	
	RETURN v_compound_filter_id;
END;

PROCEDURE GetSavedFilterName(
	in_saved_filter_sid			IN	security_pkg.T_SID_ID,
	out_filter_name				OUT saved_filter.name%TYPE	
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on saved filter with sid: '||in_saved_filter_sid);
	END IF;

	SELECT name
	  INTO out_filter_name
	  FROM saved_filter
	 WHERE saved_filter_sid = in_saved_filter_sid;
END;

FUNCTION GetNextFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER
AS
	v_filter_id					filter.filter_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO filter (filter_id, filter_type_id, compound_filter_id)
		VALUES (filter_id_seq.NEXTVAL, in_filter_type_id, in_compound_filter_id)
		RETURNING filter_id INTO v_filter_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT filter_id
			  INTO v_filter_id
			  FROM filter
			 WHERE filter_type_id = in_filter_type_id
			   AND compound_filter_id = in_compound_filter_id;
	END;
	
	RETURN v_filter_id;
END;

FUNCTION GetCompoundIdFromFilterId (
	in_filter_id			IN	filter.filter_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
BEGIN
	BEGIN
		SELECT compound_filter_id
		  INTO v_compound_filter_id
		  FROM filter
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id;
	EXCEPTION
		WHEN no_Data_found THEN
			RAISE_APPLICATION_ERROR(-20001, 'missing filter_id: '||in_filter_id);
	END;
	
	RETURN v_compound_filter_id;
END;

FUNCTION GetCompoundIdFromFieldId (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE
AS
	v_filter_id				filter.filter_id%TYPE;
BEGIN
	BEGIN
		SELECT filter_id
		  INTO v_filter_id
		  FROM filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_field_id = in_filter_field_id;
	EXCEPTION
		WHEN no_data_found THEN
			RAISE_APPLICATION_ERROR(-20001, 'Failed to find filter field id: '||in_filter_field_id);
	END;
	
	RETURN GetCompoundIdFromFilterId(v_filter_id);
END;

PROCEDURE DeleteFilterField_UNSEC (
	in_filter_field_id			IN	filter_field.filter_field_id%TYPE,
	in_app_sid					IN	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN
	-- Delete embedded filters
	FOR r IN (
		SELECT DISTINCT fv.compound_filter_id_value
		  FROM filter_value fv
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND fv.compound_filter_id_value IS NOT NULL
		   AND fv.app_sid = in_app_sid
	) LOOP
		-- clear all references and then delete the compound filter
		UPDATE filter_value
		   SET compound_filter_id_value = NULL
		 WHERE compound_filter_id_value = r.compound_filter_id_value
		   AND app_sid = in_app_sid;
		
		DeleteCompoundFilter_UNSEC(r.compound_filter_id_value, in_app_sid);
	END LOOP;
	
	--we use delete cascade to avoid RI errors caused by race conditions between successive filter web requests 
	DELETE FROM filter_field
	 WHERE filter_field_id = in_filter_field_id
	   AND app_sid = in_app_sid;
END;
	 
PROCEDURE DeleteFilter_UNSEC (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_app_sid					IN	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN
	FOR r IN (
		SELECT filter_field_id
		  FROM filter_field
		 WHERE filter_id = in_filter_id
		   AND app_sid = in_app_sid
	) LOOP
		DeleteFilterField_UNSEC(r.filter_field_id, in_app_sid);
	END LOOP;
	
	DELETE FROM filter
	 WHERE filter_id = in_filter_id
	   AND app_sid = in_app_sid;
END;

PROCEDURE DeleteFilter (
	in_filter_id				IN	filter.filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	DeleteFilter_UNSEC(in_filter_id);
END;

PROCEDURE DeleteCompoundFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_WRITE);
	
	DeleteCompoundFilter_UNSEC(in_compound_filter_id);
END;

PROCEDURE DeleteCompoundFilter_UNSEC (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_app_sid					IN	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN	
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM filter f
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
		   AND f.app_sid = in_app_sid
		 UNION
		SELECT f.filter_id, ft.helper_pkg
		  FROM filter_value fv
		  JOIN filter_field ff ON fv.app_sid = ff.app_sid AND fv.filter_field_id = ff.filter_field_id
		  JOIN filter f ON ff.app_sid = f.app_sid AND ff.filter_id = f.filter_id
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE fv.compound_filter_id_value = in_compound_filter_id
		   AND fv.app_sid = in_app_sid
		   AND ff.app_sid = in_app_sid
		   AND f.app_sid = in_app_sid
	) LOOP
		BEGIN
			EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.DeleteFilter(:filter_id);END;') USING r.filter_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- It's OK not to implement a delete if you only use filter_field / filter_value to store the user config
		END;
		
		DeleteFilter_UNSEC(r.filter_id, in_app_sid);
	END LOOP;
	
	DELETE FROM compound_filter
	 WHERE compound_filter_id = in_compound_filter_id
	   AND app_sid = in_app_sid;
END;

PROCEDURE AddCardFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_WRITE);
	
	out_filter_id := GetNextFilterId(in_compound_filter_id, GetFilterTypeId(in_card_group_id, in_class_type));
END;

PROCEDURE UpdateFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_operator_type			IN	filter.operator_type%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	UPDATE filter
	   SET operator_type = in_operator_type
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
END;

PROCEDURE GetFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
)
AS
	v_filter_type_id			filter_type.filter_type_id%TYPE := GetFilterTypeId(in_card_group_id, in_class_type);
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	
	BEGIN
		SELECT filter_id
		  INTO out_filter_id
		  FROM filter
		 WHERE app_sid = security_pkg.GetApp
		   AND compound_filter_id = in_compound_filter_id
		   AND filter_type_id = v_filter_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_filter_id := 0;
	END;
END;

PROCEDURE GetFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT filter_id, filter_type_id, compound_filter_id, operator_type
		  FROM filter
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id;
END;

/**********************************************************************************/
/**********************   Filter Field/Value management   *************************/
/**********************************************************************************/
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	in_group_by_index		IN	filter_field.group_by_index%TYPE,
	in_show_all				IN	filter_field.show_all%TYPE,
	in_top_n				IN	filter_field.top_n%TYPE,
	in_bottom_n				IN	filter_field.bottom_n%TYPE,
	in_column_sid			IN	filter_field.column_sid%TYPE,
	in_period_set_id		IN	filter_field.period_set_id%TYPE := NULL,
	in_period_interval_id	IN	filter_field.period_interval_id%TYPE := NULL,
	in_show_other			IN	filter_field.show_other%TYPE := NULL,
	in_row_or_col			IN	filter_field.row_or_col%TYPE := NULL,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	BEGIN
		INSERT INTO filter_field (filter_field_id, filter_id, name, comparator,
			group_by_index, show_all, top_n, bottom_n, show_other, column_sid, period_set_id,
			period_interval_id, row_or_col)
		VALUES (filter_field_id_seq.NEXTVAL, in_filter_id, in_name, in_comparator,
			in_group_by_index, in_show_all, in_top_n, in_bottom_n, in_show_other, in_column_sid,
			in_period_set_id, in_period_interval_id, in_row_or_col)
		RETURNING filter_field_id INTO out_filter_field_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE filter_field
			   SET comparator = in_comparator,
				   group_by_index = in_group_by_index,
				   show_all = in_show_all,
				   top_n = in_top_n,
				   bottom_n = in_bottom_n,
				   column_sid = in_column_sid,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id,
				   show_other = in_show_other,
				   row_or_col = in_row_or_col
			 WHERE filter_id = in_filter_id
			   AND name = in_name;
		
			SELECT filter_field_id
			  INTO out_filter_field_id
			  FROM filter_field
			 WHERE filter_id = in_filter_id
			   AND name = in_name;
	END;
END;

PROCEDURE UpdateFilterField (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_group_by_index		IN	filter_field.group_by_index%TYPE,
	in_show_all				IN	filter_field.show_all%TYPE,
	in_top_n				IN	filter_field.top_n%TYPE,
	in_bottom_n				IN	filter_field.bottom_n%TYPE,
	in_column_sid			IN	filter_field.column_sid%TYPE,
	in_period_set_id		IN	filter_field.period_set_id%TYPE,
	in_period_interval_id	IN	filter_field.period_interval_id%TYPE,
	in_show_other			IN	filter_field.show_other%TYPE,
	in_comparator			IN  filter_field.comparator%TYPE,
	in_row_or_col			IN  filter_field.row_or_col%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	UPDATE filter_field
	   SET show_all = in_show_all,
		   group_by_index = in_group_by_index,
		   top_n = in_top_n,
		   bottom_n = in_bottom_n,
		   show_other = in_show_other,
		   column_sid = in_column_sid,
		   period_set_id = in_period_set_id,
		   period_interval_id = in_period_interval_id,
		   comparator = in_comparator,
		   row_or_col = in_row_or_col
	 WHERE filter_field_id = in_filter_field_id;
END;

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_fields_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_fields_to_keep);
	v_fields_to_delete		security.T_SID_TABLE;
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	-- If there are any embedded filters - do we need to delete them too?
	-- Currently the UI doesn't remove a filter_field/value if an embedded filter is empty
	
	SELECT filter_field_id
	  BULK COLLECT INTO v_fields_to_delete
	  FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id
	   AND filter_field_id NOT IN (
			SELECT item FROM TABLE(v_fields_to_keep)
	   );

	--we use delete cascade to avoid RI errors caused by race conditions between successive filter web requests 
	DELETE FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id IN (
		SELECT column_value FROM TABLE(v_fields_to_delete)
	   );
END;

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_null_filter			IN  filter_value.null_filter%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value 
	   (filter_value_id, 
		filter_field_id, 
		filter_type, 
		null_filter,
		num_value, 
		description)
	VALUES 
	   (filter_value_id_seq.NEXTVAL, 
		in_filter_field_id, 
		FILTER_VALUE_TYPE_NUMBER, 
		in_null_filter,
		in_value, 
		SUBSTR(NVL(in_description, in_value),1,255))
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddRegionValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_region_sid			IN	filter_value.region_sid%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value 
	   (filter_value_id,
		filter_field_id,
		filter_type,
		region_sid,
		description)
	VALUES
	   (filter_value_id_seq.NEXTVAL,
		in_filter_field_id, 
		FILTER_VALUE_TYPE_REGION,
		in_region_sid, 
		SUBSTR(in_description,1,255))
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddUserValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_user_sid				IN	filter_value.user_sid%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value
	   (filter_value_id,
		filter_field_id, 
		filter_type, 
		user_sid, 
		description)
	VALUES 
	   (filter_value_id_seq.NEXTVAL,
		in_filter_field_id,
		FILTER_VALUE_TYPE_USER,
		in_user_sid,
		SUBSTR(in_description,1,255))
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddCompoundFilterValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_compound_filter_id	IN	filter_value.compound_filter_id_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value
	   (filter_value_id, 
		filter_field_id, 
		filter_type,
		compound_filter_id_value, 
		description)
	VALUES
	   (filter_value_id_seq.NEXTVAL,
		in_filter_field_id,
		FILTER_VALUE_TYPE_COMPOUND,
		in_compound_filter_id,
		in_description)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddSavedFilterValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_saved_filter_sid		IN	filter_value.saved_filter_sid_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value 
	   (filter_value_id,
		filter_field_id,
		filter_type,
		saved_filter_sid_value,
		description)
	VALUES
	   (filter_value_id_seq.NEXTVAL,
		in_filter_field_id,
		FILTER_VALUE_TYPE_SAVED,
		in_saved_filter_sid,
		in_description)
	RETURNING filter_value_id INTO out_filter_value_id;
END;

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_null_filter			IN  filter_value.null_filter%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value
	   (filter_value_id, 
		filter_field_id, 
		filter_type,
		null_filter,
		str_value, 
		description)
	VALUES
	   (filter_value_id_seq.NEXTVAL, 
		in_filter_field_id, 
		FILTER_VALUE_TYPE_STRING,
		in_null_filter,
		in_value, 
		NVL(SUBSTR(in_description,1,255), in_value))
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddDateRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_start_dtm			IN	filter_value.start_dtm_value%TYPE,
	in_end_dtm				IN	filter_value.end_dtm_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_stringValue			IN	filter_value.str_value%TYPE DEFAULT NULL,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value 
	   (filter_value_id, 
		filter_field_id, 
		filter_type,
		num_value,
		start_dtm_value,
		end_dtm_value,
		description,
		str_value)
	VALUES 
	   (filter_value_id_seq.NEXTVAL, 
		in_filter_field_id, 
		FILTER_VALUE_TYPE_DATE_RANGE,
		in_value,
		in_start_dtm,
		in_end_dtm + 1, -- Note: upper bound is exclusive
		in_description,
		in_stringValue)
	RETURNING filter_value_id INTO out_filter_value_id;
END;

PROCEDURE AddNumberRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_min_value			IN	filter_value.MIN_NUM_VAL%TYPE,
	in_max_value			IN	filter_value.MAX_NUM_VAL%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value
	   (filter_value_id,
		filter_field_id,
		filter_type,
		num_value,
		min_num_val,
		max_num_val, 
		description)
	VALUES
	   (filter_value_id_seq.NEXTVAL,
		in_filter_field_id,
		FILTER_VALUE_TYPE_NUMBER_RANGE,
		in_value,
		in_min_value,
		in_max_value,
		in_description)
	RETURNING filter_value_id INTO out_filter_value_id;
END;

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_values_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_values_to_keep);
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	DELETE FROM filter_value
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id = in_filter_field_id
	   AND filter_value_id NOT IN (
		SELECT item FROM TABLE(v_values_to_keep));
END;

PROCEDURE CopyFieldsAndValues (
	in_from_filter_id			IN	filter.filter_id%TYPE,
	in_to_filter_id				IN	filter.filter_id%TYPE
)
AS
	v_filter_field_id 			filter_field.filter_field_id%TYPE;
	v_compound_filter_id_value	filter_value.compound_filter_id_value%TYPE;
	v_new_filter_value_id		filter_value.filter_value_id%TYPE;
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_from_filter_id), security_pkg.PERMISSION_READ);
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_to_filter_id), security_pkg.PERMISSION_WRITE);
	
	FOR r IN (
		SELECT filter_field_id, name, comparator, NVL(show_all, 0) show_all, group_by_index,
			   top_n, bottom_n, show_other, column_sid, period_set_id, period_interval_id, row_or_col
		  FROM filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_from_filter_id
	) LOOP
		INSERT INTO filter_field (filter_field_id, filter_id, name, comparator, show_all, group_by_index, top_n, bottom_n, show_other, column_sid, period_set_id, period_interval_id, row_or_col)
		VALUES (filter_field_id_seq.NEXTVAL, in_to_filter_id, r.name, r.comparator, r.show_all, r.group_by_index, r.top_n, r.bottom_n, r.show_other, r.column_sid, r.period_set_id, r.period_interval_id, r.row_or_col)
		RETURNING filter_field_id INTO v_filter_field_id;
		
		FOR fv IN (
			SELECT num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, 
				   min_num_val, max_num_val, compound_filter_id_value, saved_filter_sid_value,
				   description, filter_value_id, period_set_id, period_interval_id, start_period_id,
				   filter_type, null_filter, colour
			  FROM filter_value
			 WHERE app_sid = security_pkg.GetApp
			   AND filter_field_id = r.filter_field_id
		) LOOP
			v_compound_filter_id_value := NULL;
			
			IF fv.compound_filter_id_value IS NOT NULL THEN
				-- copy embedded filter
				CopyCompoundFilter(security_pkg.GetAct, fv.compound_filter_id_value, v_compound_filter_id_value);
			END IF;
			
			INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, str_value, 
				start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, max_num_val,
				compound_filter_id_value, saved_filter_sid_value, description, period_set_id, 
				period_interval_id, start_period_id, filter_type, null_filter, colour)
			VALUES (filter_value_id_seq.NEXTVAL, v_filter_field_id, fv.num_value, fv.str_value, 
				   fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid, 
				   fv.min_num_val, fv.max_num_val, v_compound_filter_id_value, 
				   fv.saved_filter_sid_value, fv.description, fv.period_set_id,
				   fv.period_interval_id, fv.start_period_id, fv.filter_type, fv.null_filter, fv.colour)
			RETURNING filter_value_id INTO v_new_filter_value_id;
			
			INSERT INTO tt_filter_value_map (old_filter_value_id, new_filter_value_id)
			VALUES (fv.filter_value_id, v_new_filter_value_id);
		END LOOP;
		
		
		-- copy top n cache
		INSERT INTO filter_field_top_n_cache (filter_field_id, group_by_index, filter_value_id)
			SELECT v_filter_field_id, fftnc.group_by_index, fvm.new_filter_value_id
			  FROM filter_field_top_n_cache fftnc
			  JOIN tt_filter_value_map fvm ON fftnc.filter_value_id = old_filter_value_id
			 WHERE app_sid = security_pkg.GetApp
			   AND fftnc.filter_field_id = r.filter_field_id;
	END LOOP;
END;

PROCEDURE GetFieldsAndValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_field_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_value_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_READ);
	
	OPEN out_field_cur FOR
		SELECT filter_field_id, name, NVL(show_all,0) show_all, group_by_index, top_n, bottom_n,
		       show_other, column_sid, period_set_id, period_interval_id, comparator, row_or_col
		  FROM v$filter_field
		 WHERE filter_id = in_filter_id;
	
	OPEN out_value_cur FOR
		SELECT filter_field_id, name, filter_value_id, str_value, num_value, start_dtm_value,
			   end_dtm_value - 1 end_dtm_value, region_sid, description, user_sid, compound_filter_id_value,
			   saved_filter_sid_value, period_set_id, period_interval_id, start_period_id,
			   min_num_val, max_num_val, null_filter, colour,
			   CASE
					WHEN filter_type IS NOT NULL THEN filter_type
					WHEN num_value IS NOT NULL AND num_value >= 0 AND max_num_val IS NULL AND min_num_val IS NULL THEN FILTER_VALUE_TYPE_NUMBER
					WHEN num_value IS NOT NULL AND num_value >= 0 AND max_num_val IS NOT NULL OR min_num_val IS NOT NULL THEN FILTER_VALUE_TYPE_NUMBER_RANGE
					WHEN str_value IS NOT NULL THEN FILTER_VALUE_TYPE_STRING
					WHEN user_sid IS NOT NULL THEN FILTER_VALUE_TYPE_USER
					WHEN region_sid IS NOT NULL THEN FILTER_VALUE_TYPE_REGION
					WHEN (num_value IS NOT NULL AND num_value < 0) OR start_period_id IS NOT NULL THEN FILTER_VALUE_TYPE_DATE_RANGE
					WHEN saved_filter_sid_value IS NOT NULL THEN FILTER_VALUE_TYPE_SAVED
					WHEN compound_filter_id_value IS NOT NULL THEN FILTER_VALUE_TYPE_COMPOUND
					ELSE NULL
			   END filter_type
		  FROM v$filter_value
		 WHERE filter_id = in_filter_id
		   AND show_all = 0;
END;

FUNCTION CheckNumberRange (
	in_compare_value				IN	NUMBER,
	in_number_type					IN	NUMBER,
	in_min_value					IN	NUMBER,
	in_max_value					IN	NUMBER
) RETURN NUMBER
AS
BEGIN
	RETURN CASE WHEN (
			(in_number_type = NUMBER_BETWEEN OR
			 in_number_type = NUMBER_LESS_THAN_OR_EQUAL OR
			 in_number_type = NUMBER_GREATER_THAN_OR_EQUAL)
			AND in_compare_value >= NVL(in_min_value, in_compare_value)
			AND in_compare_value <= NVL(in_max_value, in_compare_value)
	   ) OR (
			in_number_type = NUMBER_EQUAL
			AND in_compare_value = in_min_value
	   ) OR (
			in_number_type = NUMBER_NOT_EQUAL
			AND in_compare_value != in_min_value
	   ) OR (
			in_number_type = NUMBER_LESS_THAN
			AND in_compare_value < in_max_value
	   ) OR (
			in_number_type = NUMBER_GREATER_THAN
			AND in_compare_value > in_min_value
	   ) OR (
			in_number_type = NUMBER_IS_NULL
			AND in_compare_value IS NULL
	   ) OR (
			in_number_type = NUMBER_NOT_NULL
			AND in_compare_value IS NOT NULL
	   ) THEN 1 ELSE 0 END;
END;

FUNCTION GetNumberTypeCount (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
) RETURN NUMBER
AS
	v_number_range_types			NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_number_range_types
	  FROM chain.filter_value
	 WHERE filter_field_id = in_filter_field_id
	   AND num_value != chain.filter_pkg.NUMBER_NOT_EQUAL;
	   
	RETURN v_number_range_types;
END;

PROCEDURE SortNumberValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
)
AS
BEGIN
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT * FROM (
			SELECT filter_value_id, pos, ROWNUM rn
			  FROM (
				SELECT filter_value_id, pos
				  FROM filter_value
				 WHERE filter_field_id = in_filter_field_id
				 ORDER BY NVL(min_num_val, max_num_val), num_value
				)
			)
		 WHERE DECODE(pos, rn, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET pos = r.rn
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

PROCEDURE SortFlowStateValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
)
AS
BEGIN
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT * FROM (
			SELECT MIN(fs.pos) new_pos, fv.pos old_pos, fv.filter_value_id
			  FROM filter_value fv
			  JOIN csr.flow_state fs ON fv.num_value = fs.flow_state_id
			 WHERE fv.filter_field_id = in_filter_field_id
			 GROUP BY fv.filter_value_id, fv.pos
		)
		 WHERE DECODE(new_pos, old_pos, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

PROCEDURE SortScoreThresholdValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
)
AS
BEGIN
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT s.pos new_pos, fv.pos old_pos, fv.filter_value_id
		  FROM chain.filter_value fv
		  JOIN (
			SELECT ROW_NUMBER() OVER (ORDER BY st.score_type_id, st.max_value) pos, st.score_threshold_id
			  FROM csr.score_threshold st
		  ) s ON s.score_threshold_id = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.pos, s.pos, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

PROCEDURE SetFlowStateColours (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE
)
AS
BEGIN
	-- update colour column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT fs.state_colour colour, fv.filter_value_id
		  FROM filter_value fv
		  JOIN csr.flow_state fs ON fv.num_value = fs.flow_state_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.colour, fs.state_colour, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET colour = r.colour
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

PROCEDURE SetThresholdColours (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE
)
AS
BEGIN
	-- update colour column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT st.bar_colour colour, fv.filter_value_id
		  FROM filter_value fv
		  JOIN csr.score_threshold st ON st.score_threshold_id = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.colour, st.bar_colour, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET colour = r.colour
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

/**
 *	@param in_include_time_in_filter
 */
PROCEDURE PopulateDateRangeTT (
	in_filter_field_id				IN filter_value.filter_field_id%TYPE,
	in_include_time_in_filter		IN NUMBER
)
AS
	v_future_start					DATE;
BEGIN
	-- No security checks on in_filter_field_id - only called from filter units
	
	-- TODO: This is called on every row, it's not a good idea to be 
	-- running a select to another table - we should store this in sys_context or something?
	IF m_user_date IS NULL THEN
		SELECT COALESCE(ut.timezone, a.timezone, 'Etc/GMT')
		  INTO m_user_timezone
		  FROM security.user_table ut, security.application a
		 WHERE ut.sid_id = security_pkg.GetSid
		   AND a.application_sid_id = security_pkg.GetApp;

		m_user_date := TRUNC(SYSTIMESTAMP AT TIME ZONE m_user_timezone);
	END IF;

	IF in_include_time_in_filter = 1 THEN
		v_future_start := SYSTIMESTAMP AT TIME ZONE m_user_timezone;
	ELSE
		-- NOTE: for the purposes of filtering the future does not start until tommorow (when dealing with just dates)
		v_future_start := m_user_date + 1;
	END IF;
	
	DELETE FROM tt_filter_date_range;

	INSERT INTO tt_filter_date_range (filter_value_id, group_by_index, start_dtm, end_dtm, null_filter)
		SELECT filter_value_id, group_by_index, 
			   -- Convert result to UTC if required 
			   CASE WHEN in_include_time_in_filter = 0 
				  THEN start_dtm ELSE FROM_TZ(CAST(start_dtm AS TIMESTAMP), m_user_timezone) AT TIME ZONE 'Etc/GMT'
			   END,
			   CASE WHEN in_include_time_in_filter = 0
				  THEN end_dtm ELSE FROM_TZ(CAST(end_dtm AS TIMESTAMP), m_user_timezone) AT TIME ZONE 'Etc/GMT'
			   END,
			   null_filter
		FROM (
			SELECT fv.filter_value_id, ff.group_by_index, fv.num_value,
				   CASE fv.num_value
					   WHEN DATE_SPECIFY_DATES THEN fv.start_dtm_value
					   WHEN DATE_TODAY THEN m_user_date
					   WHEN DATE_YEAR_TO_DATE THEN TRUNC(m_user_date, 'YEAR')
					   WHEN DATE_YEAR_TO_DATE_PREV_YEAR THEN ADD_MONTHS(TRUNC(m_user_date, 'YEAR'), -12)
					   WHEN DATE_IN_THE_LAST_WEEK THEN m_user_date - 7
					   WHEN DATE_IN_THE_LAST_MONTH THEN ADD_MONTHS(m_user_date, -1)
					   WHEN DATE_IN_THE_LAST_THREE_MONTHS THEN ADD_MONTHS(m_user_date, -3)
					   WHEN DATE_IN_THE_LAST_SIX_MONTHS THEN ADD_MONTHS(m_user_date, -6)
					   WHEN DATE_IN_THE_LAST_YEAR THEN ADD_MONTHS(m_user_date, -12)
					   WHEN DATE_IN_THE_PAST THEN NULL
					   WHEN DATE_IN_THE_FUTURE THEN v_future_start 
					   WHEN DATE_IN_THE_NEXT_WEEK THEN m_user_date + 1
					   WHEN DATE_IN_THE_NEXT_MONTH THEN m_user_date + 1
					   WHEN DATE_IN_THE_NEXT_THREE_MONTHS THEN m_user_date + 1
					   WHEN DATE_IN_THE_NEXT_SIX_MONTHS THEN m_user_date + 1
					   WHEN DATE_IN_THE_NEXT_YEAR THEN m_user_date + 1
				   END start_dtm,
				   CASE fv.num_value
					   WHEN DATE_SPECIFY_DATES THEN fv.end_dtm_value
					   WHEN DATE_TODAY THEN m_user_date + 1
					   WHEN DATE_YEAR_TO_DATE THEN m_user_date + 1
					   WHEN DATE_YEAR_TO_DATE_PREV_YEAR THEN ADD_MONTHS(m_user_date, -12) + 1
					   WHEN DATE_IN_THE_LAST_WEEK THEN m_user_date + 1
					   WHEN DATE_IN_THE_LAST_MONTH THEN m_user_date + 1
					   WHEN DATE_IN_THE_LAST_THREE_MONTHS THEN m_user_date + 1
					   WHEN DATE_IN_THE_LAST_SIX_MONTHS THEN m_user_date + 1
					   WHEN DATE_IN_THE_LAST_YEAR THEN m_user_date + 1
					   WHEN DATE_IN_THE_PAST THEN v_future_start
					   WHEN DATE_IN_THE_FUTURE THEN NULL
					   WHEN DATE_IN_THE_NEXT_WEEK THEN m_user_date + 8
					   WHEN DATE_IN_THE_NEXT_MONTH THEN ADD_MONTHS(m_user_date, 1) + 1
					   WHEN DATE_IN_THE_NEXT_THREE_MONTHS THEN ADD_MONTHS(m_user_date, 3) + 1
					   WHEN DATE_IN_THE_NEXT_SIX_MONTHS THEN ADD_MONTHS(m_user_date, 6) + 1
					   WHEN DATE_IN_THE_NEXT_YEAR THEN ADD_MONTHS(m_user_date, 12) + 1
				   END end_dtm,
				   CASE fv.num_value 
					   WHEN DATE_IS_NULL THEN NULL_FILTER_REQUIRE_NULL
					   WHEN DATE_NOT_NULL THEN NULL_FILTER_EXCLUDE_NULL
					   ELSE NULL_FILTER_ALL
				   END null_filter
			FROM filter_value fv
			JOIN filter_field ff ON fv.app_sid = ff.app_sid AND fv.filter_field_id = ff.filter_field_id
			WHERE fv.filter_field_id = in_filter_field_id
		);
END;

PROCEDURE GetLargestDateWindow (
	in_compound_filter_id	IN	compound_filter.compound_filter_id%TYPE,
	in_field_name			IN	filter_field.name%TYPE,
	in_helper_pkg			IN	filter_type.helper_pkg%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	out_start_dtm			OUT	DATE,
	out_end_dtm				OUT	DATE
)
AS
	v_date_filter_field_id			filter_field.filter_field_id%TYPE;
BEGIN
	SELECT MIN(ff.filter_field_id)
	  INTO v_date_filter_field_id
	  FROM chain.filter_field ff
	  JOIN chain.filter f ON ff.filter_id = f.filter_id AND ff.app_sid = f.app_sid
	  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
	 WHERE f.compound_filter_id = in_compound_filter_id
	   AND ff.name=in_field_name
	   AND ff.group_by_index IS NULL
	   AND LOWER(ft.helper_pkg) = in_helper_pkg;
	
	IF v_date_filter_field_id IS NOT NULL THEN
		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id		=> v_date_filter_field_id,
			in_include_time_in_filter => 0
		);
		
		SELECT CASE WHEN COUNT(CASE WHEN start_dtm IS NULL THEN 1 END) > 0 THEN in_start_dtm ELSE
			   GREATEST(NVL(in_start_dtm,MIN(start_dtm)), NVL(MIN(start_dtm),in_start_dtm)) END,
			   CASE WHEN COUNT(CASE WHEN end_dtm IS NULL THEN 1 END) > 0 THEN in_end_dtm ELSE
			   LEAST(NVL(in_end_dtm,MAX(end_dtm)), NVL(MAX(end_dtm),in_end_dtm)) END
		  INTO out_start_dtm, out_end_dtm
		  FROM chain.tt_filter_date_range;
	ELSE
		
		out_start_dtm := in_start_dtm;
		out_end_dtm := in_end_dtm;
		
	END IF;
END;

PROCEDURE CreateDateRangeValues (
	in_filter_field_id		IN	NUMBER,
	in_min_date				IN	DATE,
	in_max_date				IN	DATE
)
AS
	v_date						DATE;
	v_last_date					DATE;
	v_period_set_id				filter_field.period_set_id%TYPE;
	v_period_interval_id		filter_field.period_interval_id%TYPE;
	v_annual_periods			csr.period_set.annual_periods%TYPE;
	v_broader_interval_exists	NUMBER;
	v_interval_number			NUMBER;
	v_total_intervals			NUMBER;
	v_start_period_id			filter_value.start_period_id%TYPE;
BEGIN
	IF in_min_date IS NULL OR in_max_date IS NULL THEN
		-- no values, clean up
		DELETE FROM filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND num_value = DATE_SPECIFY_DATES;
		   
		RETURN;
	END IF;
	
	
	SELECT ff.period_set_id, ff.period_interval_id, ps.annual_periods,
		   CASE WHEN EXISTS (
			SELECT *
			  FROM filter_field pff
			  JOIN filter_field nff
				ON pff.filter_id = nff.filter_id
			   AND pff.name = nff.name
			   AND pff.period_set_id = nff.period_set_id
			   AND pff.group_by_index < nff.group_by_index
			   AND pff.filter_field_id != nff.filter_field_id
			  JOIN csr.period_interval_member pim
				ON pff.period_set_id = pim.period_set_id
			   AND pff.period_interval_id = pim.period_interval_id
			 WHERE nff.filter_field_id = in_filter_field_id
			 HAVING MAX(pim.start_period_id - pim.end_period_id) > i.max_interval_width
		   ) THEN 1 ELSE 0 END
	  INTO v_period_set_id, v_period_interval_id, v_annual_periods,
		   v_broader_interval_exists
	  FROM filter_field ff
	  LEFT JOIN csr.period_set ps ON ff.period_set_id = ps.period_set_id
	  LEFT JOIN (
		SELECT period_set_id, period_interval_id, MAX(end_period_id - start_period_id) max_interval_width
		  FROM csr.period_interval_member
		 GROUP BY period_set_id, period_interval_id
	  ) i ON ff.period_set_id = i.period_set_id AND ff.period_interval_id = i.period_interval_id
	 WHERE filter_field_id = in_filter_field_id;

	DELETE FROM filter_value
	 WHERE filter_field_id = in_filter_field_id
	   AND num_value = DATE_SPECIFY_DATES
	   AND (DECODE(period_set_id, v_period_set_id, 1, 0) != 1
		OR DECODE(period_interval_id, v_period_interval_id, 1, 0) != 1
		OR start_dtm_value > in_max_date
		OR end_dtm_value <= in_min_date
	   );
	
	IF v_period_set_id IS NOT NULL THEN
		SELECT COUNT(*) total_intervals
		  INTO v_total_intervals
		  FROM csr.period_interval_member
		 WHERE period_set_id = v_period_set_id
		   AND period_interval_id = v_period_interval_id;
		
		IF v_period_interval_id IS NULL THEN
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_NO_PERIOD_INTERVAL_ID, 'No period interval specified.');
		END IF;

		-- period sets
		IF v_broader_interval_exists = 0 THEN
			-- first breakdown (i.e. broadest granularity) on this field - use start/end dates
			v_interval_number := csr.period_pkg.GetIntervalNumber(v_period_set_id, v_period_interval_id, in_min_date);
			v_date := csr.period_pkg.GetPeriodDate(v_period_set_id, csr.period_pkg.GetPeriodNumber(v_period_set_id, v_period_interval_id, v_interval_number));

			WHILE (v_date <= in_max_date) LOOP
				v_last_date := v_date;
				
				SELECT start_period_id
				  INTO v_start_period_id
				  FROM (
					SELECT start_period_id, ROWNUM rn
					  FROM (
						SELECT start_period_id
						  FROM csr.period_interval_member
						 WHERE period_set_id = v_period_set_id
						   AND period_interval_id = v_period_interval_id
						 ORDER BY start_period_id
						)
					)
				 WHERE rn = MOD(v_interval_number - 1, v_total_intervals) + 1;
				
				v_date := csr.period_pkg.GetPeriodDate(v_period_set_id, csr.period_pkg.GetPeriodNumber(v_period_set_id, v_period_interval_id, v_interval_number + 1));
				INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, start_dtm_value, 
										  end_dtm_value, period_set_id, period_interval_id, start_period_id,
										  description, filter_type)
				SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, DATE_SPECIFY_DATES, v_last_date, 
					   v_date, v_period_set_id, v_period_interval_id, v_start_period_id,
					   v_interval_number, FILTER_VALUE_TYPE_DATE_RANGE
				  FROM dual
				 WHERE NOT EXISTS (
					SELECT *
					  FROM filter_value fv
					 WHERE fv.filter_field_id = in_filter_field_id
					   AND fv.start_dtm_value = v_last_date
				 );
				
				v_interval_number := v_interval_number + 1;
			END LOOP;
		ELSE
			-- subsequent breakdown on this field - just use period
			v_interval_number := csr.period_pkg.GetIntervalNumber(v_period_set_id, v_period_interval_id, in_min_date);
			v_date := csr.period_pkg.GetPeriodDate(v_period_set_id, csr.period_pkg.GetPeriodNumber(v_period_set_id, v_period_interval_id, v_interval_number));
			
			WHILE (v_date <= in_max_date) LOOP
				
				SELECT start_period_id
				  INTO v_start_period_id
				  FROM (
					SELECT start_period_id, ROWNUM rn
					  FROM (
						SELECT start_period_id
						  FROM csr.period_interval_member
						 WHERE period_set_id = v_period_set_id
						   AND period_interval_id = v_period_interval_id
						 ORDER BY start_period_id
						)
					)
				 WHERE rn = MOD(v_interval_number - 1, v_total_intervals) + 1;
				
				INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, period_set_id,
										  period_interval_id, start_period_id, pos, description, filter_type)
				SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, DATE_SPECIFY_DATES, v_period_set_id,
					   v_period_interval_id, v_start_period_id, v_start_period_id, v_interval_number, FILTER_VALUE_TYPE_DATE_RANGE
				  FROM dual
				 WHERE NOT EXISTS (
					SELECT *
					  FROM filter_value fv
					 WHERE fv.filter_field_id = in_filter_field_id
					   AND fv.start_period_id = v_start_period_id
				 );
				
				v_interval_number := v_interval_number + 1;
				v_date := csr.period_pkg.GetPeriodDate(v_period_set_id, csr.period_pkg.GetPeriodNumber(v_period_set_id, v_period_interval_id, v_interval_number));
			END LOOP;
		END IF;
	ELSIF MONTHS_BETWEEN(in_max_date, in_min_date) <= 1 THEN	
		v_date := TRUNC(in_min_date);
		 
		-- lock these rows to prevent another session from modifying
		-- this happens in the calendar chart when quickly switching from one month
		-- to another and then back again as the first transaction wants to remove
		-- the rows, and the second one wants to use them, but doesn't do anything with them
		-- to lock them, so the first session ends up overwritting the values and the second one gets
		-- the incorrect values
		UPDATE filter_value
		   SET filter_value_id = filter_value_id
		 WHERE filter_field_id = in_filter_field_id;
		
		-- Remove any years or months outside of new range
		DELETE FROM filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND num_value = DATE_SPECIFY_DATES
		   AND (end_dtm_value - start_dtm_value > 1
		    OR period_set_id IS NOT NULL
			OR start_dtm_value < v_date
			OR start_dtm_value > in_max_date
		 );
		 
		-- Do days
		WHILE v_date <= in_max_date LOOP
			INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, start_dtm_value, 
			                          end_dtm_value, description, filter_type)
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, DATE_SPECIFY_DATES, v_date, 
			       v_date + 1, TO_CHAR(v_date, 'DD-MM-YYYY'), FILTER_VALUE_TYPE_DATE_RANGE -- TODO: i18n
			  FROM dual
			 WHERE NOT EXISTS (
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.start_dtm_value = v_date
			 );
			v_date := v_date + 1;
		END LOOP;
	ELSIF MONTHS_BETWEEN(in_max_date, in_min_date) <= 12 THEN
		--ensure the filter_value rows include all months if range is greater than or equal to 12 months
		
		-- Remove any years or months outside of new range
		DELETE FROM filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND num_value = DATE_SPECIFY_DATES
		   AND (end_dtm_value - start_dtm_value > 31
		    OR period_set_id IS NOT NULL
		 );
		
		-- Do months
		v_date := TRUNC(in_min_date, 'MON');
		WHILE v_date <= in_max_date LOOP
			INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, start_dtm_value, 
			                          end_dtm_value, description, filter_type)
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, DATE_SPECIFY_DATES, v_date, 
			       ADD_MONTHS(v_date,1), TO_CHAR(v_date, 'Month YYYY'), FILTER_VALUE_TYPE_DATE_RANGE  -- TODO: i18n
			  FROM dual
			 WHERE NOT EXISTS (
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.start_dtm_value = v_date
			 );
			v_date := ADD_MONTHS(v_date, 1);
		END LOOP;
	ELSE
		--ensure the filter_value rows include all years if range is greater than 12 months
		
		-- Remove any months or years outside of new range
		DELETE FROM filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND num_value = DATE_SPECIFY_DATES
		   AND (end_dtm_value - start_dtm_value < 365
		    OR period_set_id IS NOT NULL
		 );
		
		-- Do years
		v_date := TRUNC(in_min_date, 'YEAR');
		WHILE v_date <= in_max_date LOOP
			INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, start_dtm_value, 
			                          end_dtm_value, description, filter_type)
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, DATE_SPECIFY_DATES, v_date, 
			       ADD_MONTHS(v_date,12), TO_CHAR(v_date, 'YYYY'), FILTER_VALUE_TYPE_DATE_RANGE -- TODO: i18n
			  FROM dual
			 WHERE NOT EXISTS (
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.start_dtm_value = v_date
			 );
			v_date := ADD_MONTHS(v_date, 12);
		END LOOP;
	END IF;
		
	
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT * FROM (
			SELECT filter_value_id, pos, ROWNUM rn
			  FROM (
				SELECT filter_value_id, pos
				  FROM filter_value
				 WHERE filter_field_id = in_filter_field_id
				 ORDER BY start_dtm_value
				)
			)
		 WHERE DECODE(pos, rn, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET pos = r.rn
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
END;

PROCEDURE SetupCalendarDateField (	
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_WRITE);

	UPDATE filter_field
	   SET period_set_id = NULL,
	       period_interval_id = NULL,
		   show_all = 1
	 WHERE group_by_index = 1
	   AND filter_id IN (
		SELECT filter_id
		  FROM filter
		 WHERE compound_filter_id = in_compound_filter_id
	   );
END;

PROCEDURE ShowAllTags (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE,
	in_tag_group_id					IN  csr.tag_group.tag_group_id%TYPE
)
AS
BEGIN
	--ensure the filter_value rows include all options
	INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
	SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, t.tag_id, t.tag
	  FROM csr.v$tag t
	  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id
	 WHERE tgm.tag_group_id = in_tag_group_id
	   AND NOT EXISTS (
		SELECT *
		  FROM filter_value fv
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND fv.num_value = t.tag_id
	 );
END;


PROCEDURE ApplyBreadcrumb (
	in_filtered_ids			IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb			IN	security_pkg.T_SID_IDS,
	out_filtered_ids		OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_breadcrumb					security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_breadcrumb);
BEGIN
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(ids.object_id, NULL, NULL)
		  BULK COLLECT INTO out_filtered_ids
		  FROM TABLE(in_filtered_ids) ids
		  JOIN TABLE(v_breadcrumb) bc ON ids.group_by_value = bc.sid_id AND ids.group_by_index = bc.pos
		 GROUP BY ids.object_id
		HAVING COUNT(DISTINCT ids.group_by_index) = v_breadcrumb_count;
END;

PROCEDURE GetFilterList(
	in_card_group_id		IN	card_group.card_group_id%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_cms_id_column_sid	IN  saved_filter.cms_id_column_sid%TYPE,
	in_for_report			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_agg_types			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_permissible_sids		security.T_SO_TABLE;
	v_saved_filter_sids		security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing filters in container with sid '||in_parent_sid);
	END IF;
	
	v_permissible_sids := securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, in_parent_sid, security_pkg.PERMISSION_READ);
	
	SELECT sf.saved_filter_sid
	  BULK COLLECT INTO v_saved_filter_sids
	  FROM saved_filter sf
	  JOIN TABLE(v_permissible_sids) v ON sf.saved_filter_sid = v.sid_id
	  LEFT JOIN cms.tab_column tc ON sf.cms_id_column_sid = tc.column_sid
	 WHERE sf.parent_sid = in_parent_sid
	   AND sf.card_group_id = NVL(in_card_group_id, sf.card_group_id)
	   AND (in_cms_id_column_sid IS NULL OR sf.cms_id_column_sid = in_cms_id_column_sid)
	   AND (sf.cms_id_column_sid IS NULL OR security_pkg.SQL_IsAccessAllowedSID(v_act_id, tc.tab_sid, security_pkg.PERMISSION_READ) = 1)
	   AND (in_for_report = 0 OR sf.exclude_from_reports = 0);
	
	OPEN out_cur FOR
		SELECT sf.saved_filter_sid item_sid, sf.name, parent_sid, sf.compound_filter_id, 
		       NVL(sf.region_column_id, sf.cms_region_column_sid) region_column_id,
		       NVL(sf.date_column_id, sf.cms_date_column_sid) date_column_id,
		       sf.card_group_id,
		       sf.exclude_from_reports,
			   security_pkg.SQL_IsAccessAllowedSid(v_act_id, sf.saved_filter_sid, security_pkg.PERMISSION_WRITE) can_write,
			   security_pkg.SQL_IsAccessAllowedSid(v_act_id, sf.saved_filter_sid, security_pkg.PERMISSION_DELETE) can_delete
		  FROM saved_filter sf
		  JOIN TABLE(v_saved_filter_sids) v ON sf.saved_filter_sid = v.column_value
		 ORDER BY sf.name;
		 
	OPEN out_agg_types FOR
		SELECT sfat.saved_filter_sid, NVL(sfat.aggregation_type, sfat.customer_aggregate_type_id) aggregate_type_id
		  FROM saved_filter_aggregation_type sfat
		  JOIN TABLE(v_saved_filter_sids) v ON sfat.saved_filter_sid = v.column_value;
	
	OPEN out_regions_cur FOR
		SELECT sfr.saved_filter_sid, sfr.region_sid
		  FROM saved_filter_region sfr
		  JOIN TABLE(v_saved_filter_sids) v ON sfr.saved_filter_sid = v.column_value;
END;

PROCEDURE RunCompoundFilter(
	in_filter_proc_name				VARCHAR2,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_sids					T_FILTERED_OBJECT_TABLE;
	v_result_sids					T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := StartDebugLog('chain.filter_pkg.RunCompoundFilter', in_compound_filter_id );
	
	v_starting_sids := in_id_list;

	IF in_parallel = 0 THEN
		out_id_list := in_id_list;
	ELSE
		out_id_list := T_FILTERED_OBJECT_TABLE();
	END IF;

	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);	
	CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM filter f
		  JOIN filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.' || in_filter_proc_name ||'(:filter_id, :parallel, :max_group_by, :input, :output);END;') USING r.filter_id, in_parallel, in_max_group_by, v_starting_sids, OUT v_result_sids;
		
		IF in_parallel = 0 THEN
			v_starting_sids := v_result_sids;
			out_id_list := v_result_sids;
		ELSE
			out_id_list := out_id_list MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
	
	EndDebugLog(v_log_id);
END;

FUNCTION FindTopNForFilterField (
	in_field_filter_id				IN	compound_filter.compound_filter_id%TYPE,
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  filter_field.group_by_index%TYPE,
	in_aggregation_type				IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE
) RETURN security.T_ORDERED_SID_TABLE
AS
	v_top_n_values					security.T_ORDERED_SID_TABLE;
BEGIN
	-- run first part of block for one filter field but using the working ids
	SELECT security.T_ORDERED_SID_ROW(top_bottom.filter_field_id, top_bottom.group_by_value)
	  BULK COLLECT INTO v_top_n_values
	  FROM (
		-- top n fields
		SELECT filter_field_id, group_by_value, top_n, bottom_n, val_number,
			   ROW_NUMBER() OVER (PARTITION BY FILTER_FIELD_ID ORDER BY val_number DESC NULLS LAST, group_by_value ASC) rn_from_top,
			   ROW_NUMBER() OVER (PARTITION BY FILTER_FIELD_ID ORDER BY val_number ASC NULLS LAST, group_by_value ASC) rn_from_bottom
		  FROM (
			SELECT ff.filter_field_id, it.group_by_value, ff.top_n, ff.bottom_n,
				   CASE o.agg_type_id
						WHEN AFUNC_COUNT THEN COUNT(o.val_number)
						WHEN AFUNC_SUM THEN SUM(o.val_number)
						WHEN AFUNC_AVERAGE THEN ROUND(AVG(o.val_number), 10)
						WHEN AFUNC_MIN THEN ROUND(MIN(o.val_number), 10)
						WHEN AFUNC_MAX THEN ROUND(MAX(o.val_number), 10)
						--WHEN AFUNC_MEDIAN THEN ROUND(MEDIAN(o.val_number), 10)
						WHEN AFUNC_STD_DEV THEN ROUND(STDDEV(o.val_number), 10)
						--WHEN AFUNC_COUNT_DISTINCT THEN COUNT(DISTINCT o.val_number)
						--WHEN AFUNC_OTHER THEN NULL
				   END val_number
			  FROM (
				SELECT ff.filter_field_id, ff.top_n, ff.bottom_n, ff.group_by_index
				  FROM chain.filter f 
				  JOIN chain.filter_field ff ON ff.filter_id = f.filter_id
				 WHERE f.compound_filter_id = in_field_filter_id
				   AND ff.filter_field_id = in_filter_field_id
				   AND ROWNUM > 0 -- force this to materialize so that it does these joins first, otherwise oracle seems to go nuts
			  ) ff
			  JOIN TABLE(in_ids) it ON it.group_by_index = ff.group_by_index
			  JOIN tt_filter_object_data o ON it.object_id = o.object_id
			 WHERE o.data_type_id = in_aggregation_type
			 GROUP BY o.agg_type_id, ff.filter_field_id, it.group_by_value, ff.top_n, ff.bottom_n
			 )
		 ) top_bottom
	 WHERE top_bottom.rn_from_top <= NVL(top_bottom.top_n, 0)
		OR top_bottom.rn_from_bottom <= NVL(top_bottom.bottom_n, 0);
		
	-- add single row to output set for filter field / - group by index
	-- Use the negative of the group_by_index for the "Others". It's negative so it doesn't overlap with value_ids and
	-- we use the group_by_index because it's easy to get
	v_top_n_values.extend;
	v_top_n_values(v_top_n_values.COUNT) := security.T_ORDERED_SID_ROW(in_filter_field_id, -in_group_by_index);	
	
	-- cache the results
	DELETE FROM filter_field_top_n_cache
	 WHERE filter_field_id = in_filter_field_id;
	INSERT INTO filter_field_top_n_cache (filter_field_id, group_by_index, filter_value_id)
	     SELECT in_filter_field_id, in_group_by_index, pos
		   FROM TABLE(v_top_n_values);

	RETURN v_top_n_values;
END;

FUNCTION FindTopN (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_type				IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_max_group_by					IN	NUMBER DEFAULT NULL
) RETURN security.T_ORDERED_SID_TABLE
AS
	v_breadcrumb_table				security.T_SID_TABLE;
BEGIN

	v_breadcrumb_table := security_pkg.SidArrayToTable(in_breadcrumb);

	return FindTopN(in_field_filter_id, in_aggregation_type, in_ids, v_breadcrumb_table, in_max_group_by);
END;

FUNCTION FindTopN (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_type				IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	in_max_group_by					IN	NUMBER DEFAULT NULL
) RETURN security.T_ORDERED_SID_TABLE
AS
	v_top_n_values					security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE(); -- not sids, but this exists already, consider new types
	v_temp_values					security.T_ORDERED_SID_TABLE; 
	v_log_id						debug_log.debug_log_id%TYPE;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := in_ids;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
	v_breadcrumb					NUMBER;
	v_temp_text						VARCHAR2(255);
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := StartDebugLog('chain.filter_pkg.FindTopN');
		
	-- for each field in the breakdowns
	FOR r IN (
		-- Collect the fields that require an "Others" block - i.e. they have show_all=1 and more than n values
		SELECT ff.filter_field_id, ff.group_by_index, 
			   CASE WHEN ff.show_all = 1 AND NVL(ff.top_n,0) + NVL(ff.bottom_n, 0) > 0 THEN 1 ELSE 0 END is_top_n
		  FROM chain.filter_field ff
		  JOIN chain.filter_value fv ON ff.filter_field_id = fv.filter_field_id
		  JOIN chain.filter f ON ff.filter_id = f.filter_id
		 WHERE f.compound_filter_id = in_field_filter_id
		   AND ff.group_by_index <= NVL(in_max_group_by, 4)
		 GROUP BY ff.filter_field_id, ff.group_by_index,  CASE WHEN ff.show_all = 1 AND NVL(ff.top_n,0) + NVL(ff.bottom_n, 0) > 0 THEN 1 ELSE 0 END
		 ORDER BY ff.group_by_index
	) LOOP	
		-- if there is a breadcrumb for this level, 
		v_breadcrumb := CASE WHEN in_breadcrumb.COUNT < r.group_by_index THEN NULL ELSE in_breadcrumb(r.group_by_index) END;
		IF v_breadcrumb IS NOT NULL THEN
			IF v_breadcrumb >= 0 THEN
				-- then filter the working ids down				
				SELECT chain.T_FILTERED_OBJECT_ROW(t1.object_id, t1.group_by_index, t1.group_by_value)
				  BULK COLLECT INTO(v_temp_ids)
				  FROM TABLE(v_ids) t1
				 WHERE EXISTS (
					SELECT 1
					  FROM TABLE(v_ids) t2
					 WHERE t1.object_id = t2.object_id
					   AND t2.group_by_index = r.group_by_index
					   AND t2.group_by_value = v_breadcrumb
				);
				v_ids := v_temp_ids;
				
				-- add single row to output set for filter field / breadcrumb
				v_top_n_values.extend;
				v_top_n_values(v_top_n_values.COUNT) := security.T_ORDERED_SID_ROW(r.filter_field_id, v_breadcrumb);
			ELSE
				-- else its the 'other' group
				SELECT security.T_ORDERED_SID_ROW(filter_field_id, filter_value_id)
				  BULK COLLECT INTO v_temp_values
				  FROM filter_field_top_n_cache
				 WHERE filter_field_id = r.filter_field_id
				   AND group_by_index = r.group_by_index;
				
				IF v_temp_values.COUNT = 0 THEN
					v_temp_values := FindTopNForFilterField(in_field_filter_id, r.filter_field_id, r.group_by_index, in_aggregation_type, v_ids);
				END IF;
				
				v_top_n_values := v_top_n_values MULTISET UNION v_temp_values;
				
				-- then filter the working ids down to the other group
				SELECT chain.T_FILTERED_OBJECT_ROW(t1.object_id, t1.group_by_index, t1.group_by_value)
				  BULK COLLECT INTO(v_temp_ids)
				  FROM TABLE(v_ids) t1
				 WHERE EXISTS (
					SELECT 1
					  FROM TABLE(v_ids) t2
					 WHERE t1.object_id = t2.object_id
					   AND t2.group_by_index = r.group_by_index
					   AND t2.group_by_value NOT IN (
							SELECT pos
							  FROM TABLE(v_temp_values)
					   )
				 );
				 
				v_ids := v_temp_ids;
			END IF;
		ELSE			
			-- clear old cached values			
			DELETE FROM filter_field_top_n_cache
			 WHERE filter_field_id = r.filter_field_id;
		
			IF r.is_top_n = 1 THEN
				v_temp_values := FindTopNForFilterField(in_field_filter_id, r.filter_field_id, r.group_by_index, in_aggregation_type, v_ids);
				v_top_n_values := v_top_n_values MULTISET UNION v_temp_values;
			ELSE
				-- just pull all filter values for this field
				SELECT security.T_ORDERED_SID_ROW(ff.filter_field_id, fv.filter_value_id)
				  BULK COLLECT INTO v_temp_values
				  FROM chain.filter_field ff
				  JOIN chain.filter_value fv ON ff.filter_field_id = fv.filter_field_id
				  JOIN chain.filter f ON ff.filter_id = f.filter_id
				 WHERE f.compound_filter_id = in_field_filter_id
				   AND ff.filter_field_id = r.filter_field_id;

				v_top_n_values := v_top_n_values MULTISET UNION v_temp_values;
			END IF;
		END IF;
	END LOOP;
	
	EndDebugLog(v_log_id);
	
	RETURN v_top_n_values;
END;

PROCEDURE GetAllFilterFieldValues (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	out_top_n_values				OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	-- we don't need a top n, so grab all
	SELECT security.T_ORDERED_SID_ROW(ff.filter_field_id, fv.filter_value_id)
	  BULK COLLECT INTO out_top_n_values
	  FROM chain.filter_field ff
	  JOIN chain.filter_value fv ON ff.filter_field_id = fv.filter_field_id
	  JOIN chain.filter f ON ff.filter_id = f.filter_id
	 WHERE f.compound_filter_id = in_field_filter_id;
END;

FUNCTION GetCompFilterIdFromBreadcrumb(
	in_breadcrumb					IN	security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_field_compound_filter_id		NUMBER;
BEGIN
	-- Join up from the filter value up to get the compound filter id 
	SELECT MIN(f.compound_filter_id)
	  INTO v_field_compound_filter_id
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON ff.filter_id = f.filter_id
	  LEFT JOIN chain.filter_value fv ON fv.filter_field_id = ff.filter_field_id
	 WHERE (fv.filter_value_id = in_breadcrumb(1)
		OR ff.filter_field_id = -in_breadcrumb(1));
		
	RETURN v_field_compound_filter_id;
END;

FUNCTION GetCompoundFilterIdFromAdapter(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER
) RETURN NUMBER
AS
	v_compound_filter_id			NUMBER;
BEGIN
	-- There should be at most one of these filter values
	SELECT MIN(fv.compound_filter_id_value)
	  INTO v_compound_filter_id
	  FROM chain.v$filter_value fv
	  -- join to make sure that there is at least one filter to run
	  JOIN chain.filter cf ON fv.compound_filter_id_value = cf.compound_filter_id
	 WHERE fv.filter_id = in_filter_id
	   AND fv.filter_field_id = in_filter_field_id;
	   
	-- check that the filter actually has values to filter on
	IF IsCompoundFilterEmpty(v_compound_filter_id) = 1 THEN
		RETURN NULL;
	END IF;
	   
	RETURN v_compound_filter_id;
END;

FUNCTION GetGroupByLimit(
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE
) RETURN NUMBER
AS
	v_group_by_limit				NUMBER := 0;
BEGIN
	SELECT MAX(group_by_index)
	  INTO v_group_by_limit
	  FROM chain.v$filter_field
	 WHERE compound_filter_id = in_field_filter_id;
	
	RETURN v_group_by_limit;
END;

PROCEDURE GetAggregateData (
	in_card_group_id				IN	chain.card_group.card_group_id%TYPE,
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	in_max_group_by					IN	NUMBER,
	in_show_totals					IN	NUMBER,
	in_object_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	in_top_n_values					IN  security.T_ORDERED_SID_TABLE,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR
)
AS
	v_breadcrumb_1					NUMBER;
	v_breadcrumb_2					NUMBER;
	v_breadcrumb_3					NUMBER;
	v_breadcrumb_4					NUMBER;
	v_group_by_limit				NUMBER := LEAST(GetGroupByLimit(in_field_filter_id), NVL(in_max_group_by, 4));
	v_breadcrumb_count				NUMBER := in_breadcrumb.COUNT;
	v_log_id						debug_log.debug_log_id%TYPE;

	v_group_by_pivot				T_GROUP_BY_PIVOT_TABLE;
	v_filter_object_data			T_FILTER_OBJECT_DATA_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := StartDebugLog('chain.filter_pkg.GetAggregateData', in_field_filter_id);

	v_breadcrumb_1 := CASE WHEN in_breadcrumb.COUNT < 1 THEN NULL ELSE in_breadcrumb(1) END;
	v_breadcrumb_2 := CASE WHEN in_breadcrumb.COUNT < 2 THEN NULL ELSE in_breadcrumb(2) END;
	v_breadcrumb_3 := CASE WHEN in_breadcrumb.COUNT < 3 THEN NULL ELSE in_breadcrumb(3) END;
	v_breadcrumb_4 := CASE WHEN in_breadcrumb.COUNT < 4 THEN NULL ELSE in_breadcrumb(4) END;

	IF in_field_filter_id IS NOT NULL THEN
	
		DELETE FROM TT_GROUP_BY_FIELD_VALUE;
		INSERT INTO TT_GROUP_BY_FIELD_VALUE (object_id, group_by_index, filter_value_id)
			SELECT DISTINCT t.object_id, ff.group_by_index, CASE WHEN fr.sid_id IS NULL THEN -fv.filter_field_id ELSE fr.pos END filter_value_id
			  FROM filter_value fv
			  JOIN filter_field ff ON fv.app_sid = ff.app_sid AND fv.filter_field_id = ff.filter_field_id
			  JOIN filter f ON ff.app_sid = f.app_sid AND ff.filter_id = f.filter_id
			  LEFT JOIN TABLE(in_top_n_values) fr ON ff.filter_field_id = fr.sid_id AND fv.filter_value_id = fr.pos
			  JOIN TABLE(in_object_id_list) t ON fv.filter_value_id = t.group_by_value AND ff.group_by_index = t.group_by_index
			 WHERE f.compound_filter_id = in_field_filter_id
			   AND (fr.sid_id IS NOT NULL OR ff.show_other = 1);
		
		DELETE FROM TT_GROUP_BY_PIVOT;
		INSERT INTO TT_GROUP_BY_PIVOT (object_id, filter_value_id1, filter_value_id2, filter_value_id3, filter_value_id4)
		SELECT fv1.object_id,
			   fv1.filter_value_id filter_value_id1,
			   fv2.filter_value_id filter_value_id2,
			   fv3.filter_value_id filter_value_id3,
			   fv4.filter_value_id filter_value_id4
		  FROM TT_GROUP_BY_FIELD_VALUE fv1
		  LEFT JOIN TT_GROUP_BY_FIELD_VALUE fv2 ON fv2.group_by_index = 2 AND fv1.object_id = fv2.object_id AND (in_max_group_by IS NULL OR in_max_group_by >= 2)
		  LEFT JOIN TT_GROUP_BY_FIELD_VALUE fv3 ON fv3.group_by_index = 3 AND fv1.object_id = fv3.object_id AND (in_max_group_by IS NULL OR in_max_group_by >= 3)
		  LEFT JOIN TT_GROUP_BY_FIELD_VALUE fv4 ON fv4.group_by_index = 4 AND fv1.object_id = fv4.object_id AND (in_max_group_by IS NULL OR in_max_group_by >= 4)
		 WHERE fv1.group_by_index = 1
		   -- apply breadcrumb if there is one
		   AND (v_breadcrumb_1 IS NULL OR fv1.filter_value_id = v_breadcrumb_1)
		   AND (v_breadcrumb_2 IS NULL OR fv2.filter_value_id = v_breadcrumb_2)
		   AND (v_breadcrumb_3 IS NULL OR fv3.filter_value_id = v_breadcrumb_3)
		   AND (v_breadcrumb_4 IS NULL OR fv4.filter_value_id = v_breadcrumb_4)
		   -- ensure we have data up to the level we're requesting (because we have left joins above)
		   AND (v_group_by_limit < 2 OR fv2.object_id IS NOT NULL)
		   AND (v_group_by_limit < 3 OR fv3.object_id IS NOT NULL)
		   AND (v_group_by_limit < 4 OR fv4.object_id IS NOT NULL);
	
		SELECT T_GROUP_BY_PIVOT_ROW(piv.object_id, piv.filter_value_id1, piv.filter_value_id2, piv.filter_value_id3, piv.filter_value_id4)
		  BULK COLLECT INTO v_group_by_pivot
		  FROM tt_group_by_pivot piv;

		SELECT T_FILTER_OBJECT_DATA_ROW(tfod.data_type_id, tfod.agg_type_id, tfod.object_id, tfod.val_number, tfod.filter_value_id)
		  BULK COLLECT INTO v_filter_object_data
		  FROM tt_filter_object_data tfod;

		OPEN out_data_cur FOR
			SELECT /*+ALL_ROWS*/
				   piv.filter_value_id1, piv.filter_value_id2, piv.filter_value_id3, piv.filter_value_id4,
				   GROUPING(piv.filter_value_id1) is_total1,
				   GROUPING(piv.filter_value_id2) is_total2,
				   GROUPING(piv.filter_value_id3) is_total3,
				   GROUPING(piv.filter_value_id4) is_total4,
				   at.column_value aggregation_type,
				   CASE o.agg_type_id
							WHEN AFUNC_COUNT THEN COUNT(o.val_number)
							WHEN AFUNC_SUM THEN SUM(o.val_number)
							WHEN AFUNC_AVERAGE THEN ROUND(AVG(o.val_number), 10)
							WHEN AFUNC_MIN THEN ROUND(MIN(o.val_number), 10)
							WHEN AFUNC_MAX THEN ROUND(MAX(o.val_number), 10)
							-- removed because it causes ORA-22905: cannot access rows from a non-nested table item
							--WHEN AFUNC_MEDIAN THEN ROUND(MEDIAN(o.val_number), 10)
							WHEN AFUNC_STD_DEV THEN ROUND(STDDEV(o.val_number), 10)
							-- removed because it causes ORA-22905: cannot access rows from a non-nested table item
							--WHEN AFUNC_COUNT_DISTINCT THEN COUNT(DISTINCT o.val_number)
							--WHEN AFUNC_OTHER THEN NULL
					   END val_number
			  FROM TABLE(v_group_by_pivot) piv
			  CROSS JOIN TABLE(in_aggregation_types) at
			  JOIN TABLE(v_filter_object_data) o ON piv.object_id = o.object_id AND at.column_value = o.data_type_id 
			   AND (o.filter_value_id IS NULL 
			    OR piv.filter_value_id1 = o.filter_value_id 
				OR piv.filter_value_id2 = o.filter_value_id 
				OR piv.filter_value_id3 = o.filter_value_id 
				OR piv.filter_value_id4 = o.filter_value_id)
			 GROUP BY at.column_value, o.agg_type_id, CUBE(piv.filter_value_id1, piv.filter_value_id2, piv.filter_value_id3, piv.filter_value_id4)
			HAVING ((in_show_totals = 1 AND v_group_by_limit > 0) OR GROUPING(piv.filter_value_id1) = 0)
			   AND ((in_show_totals = 1 AND v_group_by_limit > 1) OR GROUPING(piv.filter_value_id2) = 0)
			   AND ((in_show_totals = 1 AND v_group_by_limit > 2) OR GROUPING(piv.filter_value_id3) = 0)
			   AND ((in_show_totals = 1 AND v_group_by_limit > 3) OR GROUPING(piv.filter_value_id4) = 0)
			 ORDER BY at.column_value, o.agg_type_id, piv.filter_value_id1, piv.filter_value_id2, piv.filter_value_id3, piv.filter_value_id4;
		
		-- TODO, work out if descriptions need translations
		OPEN out_field_cur FOR
			SELECT fv.filter_id, fv.filter_field_id, fv.name, fv.filter_value_id, fv.description, 
				   fv.group_by_index, fv.pos position, fv.period_set_id, fv.period_interval_id, fv.start_period_id,
				   fv.start_dtm_value, fv.end_dtm_value, fv.colour, fv.row_or_col
			  FROM chain.v$filter_value fv
			 WHERE fv.compound_filter_id = in_field_filter_id
			   AND (fv.filter_field_id, fv.filter_value_id) IN (SELECT sid_id, pos FROM TABLE(in_top_n_values))
			   AND fv.group_by_index > v_breadcrumb_count
			   AND fv.group_by_index <= in_max_group_by
			 UNION ALL
			SELECT ff.filter_id, ff.filter_field_id, ff.name, -ff.filter_field_id, 'Other', ff.group_by_index, 999999, -- large position to stick other at the end
				   NULL, NULL, NULL, NULL, NULL, NULL, 0
			  FROM chain.v$filter_field ff
			 WHERE ff.compound_filter_id = in_field_filter_id
			   AND (ff.filter_field_id, -ff.group_by_index) IN (SELECT sid_id, pos FROM TABLE(in_top_n_values))
			   AND ff.group_by_index > v_breadcrumb_count
			   AND ff.group_by_index <= in_max_group_by
			   AND ff.show_other = 1;
	ELSE
		SELECT T_FILTER_OBJECT_DATA_ROW(tfod.data_type_id, tfod.agg_type_id, tfod.object_id, tfod.val_number, tfod.filter_value_id)
		  BULK COLLECT INTO v_filter_object_data
		  FROM tt_filter_object_data tfod;

		OPEN out_data_cur FOR
			SELECT -1 filter_value_id1, o.data_type_id aggregation_type,
					CASE o.agg_type_id
							WHEN AFUNC_COUNT THEN COUNT(o.val_number)
							WHEN AFUNC_SUM THEN SUM(o.val_number)
							WHEN AFUNC_AVERAGE THEN ROUND(AVG(o.val_number), 10)
							WHEN AFUNC_MIN THEN ROUND(MIN(o.val_number), 10)
							WHEN AFUNC_MAX THEN ROUND(MAX(o.val_number), 10)
							--WHEN AFUNC_MEDIAN THEN ROUND(MEDIAN(o.val_number), 10)
							WHEN AFUNC_STD_DEV THEN ROUND(STDDEV(o.val_number), 10)
							--WHEN AFUNC_COUNT_DISTINCT THEN COUNT(DISTINCT o.val_number)
							--WHEN AFUNC_OTHER THEN NULL
				   END val_number
			  --FROM tt_filter_object_data o
			  FROM TABLE(v_filter_object_data) o
			 GROUP BY o.data_type_id, o.agg_type_id;
		
		OPEN out_field_cur FOR
			SELECT -1 filter_value_id, 'x' name, 1 group_by_index, description
			  FROM aggregate_type at
			  JOIN TABLE(in_aggregation_types) t on at.aggregate_type_id = t.column_value
			 WHERE at.card_group_id = in_card_group_id
			   AND ROWNUM = 1;
	END IF;
	
	EndDebugLog(v_log_id);
END;

PROCEDURE PopulateTempRegionSid (
	in_region_sids					IN	security.T_SID_TABLE,	
	in_region_col_type				IN	NUMBER,
	out_has_regions					OUT NUMBER
)
AS
BEGIN
	out_has_regions := CASE WHEN in_region_col_type IS NOT NULL AND in_region_sids IS NOT NULL AND CARDINALITY(in_region_sids) > 0 THEN 1 ELSE 0 END;
	
	DELETE FROM csr.temp_region_sid;
	
	IF out_has_regions = 1 THEN
		INSERT INTO csr.temp_region_sid (region_sid)
		SELECT DISTINCT NVL(link_to_region_sid, region_sid)
		  FROM csr.region
		 START WITH region_sid IN (SELECT column_value FROM TABLE(in_region_sids))
		CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
	END IF;
END;

PROCEDURE GetAvailableGroups (
	out_available_groups_cur	OUT SYS_REFCURSOR
)
AS
	v_groups_sid				security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups');
BEGIN
	-- query limits groups to those the user has permissions to see
	
	OPEN out_available_groups_cur FOR
		SELECT so.sid_id id, so.name description
		  FROM TABLE(securableobject_pkg.GetChildrenWithPermAsTable(security_pkg.GetAct, v_groups_sid, security_pkg.PERMISSION_READ)) so
		 WHERE so.name NOT IN ('Everyone', 'RegisteredUsers', 'Chain Users');
END;

PROCEDURE GetFilterReportConfig (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_group_key				IN	filter_page_column.group_key%TYPE DEFAULT NULL,
	in_path						IN	filter_item_config.path%TYPE DEFAULT NULL,
	out_inds_cur				OUT SYS_REFCURSOR,
	out_inds_interval_cur		OUT SYS_REFCURSOR,
	out_cms_tables_cur			OUT SYS_REFCURSOR,
	out_agg_types_cur			OUT SYS_REFCURSOR,
	out_page_columns_cur		OUT SYS_REFCURSOR,
	out_item_config_cur			OUT SYS_REFCURSOR,
	out_filter_cols_cur			OUT SYS_REFCURSOR,
	out_agg_type_config_cur		OUT SYS_REFCURSOR,
	out_available_groups_cur	OUT SYS_REFCURSOR,
	out_customer_cols_cur		OUT SYS_REFCURSOR,
	out_customer_items_cur		OUT SYS_REFCURSOR,
	out_cust_item_agg_typs_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security, global config
	GetFilterPageInds(in_card_group_id, out_inds_cur, out_inds_interval_cur);
	GetFilterPageCmsTables(in_card_group_id, out_cms_tables_cur);
	GetAggregateTypes(in_card_group_id, out_agg_types_cur);
	GetFilterPageColumns(in_card_group_id, in_session_prefix, out_page_columns_cur);
	GetFilterItemConfig(in_card_group_id, in_session_prefix, in_path, out_item_config_cur);
	GetFilterColumns(in_card_group_id, NULL, out_filter_cols_cur);
	GetAggregateTypeConfig(in_card_group_id, in_session_prefix, in_path, out_agg_type_config_cur);
	GetAvailableGroups(out_available_groups_cur);
	GetCustomerFilterColumns(in_card_group_id, in_session_prefix, out_customer_cols_cur);
	GetCustomerFilterItems(in_card_group_id, in_session_prefix, out_customer_items_cur, out_cust_item_agg_typs_cur);
END;

PROCEDURE GetFilterPageColumns (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix		IN  filter_page_column.session_prefix%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_session_prefix			filter_page_column.session_prefix%TYPE := NULL;
BEGIN
	
	-- Any exact matches?
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT * 
			  FROM filter_page_column
			 WHERE card_group_id = in_card_group_id
			   AND LOWER(session_prefix) = LOWER(in_session_prefix)
		)
	) LOOP
		v_session_prefix := in_session_prefix;
	END LOOP;

	-- no security on the base data
	OPEN out_cur FOR
		SELECT fpc.card_group_id, fpc.column_name, fpc.label, fpc.pos, fpc.width, fpc.fixed_width, fpc.hidden,
			   fpc.group_sid, fpc.include_in_export
		  FROM filter_page_column fpc
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y ON fpc.group_sid = y.column_value
		 WHERE fpc.card_group_id = NVL(in_card_group_id, fpc.card_group_id)
		   AND (fpc.group_sid IS NULL OR y.column_value IS NOT NULL OR SYS_CONTEXT('SECURITY','IS_SUPERADMIN') = 1)
		   AND (LOWER(v_session_prefix) = LOWER(fpc.session_prefix) OR (v_session_prefix IS NULL AND fpc.session_prefix IS NULL))
		 ORDER BY fpc.pos;
END;

PROCEDURE GetFilterItemConfig (
	in_card_group_id			IN	filter_item_config.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_path						IN	filter_item_config.path%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_session_prefix			filter_page_column.session_prefix%TYPE := NULL;
BEGIN
	
	-- Are there any filter items for this session_prefix? If so we'll return them,
	-- if not, we'll return the filter items for the card_group_id
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT * 
			  FROM filter_item_config
			 WHERE card_group_id = in_card_group_id
			   AND LOWER(session_prefix) = LOWER(in_session_prefix)
			   AND (path = in_path OR (path IS NULL AND in_path IS NULL))
		)
	) LOOP
		v_session_prefix := in_session_prefix;
	END LOOP;
	
	-- no security on the base data
	OPEN out_cur FOR
		SELECT fig.card_group_id, fig.card_id, fig.item_name, fig.label, fig.pos,
			   fig.group_sid, fig.include_in_filter, fig.include_in_breakdown,
			   fig.include_in_advanced, fig.path, c.js_class_type,
			   CASE WHEN fig.group_sid IS NOT NULL AND y.column_value IS NULL AND SYS_CONTEXT('SECURITY','IS_SUPERADMIN') IS NULL THEN 1 ELSE 0 END hidden_by_group
		  FROM filter_item_config fig
		  JOIN card c on fig.card_id = c.card_id
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y ON fig.group_sid = y.column_value
		 WHERE fig.card_group_id = NVL(in_card_group_id, fig.card_group_id)
		   AND (LOWER(v_session_prefix) = LOWER(fig.session_prefix) OR (v_session_prefix IS NULL AND fig.session_prefix IS NULL))
		   AND (in_path = fig.path OR (in_path IS NULL AND fig.path IS NULL))
		 ORDER BY fig.pos;
END;

PROCEDURE GetAggregateTypeConfig (
	in_card_group_id			IN	aggregate_type_config.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_path						IN	aggregate_type_config.path%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_session_prefix			filter_page_column.session_prefix%TYPE := NULL;
BEGIN
	
	-- Are there any aggregate types for this session_prefix? If so we'll return them,
	-- if not, we'll return the aggreagte types for the card_group_id
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT * 
			  FROM aggregate_type_config
			 WHERE card_group_id = in_card_group_id
			   AND LOWER(session_prefix) = LOWER(in_session_prefix)
			   AND (path = in_path OR (path IS NULL AND in_path IS NULL))
		)
	) LOOP
		v_session_prefix := in_session_prefix;
	END LOOP;
	
	-- no security on the base data
	OPEN out_cur FOR
		SELECT atc.card_group_id, atc.aggregate_type_id, atc.label, atc.pos,
			   atc.group_sid, atc.enabled, atc.path,
			   CASE WHEN atc.group_sid IS NOT NULL AND y.column_value IS NULL AND SYS_CONTEXT('SECURITY','IS_SUPERADMIN') IS NULL THEN 1 ELSE 0 END hidden_by_group
		  FROM aggregate_type_config atc
		  LEFT JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y ON atc.group_sid = y.column_value
		 WHERE atc.card_group_id = NVL(in_card_group_id, atc.card_group_id)
		   AND (LOWER(v_session_prefix) = LOWER(atc.session_prefix) OR (v_session_prefix IS NULL AND atc.session_prefix IS NULL))
		   AND (in_path = atc.path OR (in_path IS NULL AND atc.path IS NULL))
		 ORDER BY atc.pos;
END;

PROCEDURE ClearFilterPageColumns (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix		IN  filter_page_column.session_prefix%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('Quick chart management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with quick chart management capability can modify filter page columns.');
	END IF;
	
	DELETE FROM filter_page_column
	 WHERE card_group_id = in_card_group_id
	   AND (LOWER(session_prefix) = LOWER(in_session_prefix) OR (session_prefix IS NULL AND in_session_prefix IS NULL));
END;

PROCEDURE SaveFilterPageColumn (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE,
	in_group_key				IN	filter_page_column.group_key%TYPE DEFAULT NULL,
	in_column_name				IN  filter_page_column.column_name%TYPE, 
	in_label					IN  filter_page_column.label%TYPE, 
	in_pos						IN  filter_page_column.pos%TYPE, 
	in_width					IN  filter_page_column.width%TYPE DEFAULT 150, 
	in_fixed_width				IN  filter_page_column.fixed_width%TYPE DEFAULT 0, 
	in_hidden					IN  filter_page_column.hidden%TYPE DEFAULT 0,
	in_group_sid				IN  filter_page_column.group_sid%TYPE DEFAULT NULL,
	in_include_in_export		IN  filter_page_column.include_in_export%TYPE DEFAULT 0
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('Quick chart management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with quick chart management capability can modify filter page columns.');
	END IF;
	
	BEGIN
		INSERT INTO filter_page_column (card_group_id, session_prefix, group_key, column_name, label, pos, width, fixed_width, hidden, group_sid, include_in_export)
		     VALUES (in_card_group_id, in_session_prefix, in_group_key, in_column_name, in_label, in_pos, in_width, in_fixed_width, in_hidden, in_group_sid, in_include_in_export);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE filter_page_column
			   SET label = in_label,
			       pos = in_pos,
				   width = in_width,
				   fixed_width = in_fixed_width,
				   hidden = in_hidden,
				   group_sid = in_group_sid,
				   include_in_export = in_include_in_export
			 WHERE card_group_id = in_card_group_id
			   AND (LOWER(session_prefix) = LOWER(in_session_prefix) OR (session_prefix IS NULL AND in_session_prefix IS NULL))
			   AND column_name = in_column_name;
	END;
END;

PROCEDURE SaveFilterItemConfig (
	in_card_group_id			IN  filter_item_config.card_group_id%TYPE,
	in_js_class_type			IN	card.js_class_type%TYPE,
	in_session_prefix			IN  filter_item_config.session_prefix%TYPE,
	in_item_name				IN  filter_item_config.item_name%TYPE, 
	in_label					IN  filter_item_config.label%TYPE, 
	in_pos						IN  filter_item_config.pos%TYPE, 
	in_group_sid				IN  filter_item_config.group_sid%TYPE DEFAULT NULL,
	in_path						IN  filter_item_config.path%TYPE DEFAULT NULL,
	in_include_in_filter		IN  filter_item_config.include_in_filter%TYPE DEFAULT 1,
	in_include_in_breakdown		IN  filter_item_config.include_in_breakdown%TYPE DEFAULT 1,
	in_include_in_advanced		IN  filter_item_config.include_in_advanced%TYPE DEFAULT 1
)
AS
	v_card_id					card.card_id%TYPE := card_pkg.GetCardId(in_js_class_type);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('Quick chart management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with quick chart management capability can modify filter item config.');
	END IF;
	
	BEGIN
		INSERT INTO filter_item_config (card_group_id, card_id, session_prefix, path, item_name, label, pos, group_sid, include_in_filter, include_in_breakdown, include_in_advanced)
		     VALUES (in_card_group_id, v_card_id, in_session_prefix, in_path, in_item_name, in_label, in_pos, in_group_sid, in_include_in_filter, in_include_in_breakdown, in_include_in_advanced);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE filter_item_config
			   SET label = in_label,
			       pos = in_pos,
				   group_sid = in_group_sid,
				   include_in_filter = in_include_in_filter,
				   include_in_breakdown = in_include_in_breakdown,
				   include_in_advanced = in_include_in_advanced
			 WHERE card_group_id = in_card_group_id
			   AND card_id = v_card_id
			   AND (LOWER(session_prefix) = LOWER(in_session_prefix) OR (session_prefix IS NULL AND in_session_prefix IS NULL))
			   AND (path = in_path OR path IS NULL AND in_path IS NULL)
			   AND item_name = in_item_name;
	END;
	
END;

PROCEDURE SaveAggregateTypeConfig (
	in_card_group_id			IN  aggregate_type_config.card_group_id%TYPE,
	in_aggregate_type_id		IN  aggregate_type_config.aggregate_type_id%TYPE, 
	in_session_prefix			IN  aggregate_type_config.session_prefix%TYPE DEFAULT NULL,
	in_label					IN  aggregate_type_config.label%TYPE, 
	in_pos						IN  aggregate_type_config.pos%TYPE DEFAULT NULL, 
	in_group_sid				IN  aggregate_type_config.group_sid%TYPE DEFAULT NULL,
	in_path						IN  aggregate_type_config.path%TYPE DEFAULT NULL,
	in_enabled					IN  aggregate_type_config.enabled%TYPE DEFAULT 1
)
AS
	v_pos						aggregate_type_config.pos%TYPE := in_pos;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('Quick chart management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with quick chart management capability can modify filter item config.');
	END IF;
	
	IF in_pos IS NULL THEN
		SELECT NVL(MAX(pos),0) + 1
		  INTO v_pos
		  FROM aggregate_type_config
		 WHERE card_group_id = in_card_group_id
		   AND (LOWER(session_prefix) = LOWER(in_session_prefix) OR (session_prefix IS NULL AND in_session_prefix IS NULL))
		   AND (path = in_path OR path IS NULL AND in_path IS NULL);
	END IF;
	
	BEGIN
		INSERT INTO aggregate_type_config (card_group_id, aggregate_type_id, session_prefix, path, label, pos, group_sid, enabled)
		     VALUES (in_card_group_id, in_aggregate_type_id, in_session_prefix, in_path,  in_label, v_pos, in_group_sid, in_enabled);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE aggregate_type_config
			   SET label = in_label,
			       pos = v_pos,
				   group_sid = in_group_sid,
				   enabled = in_enabled
			 WHERE card_group_id = in_card_group_id
			   AND aggregate_type_id = in_aggregate_type_id
			   AND (LOWER(session_prefix) = LOWER(in_session_prefix) OR (session_prefix IS NULL AND in_session_prefix IS NULL))
			   AND (path = in_path OR path IS NULL AND in_path IS NULL);
	END;
	
END;

FUNCTION UNSEC_AddCustomerAggregateType (
	in_card_group_id				IN  customer_aggregate_type.card_group_id%TYPE,
	in_cms_aggregate_type_id		IN  customer_aggregate_type.cms_aggregate_type_id%TYPE DEFAULT NULL,
	in_initiative_metric_id			IN  customer_aggregate_type.initiative_metric_id%TYPE DEFAULT NULL,
	in_ind_sid						IN  customer_aggregate_type.ind_sid%TYPE DEFAULT NULL,
	in_filter_page_ind_interval_id	IN  customer_aggregate_type.filter_page_ind_interval_id%TYPE DEFAULT NULL,
	in_meter_aggregate_type_id		IN  customer_aggregate_type.meter_aggregate_type_id%TYPE DEFAULT NULL,
	in_score_type_agg_type_id		IN  customer_aggregate_type.score_type_agg_type_id%TYPE DEFAULT NULL,
	in_cust_filt_item_agg_type_id	IN	customer_aggregate_type.cust_filt_item_agg_type_id%TYPE DEFAULT NULL
) RETURN NUMBER
AS
	v_customer_aggregate_type_id	customer_aggregate_type.customer_aggregate_type_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO customer_aggregate_type (card_group_id, customer_aggregate_type_id, cms_aggregate_type_id,
					initiative_metric_id, ind_sid, filter_page_ind_interval_id, meter_aggregate_type_id,
					score_type_agg_type_id, cust_filt_item_agg_type_id)
		     VALUES (in_card_group_id, customer_aggregate_type_id_seq.NEXTVAL, in_cms_aggregate_type_id,
					in_initiative_metric_id, in_ind_sid, in_filter_page_ind_interval_id, in_meter_aggregate_type_id,
					in_score_type_agg_type_id, in_cust_filt_item_agg_type_id)
		  RETURNING customer_aggregate_type_id INTO v_customer_aggregate_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			SELECT customer_aggregate_type_id
			  INTO v_customer_aggregate_type_id
			  FROM customer_aggregate_type
			 WHERE card_group_id = in_card_group_id
			   AND DECODE(cms_aggregate_type_id, in_cms_aggregate_type_id, 1) = 1
			   AND DECODE(initiative_metric_id, in_initiative_metric_id, 1) = 1
			   AND DECODE(ind_sid, in_ind_sid, 1) = 1
			   AND DECODE(filter_page_ind_interval_id, in_filter_page_ind_interval_id, 1) = 1
			   AND DECODE(meter_aggregate_type_id, in_meter_aggregate_type_id, 1) = 1
			   AND DECODE(score_type_agg_type_id, in_score_type_agg_type_id, 1) = 1
			   AND DECODE(cust_filt_item_agg_type_id, in_cust_filt_item_agg_type_id, 1) = 1;
	END;
	
	RETURN v_customer_aggregate_type_id;
END;

PROCEDURE UNSEC_RemoveCustomerAggType (
	in_customer_aggregate_type_id	IN  customer_aggregate_type.customer_aggregate_type_id%TYPE
)
AS
BEGIN
	DELETE FROM saved_filter_aggregation_type
	      WHERE customer_aggregate_type_id = in_customer_aggregate_type_id;

	DELETE FROM customer_aggregate_type
	      WHERE customer_aggregate_type_id = in_customer_aggregate_type_id;
END;

PROCEDURE GetAggregateTypes (
	in_card_group_id			IN  NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_aggregation_types			security.T_ORDERED_SID_TABLE;
	v_dummy						SYS_REFCURSOR;
BEGIN
	-- no security on the base data
	SELECT security.T_ORDERED_SID_ROW(a.aggregate_type_id, null)
	  BULK COLLECT INTO v_aggregation_types
	  FROM (
			SELECT DISTINCT aggregate_type_id
			  FROM aggregate_type
			 WHERE card_group_id = NVL(in_card_group_id, card_group_id)
			 UNION ALL
			SELECT customer_aggregate_type_id
			  FROM customer_aggregate_type
			 WHERE card_group_id = NVL(in_card_group_id, card_group_id)
		) a;
	 
	GetAggregateDetails(in_card_group_id, v_aggregation_types, NULL, out_cur, v_dummy);
END;

PROCEDURE GetFilteredIds (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_region_sids					IN  security.T_SID_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_helper_pkg					card_group.helper_pkg%TYPE;
	v_compound_filter_id			saved_filter.compound_filter_id%TYPE;
	v_search_text					saved_filter.search_text%TYPE;
	v_group_key						saved_filter.group_key%TYPE;
	v_region_col_id					saved_filter.region_column_id%TYPE;
	v_date_col_id					saved_filter.date_column_id%TYPE;
	v_cms_id_column_sid				saved_filter.cms_id_column_sid%TYPE;
BEGIN
	SELECT cg.helper_pkg, sf.compound_filter_id,sf.search_text, sf.group_key,
		   NVL(sf.region_column_id, sf.cms_region_column_sid), NVL(sf.date_column_id, sf.cms_date_column_sid),
		   cms_id_column_sid
	  INTO v_helper_pkg, v_compound_filter_id, v_search_text, v_group_key,
		   v_region_col_id, v_date_col_id, v_cms_id_column_sid
	  FROM saved_filter sf
	  JOIN card_group cg ON sf.card_group_id = cg.card_group_id
	 WHERE saved_filter_sid = in_saved_filter_sid;
	 
	CheckCompoundFilterAccess(v_compound_filter_id, security_pkg.PERMISSION_READ);
	 
	EXECUTE IMMEDIATE 'BEGIN ' || v_helper_pkg || '.GetFilteredIds(
		in_search				=> :search,
		in_group_key			=> :group_key,
		in_parent_id			=> :parent_id,
		in_compound_filter_id	=> :compound_filter_id,
		in_region_sids			=> :region_sids,
		in_region_col_type		=> :region_col,
		in_date_col_type		=> :date_col,
		out_id_list				=> :out_id_list); END;' 
	USING v_search_text, v_group_key, v_cms_id_column_sid,
		  v_compound_filter_id, in_region_sids,
		  v_region_col_id, v_date_col_id, OUT out_ids;
	
END;

PROCEDURE GetModuleAlertData (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_helper_pkg					card_group.helper_pkg%TYPE;
BEGIN
	SELECT cg.helper_pkg
	  INTO v_helper_pkg
	  FROM saved_filter sf
	  JOIN card_group cg ON sf.card_group_id = cg.card_group_id
	 WHERE saved_filter_sid = in_saved_filter_sid;
	 
	EXECUTE IMMEDIATE ('BEGIN ' || v_helper_pkg || '.GetAlertData(:in_id_list, :out_cur);END;') 
	USING in_id_list, OUT out_cur;	
END;

PROCEDURE GetEmptyExtraSeriesCur (
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_extra_series_cur FOR
		SELECT NULL val, NULL series_name, NULL pos, NULL aggregate_type_id, NULL parent_filter_value_id
		  FROM dual
		 WHERE 1=0;
END;

PROCEDURE GetReportData (
	in_card_group_id				IN  card_group.card_group_id%TYPE,
	in_search						IN	VARCHAR2,
	in_group_key					IN  saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER,
	in_parent_id					IN	NUMBER,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_types			IN	security_pkg.T_SID_IDS,
	in_show_totals					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_max_group_by					IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN  NUMBER,
	out_data_cur					OUT SYS_REFCURSOR,
	out_field_cur					OUT SYS_REFCURSOR,
	out_aggregate_cur				OUT SYS_REFCURSOR,
	out_aggregate_threshold_cur		OUT SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
	v_helper_pkg					card_group.helper_pkg%TYPE;
	
	v_aggregation_types_tbl			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_aggregation_types);
	v_ordered_agg_types_tbl			security.T_ORDERED_SID_TABLE := security_pkg.SidArrayToOrderedTable(in_aggregation_types);
	v_breadcrumb_tbl				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_breadcrumb);
	v_region_sids_tbl				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM card_group
	 WHERE card_group_id = in_card_group_id;
	 
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);	 
	 
	EXECUTE IMMEDIATE 'BEGIN ' || v_helper_pkg || '.GetReportData(
		in_search						=> :search,
		in_group_key					=> :group_key,
		in_pre_filter_sid				=> :pre_filter_sid,
		in_parent_type					=> :parent_type,
		in_parent_id					=> :parent_id,
		in_compound_filter_id			=> :compound_filter_id,
		in_grp_by_compound_filter_id	=> :group_by_compound_filter_id,
		in_aggregation_types			=> :aggregation_types,
		in_show_totals					=> :show_totals,
		in_breadcrumb					=> :breadcrumb,
		in_max_group_by					=> :max_group_by,
		in_region_sids					=> :region_sids,
		in_start_dtm					=> :start_dtm,
		in_end_dtm						=> :end_dtm,
		in_region_col_type				=> :region_col,
		in_date_col_type				=> :date_col,
		in_id_list_populated			=> :id_list_populated,
		out_field_cur					=> :out_data_cur,
		out_data_cur					=> :out_field_cur,
		out_extra_series_cur			=> :out_extra_series_cur
	); END;'
	USING in_search, in_group_key, in_pre_filter_sid, in_parent_type, in_parent_id,
		  in_compound_filter_id, in_grp_by_compound_filter_id, v_aggregation_types_tbl, 
		  in_show_totals, v_breadcrumb_tbl, in_max_group_by, v_region_sids_tbl,
		  in_start_dtm, in_end_dtm, in_region_col_type, in_date_col_type, in_id_list_populated,
		  OUT out_data_cur, OUT out_field_cur, OUT out_extra_series_cur;

	GetAggregateDetails(in_card_group_id, v_ordered_agg_types_tbl, in_parent_id, out_aggregate_cur, out_aggregate_threshold_cur);
END;

PROCEDURE GetIdsAndRegionSids (
	in_card_group_id				IN  card_group.card_group_id%TYPE,
	in_search						IN	VARCHAR2,
	in_group_key					IN  saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_cms_id_column_sid			IN  saved_filter.cms_id_column_sid%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_region_sid_cur				OUT	SYS_REFCURSOR
)
AS
	v_helper_pkg					card_group.helper_pkg%TYPE;
	
	v_in_region_sids_tbl			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_ids							T_FILTERED_OBJECT_TABLE;
	v_region_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	-- Security covered by the selects in each GetInitialId calls
	
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM card_group
	 WHERE card_group_id = in_card_group_id;
	 
	IF in_cms_id_column_sid IS NULL THEN
		EXECUTE IMMEDIATE ('BEGIN ' || v_helper_pkg || '.GetInitialIds(:search, :group_key, :pre_filter_sid,
			:region_sids, :start_dtm, :end_dtm, :region_col, :date_col, :in_ids, :out_ids);END;') 
		USING in_search, in_group_key, in_pre_filter_sid,
			v_in_region_sids_tbl, in_start_dtm, in_end_dtm, in_region_col_type, in_date_col_type, v_ids, OUT v_ids;
			
		EXECUTE IMMEDIATE ('BEGIN ' || v_helper_pkg || '.ConvertIdsToRegionSids(:in_ids, :out_region_sids);END;')
		USING v_ids, OUT v_region_sids;
	ELSE
		NULL; -- Placeholder for calling into cms 
	END IF;

	DELETE FROM tt_filter_id;	
	INSERT INTO tt_filter_id (id)
	     SELECT object_id
		   FROM TABLE(v_ids);
		   
	OPEN out_region_sid_cur FOR
		SELECT object_id region_sid
		  FROM TABLE(v_region_sids);
END;

PROCEDURE GetFilterColumns (
	in_card_group_id			IN  NUMBER,
	in_column_type				IN  card_group_column_type.column_type%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security on the base data
	OPEN out_cur FOR
		SELECT card_group_id, column_id, column_type, description
		  FROM card_group_column_type
		 WHERE card_group_id = in_card_group_id
		   AND column_type = NVL(in_column_type, column_type);
END;

/*
 * Tree View Procedures
 */
PROCEDURE GetTreeWithDepth(
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report				IN	NUMBER,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_include_root				IN	NUMBER,
	in_fetch_depth				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_use_dummy_root	NUMBER(10);
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT CASE WHEN in_include_root = 1 AND in_parent_sid = -1 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;
	
	SELECT CASE WHEN v_use_dummy_root = 1 THEN GetSharedParentSid(in_card_group_id) ELSE in_parent_sid END
		INTO v_parent_sid
		FROM dual;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing filters in container with sid '||v_parent_sid);
	END IF;		

	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT v_parent_sid sid_id, null saved_filter_sid, 'Public filters' name, 
			       1 lvl, 0 is_leaf, 0 rn, 1 translate, null region_column_id, null date_column_id,
			       null card_group_id, null tab_sid
			  FROM DUAL
			 WHERE v_use_dummy_root = 1
			 UNION ALL
			SELECT * 
			  FROM (
					SELECT v.sid_id, sf.saved_filter_sid, NVL(sf.name, v.name) name,
					       LEVEL + v_use_dummy_root lvl, v.is_leaf, ROWNUM rn, 0 translate,
					       sf.region_column_id, sf.date_column_id, sf.card_group_id, tc.tab_sid
					  FROM TABLE(securableobject_pkg.GetDescendantsWithPermAsTable(security_pkg.GetAct, v_parent_sid, security_pkg.PERMISSION_READ)) v
					  LEFT JOIN saved_filter sf ON sf.saved_filter_sid = v.sid_id
					  LEFT JOIN cms.tab_column tc ON sf.cms_id_column_sid = tc.column_sid
					 WHERE level <= in_fetch_depth
					   AND ((sf.saved_filter_sid IS NULL AND v.class_id = security_pkg.SO_CONTAINER)
					    OR (sf.card_group_id = NVL(in_card_group_id, sf.card_group_id) 
					   AND (in_cms_id_column_sid IS NULL OR sf.cms_id_column_sid = in_cms_id_column_sid)
					   AND (sf.cms_id_column_sid IS NULL OR security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, tc.tab_sid, security_pkg.PERMISSION_READ) = 1))
					   AND (in_for_report = 0 OR exclude_from_reports = 0))
					 START WITH v.parent_sid_id =  v_parent_sid
					 CONNECT BY PRIOR v.sid_id = v.parent_sid_id
					 ORDER SIBLINGS BY LOWER(NVL(sf.name, v.name))
			  )
		)
	 ORDER BY rn;
END;

PROCEDURE GetTree(
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report				IN	NUMBER,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_include_root				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_use_dummy_root	NUMBER(10);
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT CASE WHEN in_include_root = 1 AND in_parent_sid = -1 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;
	
	SELECT CASE WHEN v_use_dummy_root = 1 THEN GetSharedParentSid(in_card_group_id) ELSE in_parent_sid END
		INTO v_parent_sid
		FROM dual;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing filters in container with sid '||v_parent_sid);
	END IF;		

	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT v_parent_sid sid_id, null saved_filter_sid, 'Public filters' name, 
			       1 lvl, 0 is_leaf, 0 rn, 1 translate, null region_column_id, null date_column_id,
			       null card_group_id, null tab_sid
			  FROM DUAL
			 WHERE v_use_dummy_root = 1
			 UNION ALL
			SELECT * 
			  FROM (
					SELECT v.sid_id, sf.saved_filter_sid, NVL(sf.name, v.name) name,
					       LEVEL + v_use_dummy_root lvl, v.is_leaf, ROWNUM rn, 0 translate,
					       sf.region_column_id, sf.date_column_id, sf.card_group_id, tc.tab_sid
					  FROM TABLE(securableobject_pkg.GetDescendantsWithPermAsTable(security_pkg.GetAct, v_parent_sid, security_pkg.PERMISSION_READ)) v
					  LEFT JOIN saved_filter sf
						ON sf.saved_filter_sid = v.sid_id
					  LEFT JOIN cms.tab_column tc
						ON sf.cms_id_column_sid = tc.column_sid
					 WHERE ((sf.saved_filter_sid IS NULL AND v.class_id = security_pkg.SO_CONTAINER)
					    OR (sf.card_group_id = NVL(in_card_group_id, sf.card_group_id) 
					   AND (in_cms_id_column_sid IS NULL OR sf.cms_id_column_sid = in_cms_id_column_sid)
					   AND (sf.cms_id_column_sid IS NULL OR security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, tc.tab_sid, security_pkg.PERMISSION_READ) = 1))
					   AND (in_for_report = 0 OR exclude_from_reports = 0))
					 START WITH v.parent_sid_id =  v_parent_sid
					 CONNECT BY PRIOR v.sid_id = v.parent_sid_id
					 ORDER SIBLINGS BY LOWER(NVL(sf.name, v.name))
			  )
		)
	 ORDER BY rn;
END;

PROCEDURE GetTreeTextFiltered(
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report				IN	NUMBER,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_include_root				IN	NUMBER,
	in_search_phrase			IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_use_dummy_root	NUMBER(10);
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT CASE WHEN in_include_root = 1 AND in_parent_sid = -1 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;
	
	SELECT CASE WHEN v_use_dummy_root = 1 THEN GetSharedParentSid(in_card_group_id) ELSE in_parent_sid END
		INTO v_parent_sid
		FROM dual;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing filters in container with sid '||v_parent_sid);
	END IF;		

	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT v_parent_sid sid_id, null saved_filter_sid, 'Public filters' name, 
			       1 lvl, 0 is_leaf, 0 rn, 1 translate, null region_column_id, null date_column_id,
			       null card_group_id, null tab_sid
			  FROM DUAL
			 WHERE v_use_dummy_root = 1
			 UNION ALL
			SELECT * 
			  FROM (
					SELECT v.sid_id, sf.saved_filter_sid, NVL(sf.name, v.name) name,
					       LEVEL + v_use_dummy_root lvl, v.is_leaf, ROWNUM rn, 0 translate,
					       sf.region_column_id, sf.date_column_id, sf.card_group_id, tc.tab_sid
					  FROM TABLE(securableobject_pkg.GetDescendantsWithPermAsTable(security_pkg.GetAct, v_parent_sid, security_pkg.PERMISSION_READ)) v
					  LEFT JOIN saved_filter sf ON sf.saved_filter_sid = v.sid_id
					  LEFT JOIN cms.tab_column tc ON sf.cms_id_column_sid = tc.column_sid
					 WHERE ((sf.saved_filter_sid IS NULL AND v.class_id = security_pkg.SO_CONTAINER)
					    OR (sf.card_group_id = NVL(in_card_group_id, sf.card_group_id) 
					   AND (in_cms_id_column_sid IS NULL OR sf.cms_id_column_sid = in_cms_id_column_sid)
					   AND (sf.cms_id_column_sid IS NULL OR security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, tc.tab_sid, security_pkg.PERMISSION_READ) = 1))
					   AND (in_for_report = 0 OR exclude_from_reports = 0))
					 START WITH v.parent_sid_id =  v_parent_sid
					 CONNECT BY PRIOR v.sid_id = v.parent_sid_id
					 ORDER SIBLINGS BY LOWER(NVL(sf.name, v.name))
			  )
		) tree, (
			SELECT v_parent_sid sid_id
			  FROM dual
			 UNION ALL
			SELECT DISTINCT sid_id
			  FROM TABLE(securableobject_pkg.GetDescendantsWithPermAsTable(security_pkg.GetAct, v_parent_sid, security_pkg.PERMISSION_READ))
			 	START WITH sid_id IN ( 
			 		SELECT saved_filter_sid 
			 		  FROM saved_filter
			 		 WHERE (LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
			 	)
			 	CONNECT BY PRIOR parent_sid_id = sid_id 
		) ft
		WHERE tree.sid_id = ft.sid_id
		ORDER BY rn;
END;


PROCEDURE GetListTextFiltered(
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report				IN	NUMBER,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_search_phrase			IN	VARCHAR2,
	in_fetch_limit				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	
	SELECT CASE WHEN in_parent_sid = -1 THEN GetSharedParentSid(in_card_group_id) ELSE in_parent_sid END
		INTO v_parent_sid
		FROM dual;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing filters in container with sid '||v_parent_sid);
	END IF;		

	OPEN out_cur FOR
		SELECT * 
		-- ************* N.B. that's a literal 0x1 character in there, not a space **************
		  FROM (
			SELECT v.sid_id, sf.saved_filter_sid, NVL(sf.name, v.name) name,
				   LEVEL lvl, v.is_leaf, ROWNUM rn, 0 translate,
				   replace(ltrim(sys_connect_by_path(NVL(sf.name, v.name), ''),''),'',' > ') path,
				   sf.region_column_id, sf.date_column_id, sf.card_group_id, tc.tab_sid
			  FROM TABLE(securableobject_pkg.GetDescendantsWithPermAsTable(security_pkg.GetAct, v_parent_sid, security_pkg.PERMISSION_READ)) v
			  LEFT JOIN saved_filter sf ON sf.saved_filter_sid = v.sid_id
			  LEFT JOIN cms.tab_column tc ON sf.cms_id_column_sid = tc.column_sid
			 WHERE LOWER(NVL(sf.name, v.name)) LIKE '%'||LOWER(in_search_phrase)||'%'
			   AND sf.card_group_id = NVL(in_card_group_id, sf.card_group_id)
			   AND (in_cms_id_column_sid IS NULL OR sf.cms_id_column_sid = in_cms_id_column_sid)
			   AND (sf.cms_id_column_sid IS NULL OR security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, tc.tab_sid, security_pkg.PERMISSION_READ) = 1)
			   AND (in_for_report = 0 OR exclude_from_reports = 0)
			 START WITH v.parent_sid_id =  v_parent_sid
			 CONNECT BY PRIOR v.sid_id = v.parent_sid_id
			 ORDER SIBLINGS BY LOWER(NVL(sf.name, v.name))
		)
		WHERE rownum <= in_fetch_limit
	    ORDER BY rn;
END;

/*
 * End Tree View Procedures
 */
 
 /*
 * Start of alert procedures
 */
PROCEDURE GetAlertJobs (
	out_cur							OUT SYS_REFCURSOR,
	out_users_cur					OUT SYS_REFCURSOR
)
AS
	v_sysdate						DATE := CAST(sys_extract_utc(SYSTIMESTAMP) AS DATE);
BEGIN
	-- no security, only called by scheduled tasks
	OPEN out_cur FOR
		SELECT sfa.app_sid, sfa.saved_filter_sid, sfa.customer_alert_type_id,
			   sfa.every_n_minutes, sfa.schedule_xml, sf.card_group_id, sf.cms_id_column_sid, 
			   tc.tab_sid, sf.list_page_url, sfa.next_fire_time, sf.company_sid
		  FROM saved_filter_alert sfa
		  JOIN saved_filter sf ON sfa.saved_filter_sid = sf.saved_filter_sid AND sfa.app_sid = sf.app_sid
		  LEFT JOIN cms.tab_column tc ON sf.cms_id_column_sid = tc.column_sid AND sf.app_sid = tc.app_sid
		 WHERE next_fire_time < v_sysdate
		   AND (sf.card_group_id != FILTER_TYPE_CMS OR tc.tab_sid IS NOT NULL) -- check that we have a tab_sid for CMS filters
		 ORDER BY app_sid;
		 
	OPEN out_users_cur FOR
		SELECT sfas.saved_filter_sid, sfas.user_sid, sfas.region_sid, sfas.has_had_initial_set
		  FROM saved_filter_alert_subscriptn sfas
		  JOIN security.user_table ut ON sfas.user_sid = ut.sid_id
		 WHERE ut.account_enabled = 1 
		   AND (sfas.app_sid, sfas.saved_filter_sid) IN (
			SELECT app_sid, saved_filter_sid
			  FROM saved_filter_alert
			 WHERE next_fire_time < v_sysdate
		);
END;

PROCEDURE GetAllAlertParams (
	out_cg_cur						OUT SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security. Called by scheduled tasks
	
	OPEN out_cg_cur FOR
		SELECT card_group_id, list_page_url
		  FROM card_group
		 WHERE helper_pkg IS NOT NULL; -- just the card groups that are filters
	
	OPEN out_params_cur FOR
		SELECT card_group_id, field_name, description, translatable, link_text
		  FROM saved_filter_alert_param;
	
END;

PROCEDURE GetAlertData (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_all_ids						T_FILTERED_OBJECT_TABLE;
	v_new_ids						T_FILTERED_OBJECT_TABLE;
BEGIN
	-- no security, only called by scheduled tasks
	
	-- get ids
	GetFilteredIds(in_saved_filter_sid, v_region_sids, v_all_ids);
	
	-- subtract the sent ones
	SELECT T_FILTERED_OBJECT_ROW(i.object_id, NULL, NULL)
	  BULK COLLECT INTO v_new_ids
	  FROM TABLE(v_all_ids) i
	 WHERE NOT EXISTS (
		SELECT *
		  FROM saved_filter_sent_alert sa
		 WHERE sa.object_id = i.object_id
		   AND sa.saved_filter_sid = in_saved_filter_sid
		   AND sa.user_sid = security_pkg.GetSid
	 );
	
	-- delete the sent ones that are no longer in the list
	DELETE FROM saved_filter_sent_alert sa
		  WHERE sa.saved_filter_sid = in_saved_filter_sid
		    AND sa.user_sid = security_pkg.GetSid
	        AND sa.object_id NOT IN (
				SELECT object_id
				  FROM TABLE(v_all_ids)
			);
	
	-- return cursor of alert data
	IF CARDINALITY(v_new_ids) = 0 THEN
		OPEN out_cur FOR
			SELECT null object_id
			  FROM dual
			 WHERE 1 = 0;
	ELSE
		GetModuleAlertData(in_saved_filter_sid, v_new_ids, out_cur);
	END IF;
END;

PROCEDURE SetupInitialSet (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS
)
AS
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_all_ids						T_FILTERED_OBJECT_TABLE;
BEGIN
	-- no security, only called by scheduled tasks/internally after security check	
	-- get ids
	GetFilteredIds(in_saved_filter_sid, v_region_sids, v_all_ids);
	
	-- mark them all as sent
	INSERT INTO saved_filter_sent_alert (saved_filter_sid, user_sid, object_id, sent_dtm)
		 SELECT in_saved_filter_sid, security_pkg.GetSid, i.object_id, SYSDATE
		   FROM (SELECT DISTINCT object_id FROM TABLE(v_all_ids)) i
		  WHERE NOT EXISTS (
			SELECT *
			  FROM saved_filter_sent_alert sa
			 WHERE sa.saved_filter_sid = in_saved_filter_sid
			   AND sa.user_sid = security_pkg.GetSid
			   AND sa.object_id = i.object_id
			);
	
	-- set has_had_initial_set number to 1
	UPDATE saved_filter_alert_subscriptn
	   SET has_had_initial_set = 1,
	       error_message = NULL
	 WHERE saved_filter_sid = in_saved_filter_sid
	   AND user_sid = security_pkg.GetSid
	   AND (CARDINALITY(v_region_sids) = 0 AND region_sid IS NULL
	    OR region_sid IN (
			SELECT column_value
			  FROM TABLE(v_region_sids)
		));
END;

PROCEDURE MarkAlertSent (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_object_ids					IN  security_pkg.T_SID_IDS
)
AS
	v_object_ids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_object_ids);
BEGIN
	-- no security, only called by scheduled tasks
	INSERT INTO saved_filter_sent_alert (saved_filter_sid, user_sid, object_id, sent_dtm)
	     SELECT in_saved_filter_sid, in_user_sid, column_value, SYSDATE
		   FROM (SELECT DISTINCT column_value FROM TABLE(v_object_ids));

	-- clear error message as we have successfully sent alerts
	UPDATE saved_filter_alert_subscriptn
	   SET error_message = NULL
	 WHERE saved_filter_sid = in_saved_filter_sid
	   AND user_sid = in_user_sid;
END;

PROCEDURE SetAlertErrorMessage (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_error_message				IN  saved_filter_alert_subscriptn.error_message%TYPE
)
AS
BEGIN
	-- no security, only called by scheduled tasks
	UPDATE saved_filter_alert_subscriptn
	   SET error_message = in_error_message
	 WHERE saved_filter_sid = in_saved_filter_sid
	   AND user_sid = in_user_sid;
END;

PROCEDURE SetAlertNextFireTime (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_next_fire_time				IN  saved_filter_alert.next_fire_time%TYPE,
	in_alerts_sent_on_last_run		IN  saved_filter_alert.alerts_sent_on_last_run%TYPE
)
AS
BEGIN
	-- no security, only called by scheduled tasks
	UPDATE saved_filter_alert
	   SET next_fire_time = in_next_fire_time,
	       last_fire_time = SYSDATE,
		   alerts_sent_on_last_run = in_alerts_sent_on_last_run
	 WHERE saved_filter_sid = in_saved_filter_sid;
END;

PROCEDURE PageFilterAlertSids (
	in_filter_alert_sid_list		IN	security.T_SID_TABLE,
	in_shared_sid					IN	security_pkg.T_SID_ID,
	in_company_shared_sid			IN	security_pkg.T_SID_ID,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	out_filter_alert_sid_page		OUT	security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	SELECT security.T_ORDERED_SID_ROW(saved_filter_sid, rn)
	  BULK COLLECT INTO out_filter_alert_sid_page
		  FROM (
			SELECT x.saved_filter_sid, ROWNUM rn
			  FROM (
				SELECT sf.saved_filter_sid
				  FROM saved_filter sf
				  JOIN TABLE(in_filter_alert_sid_list) fil_list ON fil_list.column_value = sf.saved_filter_sid
				  LEFT JOIN (
						SELECT so.sid_id, SYS_CONNECT_BY_PATH(so.name, ' / ') path
						  FROM security.securable_object so
						 WHERE class_id != security_pkg.SO_CONTAINER
						 START WITH so.parent_sid_id IN (in_shared_sid, in_company_shared_sid)
						CONNECT BY PRIOR so.sid_id = so.parent_sid_id
					) p ON sf.saved_filter_sid = p.sid_id
				 ORDER BY LOWER(NVL(p.path, sf.name))
				) x
			)
		  WHERE rn > NVL(in_start_row, 0)
		   AND rn <= NVL(in_end_row, rn);
END;

PROCEDURE CheckManageFilterAlertAccess (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN	
	IF NOT csr.csr_data_pkg.CheckCapability('Can manage filter alerts') 
	   OR (in_saved_filter_sid IS NOT NULL AND NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_READ)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User is missing the "Can manage filter alerts" capability or does not have read access to filter: '||in_saved_filter_sid);
	END IF;
END;

PROCEDURE GetFilterAlerts (
	in_search						IN  VARCHAR2,
	in_start_row					IN  NUMBER,
	in_end_row						IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_alert_cur					OUT SYS_REFCURSOR,
	out_subscription_cur			OUT SYS_REFCURSOR
)
AS	
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_shared_sid					security_pkg.T_SID_ID := GetSharedParentSid(NULL);
	v_company_shared_sid			security_pkg.T_SID_ID;
	v_filter_sids					security.T_SO_DESCENDANTS_TABLE;
	v_chain_filter_sids				security.T_SO_DESCENDANTS_TABLE;
	v_filter_alert_sid_list			security.T_SID_TABLE;
	v_filter_alert_sid_page			security.T_ORDERED_SID_TABLE;
BEGIN
	CheckManageFilterAlertAccess;
	
	v_filter_sids := SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_shared_sid, security_pkg.PERMISSION_READ);
	
	IF HasSavedFilters(FILTER_TYPE_COMPANIES) = 1 THEN
		v_company_shared_sid := GetSharedParentSid(FILTER_TYPE_COMPANIES);
		v_chain_filter_sids := SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_company_shared_sid, security_pkg.PERMISSION_READ);
	END IF;
	
	-- Initial list with search applied
	SELECT DISTINCT sfa.saved_filter_sid
	  BULK COLLECT INTO v_filter_alert_sid_list
	  FROM saved_filter_alert sfa
	  JOIN saved_filter sf ON sfa.saved_filter_sid = sf.saved_filter_sid
	  JOIN (SELECT * FROM TABLE(v_filter_sids) UNION SELECT * FROM TABLE(v_chain_filter_sids)) so ON sfa.saved_filter_sid = so.sid_id
	  LEFT JOIN (
			SELECT so.sid_id, SYS_CONNECT_BY_PATH(so.name, ' / ') path
			  FROM security.securable_object so
			 WHERE class_id != security_pkg.SO_CONTAINER
			 START WITH so.parent_sid_id IN (v_shared_sid, v_company_shared_sid)
			CONNECT BY PRIOR so.sid_id = so.parent_sid_id
		) p ON sfa.saved_filter_sid = p.sid_id
	  LEFT JOIN saved_filter_alert_subscriptn sfas ON sfa.saved_filter_sid = sfas.saved_filter_sid
	  LEFT JOIN csr.csr_user cu ON sfas.user_sid = cu.csr_user_sid
	  LEFT JOIN csr.v$region r ON sfas.region_sid = r.region_sid
	 WHERE LOWER(NVL(p.path, sf.name)) LIKE v_search
	    OR LOWER(sfa.description) LIKE v_search
	    OR LOWER(cu.full_name) LIKE v_search
	    OR LOWER(cu.user_name) LIKE v_search
	    OR LOWER(cu.email) LIKE v_search
	    OR LOWER(r.description) LIKE v_search;
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT column_value)
	  INTO out_total_rows
	  FROM TABLE(v_filter_alert_sid_list);
	
	PageFilterAlertSids(v_filter_alert_sid_list, v_shared_sid, v_company_shared_sid, in_start_row, in_end_row, v_filter_alert_sid_page);
		
	OPEN out_alert_cur FOR
		SELECT sfa.saved_filter_sid, sf.name, NVL(p.path, sf.name) path, sfa.description, sfa.users_can_subscribe, sfa.customer_alert_type_id, 
			   CASE WHEN sfa.every_n_minutes IS NOT NULL THEN 1 ELSE 0 END is_hourly,
		       sfa.schedule_xml, sfa.next_fire_time, sfa.last_fire_time, sfa.alerts_sent_on_last_run
		  FROM saved_filter_alert sfa
		  JOIN saved_filter sf ON sfa.saved_filter_sid = sf.saved_filter_sid
		  JOIN TABLE(v_filter_alert_sid_page) fil_list ON sfa.saved_filter_sid = fil_list.sid_id
		  LEFT JOIN (
				SELECT so.sid_id, SYS_CONNECT_BY_PATH(so.name, ' / ') path
				  FROM security.securable_object so
				 WHERE class_id != security_pkg.SO_CONTAINER
				 START WITH so.parent_sid_id IN (v_shared_sid, v_company_shared_sid)
				CONNECT BY PRIOR so.sid_id = so.parent_sid_id
			) p ON sfa.saved_filter_sid = p.sid_id
		 ORDER BY fil_list.pos;
		  
	OPEN out_subscription_cur FOR
		SELECT sfas.saved_filter_sid, sfas.user_sid, cu.full_name user_full_name, cu.email, 
			   sfas.region_sid, r.description region_description, sfas.has_had_initial_set, 
			   CASE WHEN sfas.error_message IS NULL THEN 0 ELSE 1 END has_error_message,
			   cu.active is_active
		  FROM saved_filter_alert sfa
		  JOIN saved_filter_alert_subscriptn sfas ON sfa.saved_filter_sid = sfas.saved_filter_sid
		  JOIN TABLE(v_filter_alert_sid_page) fil_list ON sfa.saved_filter_sid = fil_list.sid_id
		  JOIN csr.v$csr_user cu ON sfas.user_sid = cu.csr_user_sid AND sfas.app_sid = cu.app_sid
		  LEFT JOIN csr.v$region r ON sfas.region_sid = r.region_sid AND sfas.app_sid = r.app_sid
		 ORDER BY LOWER(cu.full_name);	
END;

PROCEDURE GetFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	out_alert_cur					OUT SYS_REFCURSOR,
	out_subscription_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	CheckManageFilterAlertAccess(in_saved_filter_sid);
	
	OPEN out_alert_cur FOR
		SELECT sfa.saved_filter_sid, sf.name, sfa.description, sfa.users_can_subscribe, sfa.customer_alert_type_id, 
			   CASE WHEN sfa.every_n_minutes IS NOT NULL THEN 1 ELSE 0 END is_hourly,
		       sfa.schedule_xml, sfa.next_fire_time, sfa.last_fire_time, sfa.alerts_sent_on_last_run
		  FROM saved_filter_alert sfa
		  JOIN saved_filter sf ON sfa.saved_filter_sid = sf.saved_filter_sid
		 WHERE sfa.saved_filter_sid = in_saved_filter_sid
		 ORDER BY LOWER(sf.name);
		  
	OPEN out_subscription_cur FOR
		SELECT sfas.saved_filter_sid, sfas.user_sid, cu.full_name user_full_name, sfas.region_sid, r.description region_description,
		       sfas.has_had_initial_set, CASE WHEN sfas.error_message IS NULL THEN 0 ELSE 1 END has_error_message
		  FROM saved_filter_alert sfa
		  JOIN saved_filter_alert_subscriptn sfas ON sfa.saved_filter_sid = sfas.saved_filter_sid
		  JOIN csr.csr_user cu ON sfas.user_sid = cu.csr_user_sid AND sfas.app_sid = cu.app_sid
		  LEFT JOIN csr.v$region r ON sfas.region_sid = r.region_sid AND sfas.app_sid = r.app_sid
		 WHERE sfa.saved_filter_sid = in_saved_filter_sid
		 ORDER BY LOWER(cu.full_name);	
END;

PROCEDURE GetAlertParams (
	in_std_alert_type_id			IN	csr.customer_alert_type.std_alert_type_id%TYPE,
	in_customer_alert_type_id		IN	csr.customer_alert_type.customer_alert_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security as called by alert_pkg.GetTemplate
	-- Help_text is mandatory (i.e. not null) because of how it is translated
	OPEN out_cur FOR
		SELECT std_alert_type_id, field_name, description, help_text, repeats, display_pos
		  FROM csr.std_alert_type_param
		 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_FILTER_ALERT
		 UNION
		SELECT csr.csr_data_pkg.ALERT_FILTER_ALERT, field_name, description, description, 1, ROWNUM+7
		  FROM (
			SELECT sfap.field_name, sfap.description
			  FROM saved_filter sf
			  JOIN saved_filter_alert sfa ON sf.saved_filter_sid = sfa.saved_filter_sid
			  JOIN saved_filter_alert_param sfap ON sf.card_group_id = sfap.card_group_id
			 WHERE sfa.customer_alert_type_id = in_customer_alert_type_id
			 ORDER BY sfap.field_name
		  )
		 UNION
		SELECT csr.csr_data_pkg.ALERT_FILTER_ALERT, oracle_column, NVL(description, oracle_column), NVL(description, oracle_column), 1, pos+7
		  FROM (
			SELECT tc.oracle_column, tc.description, tc.pos
			  FROM saved_filter sf
			  JOIN saved_filter_alert sfa ON sf.saved_filter_sid = sfa.saved_filter_sid
			  JOIN cms.tab_column pk ON sf.cms_id_column_sid = pk.column_sid
			  JOIN cms.tab_column tc ON pk.tab_sid = tc.tab_sid
			 WHERE sfa.customer_alert_type_id = in_customer_alert_type_id
			 ORDER BY tc.pos
		  );
END;

PROCEDURE SaveFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_description					IN  saved_filter_alert.description%TYPE,
	in_customer_alert_type_id		IN  saved_filter_alert.customer_alert_type_id%TYPE,
	in_alert_frame_id				IN  csr.alert_template.alert_frame_id%TYPE,
	in_send_type					IN  csr.alert_template.send_type%TYPE,
	in_reply_to_name				IN  csr.alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN  csr.alert_template.reply_to_email%TYPE,
	in_users_can_subscribe			IN  saved_filter_alert.users_can_subscribe%TYPE,
	in_is_hourly					IN  NUMBER,
	in_schedule_xml					IN  saved_filter_alert.schedule_xml%TYPE,
	in_next_fire_time				IN  saved_filter_alert.next_fire_time%TYPE,
	out_customer_alert_type_id		OUT saved_filter_alert.customer_alert_type_id%TYPE
)
AS
	v_every_n_minutes				NUMBER;
	v_schedule_xml					saved_filter_alert.schedule_xml%TYPE := in_schedule_xml;
BEGIN
	CheckManageFilterAlertAccess(in_saved_filter_sid);
	
	IF in_is_hourly = 1 THEN
		v_every_n_minutes := 60;
		v_schedule_xml := NULL;
	END IF;

	IF in_customer_alert_type_id IS NULL THEN
		-- create one
		INSERT INTO csr.customer_alert_type (customer_alert_type_id, get_params_sp)
			 VALUES (csr.customer_alert_type_id_seq.nextval, 'chain.filter_pkg.GetAlertParams')
		  RETURNING customer_alert_type_id INTO out_customer_alert_type_id;
		  
		INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
			 VALUES (out_customer_alert_type_id, in_alert_frame_id, in_send_type, in_reply_to_name, in_reply_to_email);	
	ELSE
		UPDATE csr.alert_template
		   SET alert_frame_id = in_alert_frame_id,
		       send_type = in_send_type,
			   reply_to_name = in_reply_to_name,
			   reply_to_email = in_reply_to_email
		 WHERE customer_alert_type_id = in_customer_alert_type_id;
		 
		out_customer_alert_type_id := in_customer_alert_type_id;
	END IF;
	
	BEGIN
		INSERT INTO saved_filter_alert (saved_filter_sid, description, users_can_subscribe, customer_alert_type_id,
		                                every_n_minutes, schedule_xml, next_fire_time)
			 VALUES (in_saved_filter_sid, in_description, in_users_can_subscribe, out_customer_alert_type_id, 
			         v_every_n_minutes, v_schedule_xml, in_next_fire_time);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE saved_filter_alert
			   SET description = in_description,
			       users_can_subscribe = in_users_can_subscribe,
			       customer_alert_type_id = out_customer_alert_type_id,
				   every_n_minutes = v_every_n_minutes,
				   schedule_xml = v_schedule_xml,
				   next_fire_time = in_next_fire_time
			 WHERE saved_filter_sid = in_saved_filter_sid;
	END;
END;

PROCEDURE SaveFilterAlertBody (
	in_customer_alert_type_id		IN  csr.alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN  csr.alert_template_body.lang%TYPE,
	in_subject						IN  csr.alert_template_body.subject%TYPE,
	in_body_html					IN  csr.alert_template_body.body_html%TYPE,
	in_item_html					IN  csr.alert_template_body.item_html%TYPE
)
AS
BEGIN
	CheckManageFilterAlertAccess;
	
	BEGIN
		INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
				 VALUES (in_customer_alert_type_id, in_lang, in_subject, in_body_html, in_item_html);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.alert_template_body
			   SET subject = in_subject,
			       body_html = in_body_html,
				   item_html = in_item_html
			 WHERE customer_alert_type_id = in_customer_alert_type_id
			   AND lang = in_lang;
	END;
END;
 
PROCEDURE DeleteFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID
)
AS
	v_customer_alert_type_id		saved_filter_alert.customer_alert_type_id%TYPE;
BEGIN
	CheckManageFilterAlertAccess(in_saved_filter_sid);
	
	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM saved_filter_alert
	 WHERE saved_filter_sid = in_saved_filter_sid;
		
	DELETE FROM saved_filter_sent_alert
	      WHERE saved_filter_sid = in_saved_filter_sid;
		  
	DELETE FROM saved_filter_alert_subscriptn
	      WHERE saved_filter_sid = in_saved_filter_sid;
		  
	DELETE FROM saved_filter_alert
	      WHERE saved_filter_sid = in_saved_filter_sid;
	
	csr.alert_pkg.DeleteTemplate(v_customer_alert_type_id);
END;

PROCEDURE CreateFilterAlertSubscription (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_has_had_initial_set			IN  saved_filter_alert_subscriptn.has_had_initial_set%TYPE
)
AS
BEGIN
	CheckManageFilterAlertAccess(in_saved_filter_sid);
	
	BEGIN
		INSERT INTO saved_filter_alert_subscriptn (saved_filter_sid, user_sid, region_sid, has_had_initial_set)
			 VALUES (in_saved_filter_sid, in_user_sid, in_region_sid, in_has_had_initial_set);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; -- two people adding the same subscription at the same time
	END;
END;

PROCEDURE DeleteFilterAlertSubscription (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CheckManageFilterAlertAccess(in_saved_filter_sid);
	
	DELETE FROM saved_filter_alert_subscriptn
	      WHERE saved_filter_sid = in_saved_filter_sid
		    AND user_sid = in_user_sid
			AND DECODE(region_sid, in_region_sid, 1) = 1;	
END;

PROCEDURE CheckAlertSubscriptionAccess (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID
)
AS
	v_users_can_subscribe			saved_filter_alert.users_can_subscribe%TYPE;
BEGIN
	SELECT users_can_subscribe
	  INTO v_users_can_subscribe
	  FROM saved_filter_alert
	 WHERE saved_filter_sid = in_saved_filter_sid;
	 
	IF NOT (v_users_can_subscribe = 1 OR csr.csr_data_pkg.CheckCapability('Can manage filter alerts')) OR 
	   NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering alert subscription: '||in_saved_filter_sid);
	END IF;
END;

PROCEDURE UnsubscribeFromFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CheckAlertSubscriptionAccess(in_saved_filter_sid);
	
	DELETE FROM saved_filter_alert_subscriptn
	      WHERE saved_filter_sid = in_saved_filter_sid
		    AND user_sid = security_pkg.GetSid;	
END;

PROCEDURE SubscribeToFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS
)
AS
	v_region_sids_tbl				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_new_region_sids				security_pkg.T_SID_IDS;
BEGIN
	CheckAlertSubscriptionAccess(in_saved_filter_sid);
	
	SELECT r.column_value
	  BULK COLLECT INTO v_new_region_sids
	  FROM TABLE(v_region_sids_tbl) r
	  LEFT JOIN saved_filter_alert_subscriptn sfas ON r.column_value = sfas.region_sid
	   AND sfas.saved_filter_sid = in_saved_filter_sid
	   AND sfas.user_sid = security_pkg.GetSid
	 WHERE sfas.saved_filter_sid IS NULL;
	
	DELETE FROM saved_filter_alert_subscriptn
	      WHERE saved_filter_sid = in_saved_filter_sid
		    AND user_sid = security_pkg.GetSid
			AND (region_sid IS NULL 
			 OR region_sid NOT IN (
				SELECT column_value
				  FROM TABLE(v_region_sids_tbl)
			));
	
	IF CARDINALITY(v_region_sids_tbl) > 0 THEN
		INSERT INTO saved_filter_alert_subscriptn (saved_filter_sid, user_sid, region_sid)
			 SELECT in_saved_filter_sid, security_pkg.GetSid, column_value
			   FROM TABLE(v_region_sids_tbl) r
			  WHERE NOT EXISTS (
				SELECT *
				  FROM saved_filter_alert_subscriptn
				 WHERE saved_filter_sid = in_saved_filter_sid
				   AND user_sid = security_pkg.GetSid
				   AND region_sid = r.column_value
			  );
	ELSE
		INSERT INTO saved_filter_alert_subscriptn (saved_filter_sid, user_sid)
			 VALUES (in_saved_filter_sid, security_pkg.GetSid);
	END IF;
	
	IF in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL) OR v_new_region_sids.COUNT != 0 THEN
		SetupInitialSet(in_saved_filter_sid, v_new_region_sids);
	END IF;

	-- audit
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_FILTER,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_saved_filter_sid,
		in_description		=>	'Filter subscribed for user {0}', 
		in_param_1			=>	security_pkg.GetSid
	);
END;

PROCEDURE GetMyFilterAlerts (
	out_filter_alerts				OUT  SYS_REFCURSOR,
	out_filter_alert_regions		OUT  SYS_REFCURSOR
)
AS
	v_shared_sid					security_pkg.T_SID_ID := GetSharedParentSid(NULL);
	v_company_shared_sid			security_pkg.T_SID_ID;
	v_filter_sids					security.T_SO_DESCENDANTS_TABLE;
	v_chain_filter_sids				security.T_SO_DESCENDANTS_TABLE;
BEGIN
	
	v_filter_sids := SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_shared_sid, security_pkg.PERMISSION_READ);
	
	IF HasSavedFilters(FILTER_TYPE_COMPANIES) = 1 THEN
		v_company_shared_sid := GetSharedParentSid(FILTER_TYPE_COMPANIES);
		v_chain_filter_sids := SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
						v_company_shared_sid, security_pkg.PERMISSION_READ);
	END IF;
	
	OPEN out_filter_alerts FOR
		SELECT sfa.saved_filter_sid, sf.name, NVL(p.path, sf.name) path, sfa.description, 
			   CASE WHEN sfa.every_n_minutes IS NOT NULL THEN 1 ELSE 0 END is_hourly,
			   sfa.schedule_xml, NVL(sfas.subscribed, 0) subscribed, NVL(sfas.all_regions, 0) all_regions,
			   NVL(sfas.has_error_message, 0) has_error_message,
			   NVL(cu.active, 0) is_active
		  FROM saved_filter_alert sfa
		  JOIN saved_filter sf ON sfa.saved_filter_sid = sf.saved_filter_sid
		  JOIN (SELECT * FROM TABLE(v_filter_sids) UNION SELECT * FROM TABLE(v_chain_filter_sids)) so ON sfa.saved_filter_sid = so.sid_id
		  LEFT JOIN csr.v$csr_user cu ON cu.csr_user_sid = security_pkg.GetSid AND cu.app_sid = security_pkg.GetApp
		  LEFT JOIN (
			SELECT sfas.saved_filter_sid, CASE WHEN COUNT(sfas.user_sid) = 0 THEN 0 ELSE 1 END subscribed,
			       CASE WHEN COUNT(CASE WHEN sfas.region_sid IS NULL AND sfas.user_sid IS NOT NULL THEN 1 END) = 0 THEN 0 ELSE 1 END all_regions,
				   MAX(CASE WHEN sfas.error_message IS NULL THEN 0 ELSE 1 END) has_error_message
			  FROM saved_filter_alert_subscriptn sfas
			 WHERE sfas.user_sid = security_pkg.GetSid
			 GROUP BY saved_filter_sid
			) sfas ON sfa.saved_filter_sid = sfas.saved_filter_sid 	
		  LEFT JOIN (
				SELECT so.sid_id, SYS_CONNECT_BY_PATH(so.name, ' / ') path
				  FROM security.securable_object so
				 WHERE class_id != security_pkg.SO_CONTAINER
				 START WITH so.sid_id IN (v_shared_sid, v_company_shared_sid)
				CONNECT BY PRIOR so.sid_id = so.parent_sid_id
			) p ON sfa.saved_filter_sid = p.sid_id			
		 WHERE sfa.users_can_subscribe = 1
		 ORDER BY subscribed DESC, LOWER(NVL(p.path, sf.name));
		 
	OPEN out_filter_alert_regions FOR
		SELECT sfas.saved_filter_sid, sfas.region_sid, r.description
		  FROM saved_filter_alert sfa
		  JOIN (SELECT * FROM TABLE(v_filter_sids) UNION SELECT * FROM TABLE(v_chain_filter_sids)) so ON sfa.saved_filter_sid = so.sid_id
		  JOIN saved_filter_alert_subscriptn sfas ON sfa.saved_filter_sid = sfas.saved_filter_sid 
		   AND sfas.user_sid = security_pkg.GetSid
		  JOIN csr.v$region r ON sfas.region_sid = r.region_sid
		 WHERE sfa.users_can_subscribe = 1;
END;
/*
 * End of alert procedures
 */ 

PROCEDURE GetFilterPageCmsTables (
	in_card_group_id				IN  filter_page_cms_table.card_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
BEGIN
	-- security check handled in query
	
	OPEN out_cur FOR
		SELECT f.filter_page_cms_table_id, f.card_group_id, f.column_sid, NVL(tc.description, tc.oracle_column) column_description,
			   t.tab_sid, NVL(t.description, t.oracle_table) table_description
		  FROM filter_page_cms_table f
		  JOIN cms.tab_column tc ON f.app_sid = tc.app_sid AND f.column_sid = tc.column_sid
		  JOIN cms.tab t ON tc.app_sid = t.app_sid AND tc.tab_sid = t.tab_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSid(v_act_id, t.tab_sid, security_pkg.PERMISSION_READ) = 1
		   AND f.card_group_id = NVL(in_card_group_id, f.card_group_id)
		 ORDER BY f.card_group_id, t.description;
END;

PROCEDURE SaveFilterPageCmsTable (
	in_filter_page_cms_table_id		IN  filter_page_cms_table.filter_page_cms_table_id%TYPE,
	in_card_group_id				IN  filter_page_cms_table.card_group_id%TYPE,
	in_column_sid					IN  filter_page_cms_table.column_sid%TYPE,
	out_filter_page_cms_table_id	OUT filter_page_cms_table.filter_page_cms_table_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify filter CMS tables.');
	END IF;
	
	IF in_filter_page_cms_table_id IS NULL THEN
		INSERT INTO filter_page_cms_table (filter_page_cms_table_id, card_group_id, column_sid)
			 VALUES (filter_page_cms_table_id_seq.NEXTVAL, in_card_group_id, in_column_sid)
		  RETURNING filter_page_cms_table_id INTO out_filter_page_cms_table_id;
	ELSE
		out_filter_page_cms_table_id := in_filter_page_cms_table_id;
	END IF;
END;

PROCEDURE DeleteFilterPageCmsTable (
	in_filter_page_cms_table_id		IN  filter_page_cms_table.filter_page_cms_table_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify filter CMS tables.');
	END IF;
	
	DELETE FROM filter_page_cms_table
	      WHERE filter_page_cms_table_id = in_filter_page_cms_table_id;
END;

/*
 * Start of filter ind procedures
 */
PROCEDURE GetFilterPageInds (
	in_card_group_id				IN  filter_page_ind.card_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_intervals_cur				OUT SYS_REFCURSOR
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
BEGIN
	-- security check handled in query
	
	OPEN out_cur FOR
		SELECT f.filter_page_ind_id, f.card_group_id, f.ind_sid, f.period_set_id, f.period_interval_id, 
		       f.start_dtm, f.end_dtm, f.previous_n_intervals, i.description ind_description, i.measure_sid,
			   f.include_in_list, f.include_in_filter, f.include_in_aggregates, f.include_in_breakdown,
			   f.show_measure_in_description, f.show_interval_in_description, f.description_override
		  FROM filter_page_ind f
		  JOIN csr.v$ind i ON f.ind_sid = i.ind_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSid(v_act_id, f.ind_sid, security_pkg.PERMISSION_READ) = 1
		   AND f.card_group_id = NVL(in_card_group_id, f.card_group_id)
		 ORDER BY f.card_group_id, i.description;
		   
	OPEN out_intervals_cur FOR
		SELECT fi.filter_page_ind_interval_id, fi.filter_page_ind_id, fi.current_interval_offset, 
			   NVL(fi.start_dtm, csr.period_pkg.AddIntervals(f.period_set_id, f.period_interval_id, SYSDATE, fi.current_interval_offset)) start_dtm
		  FROM filter_page_ind_interval fi
		  JOIN filter_page_ind f ON fi.filter_page_ind_id = f.filter_page_ind_id
		  JOIN csr.v$ind i ON f.ind_sid = i.ind_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSid(v_act_id, f.ind_sid, security_pkg.PERMISSION_READ) = 1
		   AND f.card_group_id = NVL(in_card_group_id, f.card_group_id)
		 ORDER BY fi.filter_page_ind_id, start_dtm;
END;

PROCEDURE SaveFilterPageInd (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE,
	in_card_group_id				IN  filter_page_ind.card_group_id%TYPE,
	in_ind_sid						IN  filter_page_ind.ind_sid%TYPE,
	in_period_set_id				IN  filter_page_ind.period_set_id%TYPE,
	in_period_interval_id			IN  filter_page_ind.period_interval_id%TYPE,
	in_start_dtm					IN  filter_page_ind.start_dtm%TYPE,
	in_end_dtm						IN  filter_page_ind.end_dtm%TYPE,
	in_previous_n_intervals			IN  filter_page_ind.previous_n_intervals%TYPE,
	in_include_in_list				IN  filter_page_ind.include_in_list%TYPE,
	in_include_in_filter			IN  filter_page_ind.include_in_filter%TYPE,
	in_include_in_aggregates		IN  filter_page_ind.include_in_aggregates%TYPE,
	in_include_in_breakdown			IN  filter_page_ind.include_in_breakdown%TYPE,
	in_show_measure_in_description	IN  filter_page_ind.show_measure_in_description%TYPE,
	in_show_interval_in_descriptn	IN  filter_page_ind.show_interval_in_description%TYPE,
	in_description_override			IN  filter_page_ind.description_override%TYPE,
	out_filter_page_ind_id			OUT filter_page_ind.filter_page_ind_id%TYPE
)
AS
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify filter page inds.');
	END IF;
	
	IF in_filter_page_ind_id IS NULL THEN
		INSERT INTO filter_page_ind (filter_page_ind_id, card_group_id, ind_sid, period_set_id, 
					period_interval_id, start_dtm, end_dtm, previous_n_intervals, include_in_list,
					include_in_filter, include_in_aggregates, include_in_breakdown, 
					show_measure_in_description, show_interval_in_description, description_override)
			 VALUES (filter_page_ind_id_seq.NEXTVAL, in_card_group_id, in_ind_sid, in_period_set_id,
					in_period_interval_id, in_start_dtm, in_end_dtm, in_previous_n_intervals,
					in_include_in_list, in_include_in_filter, in_include_in_aggregates,
					in_include_in_breakdown, in_show_measure_in_description,
					in_show_interval_in_descriptn, in_description_override)
		  RETURNING filter_page_ind_id INTO out_filter_page_ind_id;
	ELSE
		UPDATE filter_page_ind
		   SET period_set_id = in_period_set_id,
		       period_interval_id = in_period_interval_id,
			   start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   previous_n_intervals = in_previous_n_intervals,
			   include_in_list = in_include_in_list,
			   include_in_filter = in_include_in_filter,
			   include_in_aggregates = in_include_in_aggregates,
			   include_in_breakdown = in_include_in_breakdown,
			   show_measure_in_description = in_show_measure_in_description,
			   show_interval_in_description = in_show_interval_in_descriptn,
			   description_override = in_description_override
		 WHERE filter_page_ind_id = in_filter_page_ind_id;
		
		out_filter_page_ind_id := in_filter_page_ind_id;
	END IF;
	
	GenerateFilterPageIndIntervals(out_filter_page_ind_id);
END;

PROCEDURE DeleteFilterPageInd (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify filter page inds.');
	END IF;
	
	DELETE FROM filter_page_ind_interval
	      WHERE filter_page_ind_id = in_filter_page_ind_id;
		  
	DELETE FROM filter_page_ind
	      WHERE filter_page_ind_id = in_filter_page_ind_id;
END;

PROCEDURE GenerateFilterPageIndIntervals (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE
)
AS
	v_filter_page_ind_interval_id	filter_page_ind_interval.filter_page_ind_interval_id%TYPE;	
	v_period_set_id					filter_page_ind.period_set_id%TYPE;	
	v_period_interval_id			filter_page_ind.period_interval_id%TYPE;
	v_start_dtm						filter_page_ind.start_dtm%TYPE;
	v_end_dtm						filter_page_ind.end_dtm%TYPE;
	v_previous_n_intervals			filter_page_ind.previous_n_intervals%TYPE;
	v_card_group_id					filter_page_ind.card_group_id%TYPE;
	v_period_number					NUMBER;
	v_period_date					DATE;
	v_interval_number				NUMBER;
	v_interval_offset				NUMBER;
	v_ids_to_keep					security.T_SID_TABLE := security.T_SID_TABLE();
	v_customer_aggregate_type_id	NUMBER;
	v_include_in_aggregates			NUMBER;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify filter page inds.');
	END IF;

	SELECT fpi.period_set_id, fpi.period_interval_id, fpi.start_dtm, fpi.end_dtm, fpi.previous_n_intervals, 
	       fpi.card_group_id, CASE WHEN fpi.include_in_aggregates = 1 AND m.custom_field IS NULL THEN 1 ELSE 0 END 
	  INTO v_period_set_id, v_period_interval_id, v_start_dtm, v_end_dtm, v_previous_n_intervals, 
	       v_card_group_id, v_include_in_aggregates
	  FROM filter_page_ind fpi
	  JOIN csr.ind i ON fpi.app_sid = i.app_sid AND fpi.ind_sid = i.ind_sid
	  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid
	 WHERE filter_page_ind_id = in_filter_page_ind_id;

	IF v_start_dtm IS NOT NULL AND v_end_dtm IS NOT NULL THEN
		v_period_number := csr.period_pkg.GetPeriodNumber(v_period_set_id, v_start_dtm);
		v_period_date := csr.period_pkg.GetPeriodDate(v_period_set_id, v_period_number);
		
		BEGIN
			INSERT INTO filter_page_ind_interval (filter_page_ind_interval_id, filter_page_ind_id, start_dtm)
			     VALUES (filter_page_ind_intrval_id_seq.NEXTVAL, in_filter_page_ind_id, v_period_date)
			  RETURNING filter_page_ind_interval_id INTO v_filter_page_ind_interval_id;
		EXCEPTION
			WHEN dup_val_on_index THEN
				SELECT filter_page_ind_interval_id
				  INTO v_filter_page_ind_interval_id
				  FROM filter_page_ind_interval
				 WHERE filter_page_ind_id = in_filter_page_ind_id
				   AND start_dtm = v_period_date;
		END;
		
		IF v_include_in_aggregates = 1 THEN
			v_customer_aggregate_type_id := UNSEC_AddCustomerAggregateType(
				in_card_group_id				=> v_card_group_id,
				in_filter_page_ind_interval_id	=> v_filter_page_ind_interval_id
			);
		END IF;
		
		v_ids_to_keep.extend;
		v_ids_to_keep(v_ids_to_keep.COUNT) := v_filter_page_ind_interval_id;
		
		v_period_date := csr.period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_period_date, 1);
		WHILE v_period_date < v_end_dtm LOOP
			BEGIN
				INSERT INTO filter_page_ind_interval (filter_page_ind_interval_id, filter_page_ind_id, start_dtm)
					 VALUES (filter_page_ind_intrval_id_seq.NEXTVAL, in_filter_page_ind_id, v_period_date)
				  RETURNING filter_page_ind_interval_id INTO v_filter_page_ind_interval_id;
			EXCEPTION
				WHEN dup_val_on_index THEN
					SELECT filter_page_ind_interval_id
					  INTO v_filter_page_ind_interval_id
					  FROM filter_page_ind_interval
					 WHERE filter_page_ind_id = in_filter_page_ind_id
					   AND start_dtm = v_period_date;
			END;
			
			IF v_include_in_aggregates = 1 THEN
				v_customer_aggregate_type_id := UNSEC_AddCustomerAggregateType(
					in_card_group_id				=> v_card_group_id,
					in_filter_page_ind_interval_id	=> v_filter_page_ind_interval_id
				);
			END IF;
		
			v_ids_to_keep.extend;
			v_ids_to_keep(v_ids_to_keep.COUNT) := v_filter_page_ind_interval_id;
		
			v_period_date := csr.period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_period_date, 1);
		END LOOP;
		
	ELSIF v_previous_n_intervals IS NOT NULL AND v_previous_n_intervals > 0 THEN
		v_interval_offset := 0;
		WHILE v_interval_offset > (v_previous_n_intervals * -1) LOOP
			BEGIN
				INSERT INTO filter_page_ind_interval (filter_page_ind_interval_id, filter_page_ind_id, current_interval_offset)
					 VALUES (filter_page_ind_intrval_id_seq.NEXTVAL, in_filter_page_ind_id, v_interval_offset)
				  RETURNING filter_page_ind_interval_id INTO v_filter_page_ind_interval_id;
			EXCEPTION
				WHEN dup_val_on_index THEN
					SELECT filter_page_ind_interval_id
					  INTO v_filter_page_ind_interval_id
					  FROM filter_page_ind_interval
					 WHERE filter_page_ind_id = in_filter_page_ind_id
					   AND current_interval_offset = v_interval_offset;
			END;
				  
			IF v_include_in_aggregates = 1 THEN
				v_customer_aggregate_type_id := UNSEC_AddCustomerAggregateType(
					in_card_group_id				=> v_card_group_id,
					in_filter_page_ind_interval_id	=> v_filter_page_ind_interval_id
				);
			END IF;
		
			v_ids_to_keep.extend;
			v_ids_to_keep(v_ids_to_keep.COUNT) := v_filter_page_ind_interval_id;
		
			v_interval_offset := v_interval_offset -1;
		END LOOP;
	END IF;
	
	-- if its not a numerical/filterable or its an interval thats about to be removed, then
	-- remove the custom aggregate type
	FOR r IN (
		SELECT cuat.customer_aggregate_type_id
		  FROM customer_aggregate_type cuat
		  JOIN filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id		  
		 WHERE cuat.card_group_id = v_card_group_id
		   AND fpi.filter_page_ind_id = in_filter_page_ind_id
		   AND cuat.filter_page_ind_interval_id NOT IN (
			SELECT filter_page_ind_interval_id
			  FROM filter_page_ind_interval fpii
			  JOIN filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
			  JOIN csr.ind i ON fpi.app_sid = i.app_sid AND fpi.ind_sid = i.ind_sid
			  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid
			 WHERE m.custom_field IS NULL --numbers only
			   AND fpi.include_in_aggregates = 1
			   AND fpi.filter_page_ind_id = in_filter_page_ind_id
			   AND fpii.filter_page_ind_interval_id IN (
					SELECT column_value
					  FROM TABLE(v_ids_to_keep)
			   )
			)
	) LOOP
		UNSEC_RemoveCustomerAggType(r.customer_aggregate_type_id);
	END LOOP;
	
	DELETE FROM filter_page_ind_interval
	      WHERE app_sid = security_pkg.GetApp
		    AND filter_page_ind_id = in_filter_page_ind_id
	        AND filter_page_ind_interval_id NOT IN (
				SELECT column_value
				  FROM TABLE(v_ids_to_keep)
			);
END;

PROCEDURE EmptyTempFilterIndVal
AS
BEGIN
	-- no security, just emptying temp table
	DELETE FROM tt_filter_ind_val;
END;
 
PROCEDURE AddTempFilterIndVal (
	in_filter_page_ind_interval_id	IN  tt_filter_ind_val.filter_page_ind_interval_id%TYPE,
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_ind_sid						IN  security_pkg.T_SID_ID,
	in_period_start_dtm				IN  tt_filter_ind_val.period_start_dtm%TYPE,
	in_period_end_dtm				IN  tt_filter_ind_val.period_end_dtm%TYPE,
	in_val_number					IN  tt_filter_ind_val.val_number%TYPE,
	in_error_code					IN  tt_filter_ind_val.error_code%TYPE,
	in_note							IN  tt_filter_ind_val.note%TYPE
)
AS
BEGIN
	-- no security, just inserting into temp table
	INSERT INTO tt_filter_ind_val (filter_page_ind_interval_id, region_sid, ind_sid, 
				period_start_dtm, period_end_dtm, val_number, error_code, note)
		 VALUES (in_filter_page_ind_interval_id, in_region_sid, in_ind_sid, 
				in_period_start_dtm, in_period_end_dtm, in_val_number, in_error_code, in_note);
END;

PROCEDURE FilterIndNumber (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_filter_page_ind_interval_id	NUMBER;
BEGIN
	-- no security checks required, just filtering a list of ids the user has access to
	
	v_filter_page_ind_interval_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description, filter_type)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, filter_pkg.NUMBER_EQUAL, ti.val_number, ti.val_number, FILTER_VALUE_TYPE_NUMBER_RANGE
		  FROM (
			  SELECT DISTINCT ti.val_number
				FROM tt_filter_ind_val ti
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
			   WHERE ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id
		) ti -- numbers
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND num_value = filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = ti.val_number
		 );
	END IF;
	
	SortNumberValues(in_filter_field_id);	
	
	SELECT T_FILTERED_OBJECT_ROW(p.region_sid, p.group_by_index, p.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT ti.region_sid, fv.group_by_index, fv.filter_value_id
		  FROM tt_filter_ind_val ti
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
		  CROSS JOIN v$filter_value fv
		 WHERE fv.filter_id = in_filter_id 
		   AND fv.filter_field_id = in_filter_field_id
		   AND ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id
		   AND filter_pkg.CheckNumberRange(ti.val_number, fv.num_value, fv.min_num_val, fv.max_num_val) = 1
		) p;
END;

PROCEDURE FilterIndText (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_filter_page_ind_interval_id	NUMBER;
BEGIN
	-- no security checks required, just filtering a list of ids the user has access to

	v_filter_page_ind_interval_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	SELECT T_FILTERED_OBJECT_ROW(ti.region_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM tt_filter_ind_val ti
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
	  JOIN v$filter_value fv ON LOWER(ti.note) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id
	   AND ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id;
END;

PROCEDURE FilterIndDate (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
	v_filter_page_ind_interval_id	NUMBER;
BEGIN
	-- no security checks required, just filtering a list of ids the user has access to
	
	v_filter_page_ind_interval_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val_number is stored as days since 1900 (JS one day behind).
		SELECT MIN(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val_number), MAX(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val_number)
		  INTO v_min_date, v_max_date
		  FROM tt_filter_ind_val ti
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
		 WHERE ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id;
		
		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT T_FILTERED_OBJECT_ROW(ti.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM tt_filter_ind_val ti
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
	  JOIN tt_filter_date_range dr 
		ON TO_DATE('30-12-1899', 'DD-MM-YYYY') + ti.val_number >= NVL(dr.start_dtm, TO_DATE('30-12-1899', 'DD-MM-YYYY') + ti.val_number)
	   AND (dr.end_dtm IS NULL OR TO_DATE('30-12-1899', 'DD-MM-YYYY') + ti.val_number < dr.end_dtm)
	 WHERE ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id
	   AND TO_DATE('30-12-1899', 'DD-MM-YYYY') + ti.val_number IS NOT NULL;
END;

PROCEDURE FilterIndCombo (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name 			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_filter_page_ind_interval_id	NUMBER;
	v_custom_field					csr.measure.custom_field%TYPE;
	t_custom_field					csr.T_SPLIT_TABLE;
BEGIN
	-- no security checks required, just filtering a list of ids the user has access to
	
	v_filter_page_ind_interval_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		SELECT custom_field
		INTO v_custom_field
		  FROM filter_page_ind fpi
		  JOIN filter_page_ind_interval fpii ON fpi.filter_page_ind_id = fpii.filter_page_ind_id
		  JOIN csr.ind i ON fpi.ind_sid = i.ind_sid
		  JOIN csr.measure m on i.measure_sid = m.measure_sid
		 WHERE fpii.filter_page_ind_interval_id = v_filter_page_ind_interval_id;
		
		-- If checkbox insert Yes/No as we're displaying it as a combo instead.
		IF v_custom_field = 'x' THEN
			INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description, filter_type)
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, o.value, o.description, FILTER_VALUE_TYPE_NUMBER
			  FROM (
				SELECT 1 value, 'Yes' description FROM dual
				UNION ALL SELECT 0, 'No' FROM dual
			  ) o
			 WHERE NOT EXISTS (
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = o.value
			 );
		ELSE
			t_custom_field := csr.utils_pkg.SplitString(v_custom_field, CHR(13)||CHR(10));
			
			FOR r IN (
				SELECT t.item, t.pos
				  FROM TABLE(t_custom_field) t
				 WHERE NOT EXISTS (
					 SELECT *
					  FROM filter_value fv
					 WHERE fv.filter_field_id = in_filter_field_id
					   AND fv.num_value = t.pos
				)
			)
			LOOP
				INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description, filter_type)
				VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, r.pos, r.item, FILTER_VALUE_TYPE_NUMBER);
			END LOOP;
		END IF;
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(ti.region_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM tt_filter_ind_val ti
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ti.region_sid = t.object_id
	  JOIN v$filter_value fv ON ti.val_number = fv.num_value
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id
	   AND ti.filter_page_ind_interval_id = v_filter_page_ind_interval_id;
END;

PROCEDURE FilterInd (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- no security checks required, just filtering a list of ids the user has access to

	IF in_filter_field_name LIKE 'FilterPageIndIntervalNumber.%' THEN
		FilterIndNumber(in_filter_id, in_filter_field_id, in_filter_field_name, in_show_all, in_ids, out_ids);
	ELSIF in_filter_field_name LIKE 'FilterPageIndIntervalText.%' THEN
		FilterIndText(in_filter_id, in_filter_field_id, in_filter_field_name, in_show_all, in_ids, out_ids);
	ELSIF in_filter_field_name LIKE 'FilterPageIndIntervalDate.%' THEN
		FilterIndDate(in_filter_id, in_filter_field_id, in_filter_field_name, in_show_all, in_ids, out_ids);
	ELSIF in_filter_field_name LIKE 'FilterPageIndIntervalCombo.%' THEN
		FilterIndCombo(in_filter_id, in_filter_field_id, in_filter_field_name, in_show_all, in_ids, out_ids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_filter_field_name);
	END IF;
END;
 
/*
 * End of filter ind procedures
 */

/*
 * Caching procedures
 */

FUNCTION GetFilterCacheTimeout
RETURN NUMBER
AS
	v_timeout		customer_options.filter_cache_timeout%TYPE;
BEGIN
	SELECT filter_cache_timeout
	  INTO v_timeout
	  FROM chain.customer_options;
	
	RETURN v_timeout;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 600; -- 10 minutes
END;

PROCEDURE GetFilteredObjectsFromCache (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE,
	out_filtered_objects			OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						NUMBER;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	v_log_id := StartDebugLog('chain.filter_pkg.GetFilteredObjectsFromCache', in_card_group_id);
	BEGIN
		SELECT t2.column_value
		  INTO out_filtered_objects
		  FROM filter_cache t, TABLE(t.cached_rows) t2
		 WHERE app_sid = v_app_sid
		   AND user_sid = v_user_sid
		   AND card_group_id = in_card_group_id
		   AND (cms_col_sid = in_cms_col_sid OR (cms_col_sid IS NULL AND in_cms_col_sid IS NULL))
		   AND expire_dtm > SYSDATE
		   AND act_id = v_act;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_filtered_objects := NULL;
	END;
	EndDebugLog(v_log_id);
	
	COMMIT;
END;

PROCEDURE SetFilteredObjectsInCache (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE,
	in_filtered_objects				IN 	T_FILTERED_OBJECT_TABLE
)
AS
	v_timeout						number := GetFilterCacheTimeout/24/60/60; -- timeout, convert seconds to days
	v_log_id						NUMBER;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_array							T_FILTER_CACHE_VARRAY := T_FILTER_CACHE_VARRAY();
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	v_log_id := StartDebugLog('chain.filter_pkg.SetFilteredObjectsInCache', in_card_group_id);
	
	-- This conversion can be slow if in_filtered_objects is very large, we could add a separate
	-- log timer, but only if it starts to have an impact
	v_array.extend;
	v_array(1) := in_filtered_objects;
	
	BEGIN
		INSERT INTO filter_cache(card_group_id, cms_col_sid, expire_dtm, cached_rows)
		VALUES (in_card_group_id, in_cms_col_sid, SYSDATE+v_timeout, v_array);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE filter_cache
			   SET cached_rows = v_array,
				   expire_dtm = SYSDATE + v_timeout,
				   act_id = SYS_CONTEXT('SECURITY','ACT')
			 WHERE app_sid = v_app_sid
			   AND user_sid = v_user_sid
			   AND card_group_id = in_card_group_id
			   AND act_id = v_act
			   AND (cms_col_sid = in_cms_col_sid OR (cms_col_sid IS NULL AND in_cms_col_sid IS NULL));
	END;
	
	EndDebugLog(v_log_id);
	COMMIT;
END;

PROCEDURE ClearCacheForAllUsers (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE DEFAULT NULL,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE DEFAULT NULL
)
AS
	v_log_id						NUMBER;
	v_col_tab						security.T_SID_TABLE;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	v_log_id := StartDebugLog('chain.filter_pkg.ClearCacheForAllUsers', in_card_group_id);
	
	DELETE FROM filter_cache
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = NVL(in_card_group_id, card_group_id)
	   AND (in_cms_col_sid IS NULL OR cms_col_sid = in_cms_col_sid);
	
	IF in_cms_col_sid IS NOT NULL THEN
		v_col_tab := cms.filter_pkg.GetFilterCascadeSids(in_cms_col_sid);
		
		DELETE FROM filter_cache
		 WHERE app_sid = security_pkg.GetApp
		   AND cms_col_sid IN (
				SELECT column_value FROM TABLE(v_col_tab) WHERE column_value IS NOT NULL
			);
	END IF;
	
	EndDebugLog(v_log_id);
	
	COMMIT;
END;

PROCEDURE ClearCacheForUser (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE DEFAULT NULL,
	in_user_sid						IN	filter_cache.user_sid%TYPE
)
AS
	v_log_id						NUMBER;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	v_log_id := StartDebugLog('chain.filter_pkg.ClearCacheForUser', in_user_sid);
	
	DELETE FROM filter_cache
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid
	   AND NVL(in_card_group_id, card_group_id) = card_group_id;
	
	EndDebugLog(v_log_id);
	
	COMMIT;
END;

PROCEDURE RemoveExpiredCaches
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	DELETE FROM filter_cache
	 WHERE expire_dtm < SYSDATE;
	
	COMMIT;
END;

/*
 * End of Caching procedures
 */

PROCEDURE GetGridExtensions (
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security required
	OPEN out_cur FOR
		SELECT grid_extension_id, 
			   base_card_group_id, 
			   base_card_group_name, 
			   extension_card_group_id, 
			   extension_card_group_name, 
			   name
		  FROM v$grid_extension;
END;

PROCEDURE GetCustomerGridExtensions (
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security required
	OPEN out_cur FOR
		SELECT grid_extension_id,
			   enabled
		  FROM customer_grid_extension
		 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE SaveCustomerGridExtension (
	in_grid_extension_id		IN customer_grid_extension.grid_extension_id%TYPE,
	in_enabled					IN customer_grid_extension.enabled%TYPE,
	out_grid_extension_id		OUT	customer_grid_extension.grid_extension_id%TYPE
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 AND NOT security.security_pkg.IsAdmin(security.security_pkg.getact) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure grid extensions');
	END IF;
	
	BEGIN
		INSERT INTO customer_grid_extension (grid_extension_id, enabled)
		VALUES (in_grid_extension_id, in_enabled);
	EXCEPTION
		WHEN dup_val_on_index THEN
		UPDATE customer_grid_extension
		   SET enabled = in_enabled
		 WHERE grid_extension_id = in_grid_extension_id;
	END;
	
	out_grid_extension_id := in_grid_extension_id;

END;

PROCEDURE GetEnabledGridExtensions (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security required
	OPEN out_cur FOR
		SELECT extension_card_group_id, 
			   record_name
		  FROM grid_extension ge
		  JOIN customer_grid_extension cge ON cge.grid_extension_id = ge.grid_extension_id
		 WHERE cge.app_sid = security_pkg.GetApp
		   AND base_card_group_id = in_card_group_id
		   AND cge.enabled = 1;
END;

PROCEDURE SortExtension(
	in_base_grid				IN  VARCHAR2,
	in_id_list					IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row				IN	NUMBER,
	in_end_row					IN	NUMBER,
	in_order_by 				IN	VARCHAR2,
	in_order_dir				IN	VARCHAR2,
	out_id_list					OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_tilde_pos					NUMBER;
	v_record					VARCHAR2(255);
	v_field						VARCHAR2(255);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	-- No security required
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.filter_pkg.SortExtension');

	v_tilde_pos := INSTR(in_order_by, '~', 1);
	v_record := SUBSTR(in_order_by, 1, v_tilde_pos - 1);
	v_field := SUBSTR(in_order_by, v_tilde_pos + 1);

	CASE LOWER(in_base_grid)
		WHEN 'audit' THEN 
			CASE LOWER(v_record)
				WHEN 'company' THEN
					chain.company_filter_pkg.SortAuditSids(
						in_id_list				=> in_id_list,
						in_start_row			=> in_start_row,
						in_end_row				=> in_end_row,
						in_order_by 			=> v_field,
						in_order_dir			=> in_order_dir,
						out_id_list				=> out_id_list);
			END CASE;
		WHEN 'noncompliance' THEN 
			CASE LOWER(v_record)
				WHEN 'audit' THEN
					csr.audit_report_pkg.SortNonCompIds(
						in_id_list				=> in_id_list,
						in_start_row			=> in_start_row,
						in_end_row				=> in_end_row,
						in_order_by 			=> v_field,
						in_order_dir			=> in_order_dir,
						out_id_list				=> out_id_list);
				WHEN 'company' THEN
					chain.company_filter_pkg.SortNonCompIds(
						in_id_list				=> in_id_list,
						in_start_row			=> in_start_row,
						in_end_row				=> in_end_row,
						in_order_by 			=> v_field,
						in_order_dir			=> in_order_dir,
						out_id_list				=> out_id_list);
			END CASE;
		WHEN 'activity' THEN 
			CASE LOWER(v_record)
				WHEN 'company' THEN
					chain.company_filter_pkg.SortActivityIds(
						in_id_list				=> in_id_list,
						in_start_row			=> in_start_row,
						in_end_row				=> in_end_row,
						in_order_by 			=> v_field,
						in_order_dir			=> in_order_dir,
						out_id_list				=> out_id_list);
			END CASE;
		WHEN 'survey_response' THEN 
			CASE LOWER(v_record)
				WHEN 'company' THEN
					chain.company_filter_pkg.SortSurveyResponseIds(
						in_id_list				=> in_id_list,
						in_start_row			=> in_start_row,
						in_end_row				=> in_end_row,
						in_order_by 			=> v_field,
						in_order_dir			=> in_order_dir,
						out_id_list				=> out_id_list);
			END CASE;
	END CASE;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE InvertFilterSet(
	in_starting_sids 		IN  T_FILTERED_OBJECT_TABLE,
	in_result_sids   		IN  T_FILTERED_OBJECT_TABLE,
	out_inverse_result_sids	OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- Used by the NOT EQUALS filtering code to effectively invert application of the filtered results
	SELECT T_FILTERED_OBJECT_ROW(object_id, group_by_index, group_by_value)
	  BULK COLLECT INTO out_inverse_result_sids
	  FROM TABLE(in_starting_sids) 
	 WHERE object_id NOT IN (
	 	SELECT r.object_id
		  FROM TABLE(in_result_sids) r
	 );
END;

PROCEDURE SaveCustomerFilterColumn(
	in_card_group_id	IN	customer_filter_column.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_column.session_prefix%TYPE,
	in_column_name		IN	customer_filter_column.column_name%TYPE,
	in_label			IN	customer_filter_column.label%TYPE,
	in_width			IN	customer_filter_column.width%TYPE,
	in_fixed_width		IN	customer_filter_column.fixed_width%TYPE,
	in_sortable			IN	customer_filter_column.sortable%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND NOT csr.csr_data_pkg.CheckCapability('Quick chart management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with quick chart management capability can manage customer filter columns');
	END IF;

	BEGIN
		INSERT INTO customer_filter_column (
			customer_filter_column_id,
			card_group_id, column_name, session_prefix,
			label, width, fixed_width, sortable
		) VALUES (
			customer_filter_column_id_seq.NEXTVAL,
			in_card_group_id, in_column_name, in_session_prefix,
			in_label, in_width, in_fixed_width, in_sortable
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE customer_filter_column
			   SET label = in_label,
				   width = in_width,
				   fixed_width = in_fixed_width,
				   sortable = in_sortable
			 WHERE card_group_id = in_card_group_id
			   AND column_name = in_column_name
			   AND (session_prefix = in_session_prefix OR 
					(session_prefix IS NULL AND in_session_prefix IS NULL));
	END;

	OPEN out_cur FOR
		SELECT customer_filter_column_id,
			   card_group_id, column_name, session_prefix,
			   label, width, fixed_width, sortable
		  FROM customer_filter_column
		 WHERE card_group_id = in_card_group_id
		   AND column_name = in_column_name
		   AND (session_prefix = in_session_prefix OR 
				(session_prefix IS NULL AND in_session_prefix IS NULL));
END;

PROCEDURE GetCustomerFilterColumns(
	in_card_group_id	IN	customer_filter_column.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_column.session_prefix%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security needed
	OPEN out_cur FOR
		SELECT customer_filter_column_id,
			   card_group_id, column_name, session_prefix,
			   label, width, fixed_width, sortable
		  FROM (
				SELECT customer_filter_column_id,
					   card_group_id, column_name, session_prefix,
					   label, width, fixed_width, sortable
				  FROM customer_filter_column
				 WHERE card_group_id = in_card_group_id
				   AND session_prefix IS NULL
				   AND column_name NOT IN (
						SELECT column_name
						  FROM customer_filter_column
						 WHERE card_group_id = in_card_group_id
						   AND session_prefix = in_session_prefix
				   )
				 UNION
				SELECT customer_filter_column_id,
					   card_group_id, column_name, session_prefix,
					   label, width, fixed_width, sortable
				  FROM customer_filter_column
				 WHERE card_group_id = in_card_group_id
				   AND session_prefix  = in_session_prefix
		  )
	  ORDER BY column_name;
END;

PROCEDURE SaveCustomerFilterItem(
	in_card_group_id	IN	customer_filter_item.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_item.session_prefix%TYPE,
	in_item_name		IN	customer_filter_item.item_name%TYPE,
	in_label			IN	customer_filter_item.label%TYPE,
	in_can_breakdown	IN	customer_filter_item.can_breakdown%TYPE,
	in_analytic_fns		IN  security.security_pkg.T_SID_IDS,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR,
	out_agg_types_cur	OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_cust_filt_item_id		customer_filter_item.customer_filter_item_id%TYPE;
	v_cf_item_agg_typ_id	customer_filter_item.customer_filter_item_id%TYPE;
	v_cust_agg_typ_id		customer_filter_item.customer_filter_item_id%TYPE;
	v_analytic_fns			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_analytic_fns);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND NOT csr.csr_data_pkg.CheckCapability('Quick chart management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with quick chart management capability can manage customer filter items');
	END IF;

	BEGIN
		INSERT INTO customer_filter_item (
			customer_filter_item_id,
			card_group_id, item_name, session_prefix,
			label, can_breakdown
		) VALUES (
			customer_filter_item_id_seq.NEXTVAL,
			in_card_group_id, in_item_name, in_session_prefix,
			in_label, in_can_breakdown
		) RETURNING customer_filter_item_id INTO v_cust_filt_item_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			SELECT customer_filter_item_id
			  INTO v_cust_filt_item_id
			  FROM customer_filter_item
			 WHERE card_group_id = in_card_group_id
			   AND item_name = in_item_name
			   AND (session_prefix = in_session_prefix OR 
					(session_prefix IS NULL AND in_session_prefix IS NULL));

			UPDATE customer_filter_item
			   SET label = in_label,
				   can_breakdown = in_can_breakdown
			 WHERE customer_filter_item_id = v_cust_filt_item_id;
	END;

	-- We only insert here, never delete, in case the agg types are in use.
	FOR r IN (SELECT column_value analytic_function FROM TABLE(v_analytic_fns) WHERE column_value is not NULL) LOOP
		BEGIN
			INSERT INTO cust_filt_item_agg_type (
				customer_filter_item_id, cust_filt_item_agg_type_id, analytic_function
			) VALUES (
				v_cust_filt_item_id, cust_filt_item_agg_type_id_seq.NEXTVAL, r.analytic_function
			) RETURNING cust_filt_item_agg_type_id INTO v_cf_item_agg_typ_id;

			v_cust_agg_typ_id := UNSEC_AddCustomerAggregateType(
				in_card_group_id => in_card_group_id,
				in_cust_filt_item_agg_type_id => v_cf_item_agg_typ_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;

	OPEN out_cur FOR
		SELECT customer_filter_item_id,
			   card_group_id, item_name, session_prefix,
			   label, can_breakdown
		  FROM customer_filter_item
		 WHERE customer_filter_item_id = v_cust_filt_item_id;

	OPEN out_agg_types_cur FOR
		SELECT cfiat.customer_filter_item_id, cat.customer_aggregate_type_id,
			   cfiat.cust_filt_item_agg_type_id, cfiat.analytic_function
		  FROM cust_filt_item_agg_type cfiat
		  JOIN customer_aggregate_type cat ON cat.cust_filt_item_agg_type_id = cfiat.cust_filt_item_agg_type_id
		 WHERE customer_filter_item_id = v_cust_filt_item_id;
END;

PROCEDURE GetCustomerFilterItems(
	in_card_group_id		IN	customer_filter_item.card_group_id%TYPE,
	in_session_prefix		IN	customer_filter_item.session_prefix%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR,
	out_agg_types_cur		OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_cust_filt_item_ids	security.T_SID_TABLE;
BEGIN
	SELECT customer_filter_item_id
	  BULK COLLECT INTO v_cust_filt_item_ids
	  FROM (
			SELECT customer_filter_item_id
			  FROM customer_filter_item
			 WHERE card_group_id = in_card_group_id
			   AND session_prefix IS NULL
			   AND item_name NOT IN (
					SELECT item_name
					  FROM customer_filter_item
					 WHERE card_group_id = in_card_group_id
					   AND session_prefix = in_session_prefix
			   )
			 UNION
			SELECT customer_filter_item_id
			  FROM customer_filter_item
			 WHERE card_group_id = in_card_group_id
			   AND session_prefix  = in_session_prefix
	  );

	-- no security needed
	OPEN out_cur FOR
		SELECT customer_filter_item_id,
			   card_group_id, item_name, session_prefix,
			   label, can_breakdown
		  FROM customer_filter_item
		  JOIN TABLE(v_cust_filt_item_ids) t ON t.column_value = customer_filter_item_id;

	OPEN out_agg_types_cur FOR
		SELECT cfiat.customer_filter_item_id, cat.customer_aggregate_type_id,
			   cfiat.cust_filt_item_agg_type_id, cfiat.analytic_function
		  FROM cust_filt_item_agg_type cfiat
		  JOIN customer_aggregate_type cat ON cat.cust_filt_item_agg_type_id = cfiat.cust_filt_item_agg_type_id
		  JOIN TABLE(v_cust_filt_item_ids) t ON t.column_value = cfiat.customer_filter_item_id;
END;

END filter_pkg;
/