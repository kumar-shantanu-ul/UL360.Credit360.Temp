CREATE OR REPLACE PACKAGE BODY CSR.Dataview_Pkg AS

-- Securable object callbacks
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
) AS
BEGIN
	UPDATE DATAVIEW SET name=in_new_name WHERE dataview_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE attachment
	   SET dataview_sid = NULL
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_zone
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM attachment_history
	 WHERE attachment_id IN (
			SELECT attachment_id
			  FROM attachment
			 WHERE dataview_sid = in_sid_id);

	DELETE FROM attachment
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_ind_description
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_ind_member
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM tpl_report_tag_dv_region
	 WHERE dataview_sid = in_sid_id;

	-- Don't just delete it, we want it to remain in the template for remapping.
	UPDATE tpl_report_tag
	   SET tag_type = -1, tpl_report_tag_dataview_id = NULL
	 WHERE tpl_report_tag_dataview_id IN (
		SELECT tpl_report_tag_dataview_id FROM tpl_report_tag_dataview
		 WHERE dataview_sid = in_sid_id);

	DELETE FROM tpl_report_tag_dataview
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_region_description
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_region_member
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_scenario_run
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM excel_export_options_tag_group
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM excel_export_options
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_trend
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_arbitrary_period 
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_arbitrary_period_hist
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_history 
	 WHERE dataview_sid = in_sid_id;

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id, 
		csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
		security_pkg.GetApp(), 
		in_sid_id, 
		'Dataview deleted');
END;

PROCEDURE TrashObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
) AS
	v_name							dataview.name%TYPE;
BEGIN
	-- get name
	SELECT name
	  INTO v_name
	  FROM dataview 
	 WHERE dataview_sid = in_sid_id;

    csr_data_pkg.WriteAuditLogEntry(
        in_act_id, 
        csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
        security_pkg.GetApp(), 
        in_sid_id, 
        'Dataview "{0}" trashed', 
		v_name);

	trash_pkg.TrashObject(in_act_id, in_sid_id, 
		securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.GetApp(), 'Trash'),
		v_name);
END;

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
)
AS
BEGIN
	FOR r IN (
		SELECT trash_sid, description
		  FROM trash t, security.securable_object so
		 WHERE so.class_id = class_pkg.GetClassId('CSRDataView')
		   AND t.trash_sid = so.sid_id
	) LOOP
		csr_data_pkg.WriteAuditLogEntry(
			SYS_CONTEXT('SECURITY', 'ACT'),
			csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
			SYS_CONTEXT('SECURITY', 'APP'),
			r.trash_sid,
			'Dataview "{0}" restored', 
			r.description);
	END LOOP;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE dataview
	   SET parent_sid = in_new_parent_sid_id
	 WHERE dataview_sid = in_sid_id;
END;

PROCEDURE SaveDataView(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	in_name							IN	dataview.name%TYPE,
	in_start_dtm					IN	dataview.start_dtm%TYPE,
	in_end_dtm						IN	dataview.end_dtm%TYPE,
	in_group_by						IN	dataview.group_by%TYPE,
	in_period_set_id				IN	dataview.period_set_id%TYPE,
	in_period_interval_id			IN	dataview.period_interval_id%TYPE,
	in_chart_config_xml				IN 	dataview.chart_config_xml%TYPE,
	in_chart_style_xml				IN	dataview.chart_style_xml%TYPE,
	in_description					IN	dataview.description%TYPE,
	in_dataview_type_id				IN	dataview.dataview_type_id%TYPE,
	in_show_calc_trace				IN	dataview.show_calc_trace%TYPE,
	in_show_variance				IN	dataview.show_variance%TYPE,
	in_show_abs_variance			IN	dataview.show_abs_variance%TYPE,
	in_show_variance_explanations	IN	dataview.show_variance_explanations%TYPE,
	in_include_parent_region_names	IN	dataview.include_parent_region_names%TYPE,
	in_sort_by_most_recent			IN	dataview.sort_by_most_recent%TYPE,
	in_treat_null_as_zero			IN	dataview.treat_null_as_zero%TYPE,
	in_rank_limit_left				IN	dataview.rank_limit_left%TYPE,
	in_rank_limit_left_type			IN	dataview.rank_limit_left_type%TYPE,
	in_rank_limit_right				IN	dataview.rank_limit_right%TYPE,
	in_rank_limit_right_type		IN	dataview.rank_limit_right%TYPE,
	in_rank_ind_sid					IN	dataview.rank_ind_sid%TYPE,
	in_rank_filter_type				IN	dataview.rank_filter_type%TYPE,
	in_rank_reverse					IN	dataview.rank_reverse%TYPE,
	in_region_grouping_tag_group	IN	dataview.region_grouping_tag_group%TYPE,
	in_anonymous_region_names		IN	dataview.anonymous_region_names%TYPE,
	in_include_notes_in_table		IN	dataview.include_notes_in_table%TYPE,
	in_show_region_events			IN	dataview.show_region_events%TYPE,
	in_suppress_unmerged_data_msg	IN	dataview.suppress_unmerged_data_message%TYPE,
	in_highlight_changed_since		IN	dataview.highlight_changed_since%TYPE,
	in_highlight_changed_since_dtm	IN	dataview.highlight_changed_since_dtm%TYPE,
	in_show_layer_variance_pct		IN	dataview.show_layer_variance_pct%TYPE,
	in_show_layer_variance_abs		IN	dataview.show_layer_variance_abs%TYPE,
	in_show_layer_var_pct_base		IN	dataview.show_layer_variance_pct_base%TYPE,
	in_show_layer_var_abs_base		IN	dataview.show_layer_variance_abs_base%TYPE,
	in_show_layer_variance_start	IN	dataview.show_layer_variance_start%TYPE,
	in_aggregation_period_id		IN	dataview.aggregation_period_id%TYPE DEFAULT NULL,
	out_dataview_sid_id				OUT security_pkg.T_SID_ID
)
AS
    CURSOR current_cursor IS 
        SELECT parent_sid, name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos, description,
               dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id, version_num,
			   aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start
          FROM dataview
         WHERE dataview_sid = in_dataview_sid
           FOR UPDATE /* important to avoid races to increment version number */;
    r                               current_cursor%ROWTYPE;
    v_act_id                        security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
    v_next_version                  dataview.version_num%TYPE;
    v_max_versions                  customer.max_dataview_history%TYPE;
BEGIN
	IF in_dataview_sid IS NULL THEN
		SecurableObject_Pkg.CreateSO(v_act_id, in_parent_sid,
			class_pkg.getClassID('CSRDataView'), REPLACE(in_name,'/','\'), out_dataview_sid_id);
	
		INSERT INTO dataview (dataview_sid, parent_sid, name, start_dtm, end_dtm, group_by, period_set_id,
			period_interval_id, chart_config_xml, chart_style_xml, description, dataview_type_id, 
			show_calc_trace, show_variance, show_abs_variance, show_variance_explanations, 
			include_parent_region_names, sort_by_most_recent, treat_null_as_zero, last_updated_sid, rank_limit_left, 
			rank_limit_left_type, rank_limit_right, rank_limit_right_type, rank_ind_sid, rank_filter_type, 
			rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
			show_region_events, suppress_unmerged_data_message, aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start)
		VALUES (out_dataview_sid_id, in_parent_sid, in_name, in_start_dtm, in_end_dtm, in_group_by,
				in_period_set_id, in_period_interval_id, in_chart_config_xml, in_chart_style_xml, in_description,
				in_dataview_type_id, in_show_calc_trace,
				in_show_variance, in_show_abs_variance, in_show_variance_explanations, in_include_parent_region_names,
				in_sort_by_most_recent, in_treat_null_as_zero, SYS_CONTEXT('SECURITY', 'SID'),
				in_rank_limit_left, in_rank_limit_left_type, in_rank_limit_right, in_rank_limit_right_type,
				in_rank_ind_sid, in_rank_filter_type, in_rank_reverse, in_region_grouping_tag_group,
				in_anonymous_region_names, in_include_notes_in_table, in_show_region_events,
				in_suppress_unmerged_data_msg, in_aggregation_period_id, in_highlight_changed_since, in_highlight_changed_since_dtm,
				in_show_layer_variance_pct, in_show_layer_variance_abs, in_show_layer_var_pct_base, in_show_layer_var_abs_base, in_show_layer_variance_start);

		RETURN;
	END IF;
	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_dataview_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the dataview with sid '||in_dataview_sid);
	END IF;

    -- The maximum number of historical dataview versions to keep (NULL means unlimited)
	SELECT max_dataview_history
      INTO v_max_versions
	  FROM customer
	 WHERE app_sid = security_pkg.GetApp();

    OPEN current_cursor;
    FETCH current_cursor INTO r;

    v_next_version := NVL(r.version_num, 1) + 1;

    -- If history is enabled, make a copy of the current record 
    IF v_max_versions IS NULL OR v_max_versions > 0 THEN
        INSERT INTO dataview_history 
              (name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos, description,
               dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id, aggregation_period_id,
			   highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start,
               version_num, dataview_sid)
        VALUES 
              (r.name, r.start_dtm, r.end_dtm, r.group_by, r.chart_config_xml, r.chart_style_xml, r.pos, r.description,
               r.dataview_type_id, r.show_calc_trace, r.show_variance, r.show_abs_variance, r.show_variance_explanations,
               r.sort_by_most_recent, r.treat_null_as_zero, r.include_parent_region_names, r.last_updated_dtm, r.last_updated_sid, r.rank_filter_type,
               r.rank_limit_left, r.rank_ind_sid, r.rank_limit_right, r.rank_limit_left_type, r.rank_limit_right_type,
               r.rank_reverse, r.region_grouping_tag_group, r.anonymous_region_names, r.include_notes_in_table,
               r.show_region_events, r.suppress_unmerged_data_message, r.period_set_id, r.period_interval_id, r.aggregation_period_id,
			   r.highlight_changed_since, r.highlight_changed_since_dtm,
			   r.show_layer_variance_pct, r.show_layer_variance_abs, r.show_layer_variance_pct_base, r.show_layer_variance_abs_base, r.show_layer_variance_start,
               NVL(r.version_num, 1), in_dataview_sid);

        -- Clear down old records
        IF v_max_versions IS NOT NULL THEN
            DELETE FROM dataview_history 
             WHERE dataview_sid = in_dataview_sid
               AND version_num <= r.version_num - v_max_versions;
        END IF;
    END IF;

	UPDATE dataview
	   SET start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   group_by = in_group_by,
		   period_set_id = in_period_set_id,
		   period_interval_id = in_period_interval_id,
		   chart_config_xml = in_chart_config_xml,
		   chart_style_xml = in_chart_style_xml,
		   name = in_name,
		   dataview_type_id = in_dataview_type_id,
		   description = in_description,
		   show_calc_trace = in_show_calc_trace,
		   show_variance = in_show_variance,
		   show_abs_variance = in_show_abs_variance,
		   show_variance_explanations = in_show_variance_explanations,
		   include_parent_region_names = in_include_parent_region_names,
		   sort_by_most_recent = in_sort_by_most_recent,
		   treat_null_as_zero = in_treat_null_as_zero,
		   last_updated_sid = SYS_CONTEXT('SECURITY', 'SID'),
		   last_updated_dtm = sysdate,
		   rank_limit_left = in_rank_limit_left,
		   rank_limit_left_type = in_rank_limit_left_type,
		   rank_limit_right = in_rank_limit_right,
		   rank_limit_right_type = in_rank_limit_right_type,
		   rank_ind_sid = in_rank_ind_sid,
		   rank_filter_type = in_rank_filter_type,
		   rank_reverse = in_rank_reverse,
		   region_grouping_tag_group = in_region_grouping_tag_group,
		   anonymous_region_names = in_anonymous_region_names,
		   include_notes_in_table = in_include_notes_in_table,
		   show_region_events = in_show_region_events,
		   suppress_unmerged_data_message = in_suppress_unmerged_data_msg,
		   highlight_changed_since = in_highlight_changed_since,
		   highlight_changed_since_dtm = in_highlight_changed_since_dtm,
		   show_layer_variance_pct = in_show_layer_variance_pct,
		   show_layer_variance_abs = in_show_layer_variance_abs,
		   show_layer_variance_pct_base = in_show_layer_var_pct_base,
		   show_layer_variance_abs_base = in_show_layer_var_abs_base,
		   show_layer_variance_start = in_show_layer_variance_start,
		   aggregation_period_id = in_aggregation_period_id,
           version_num = v_next_version
	 WHERE CURRENT OF current_cursor;

    CLOSE current_cursor;

    csr_data_pkg.WriteAuditLogEntry(
        security_pkg.GetAct(), 
        csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
        security_pkg.GetApp(), 
        in_dataview_sid, 
        'Dataview updated to version {0}',
        v_next_version);

	IF in_parent_sid != r.parent_sid THEN
		securableobject_pkg.MoveSO(v_act_id, in_dataview_sid, in_parent_sid);
	END IF;
	securableobject_pkg.RenameSO(v_act_id, in_dataview_sid, REPLACE(in_name,'/','\'));

	-- clean up old trends + zones (they will be added again by the caller)
	DELETE FROM dataview_trend
	 WHERE dataview_sid = in_dataview_sid;

	DELETE FROM dataview_zone
	 WHERE dataview_sid = in_dataview_sid;

	out_dataview_sid_id := in_dataview_sid;
END;

PROCEDURE RenameDataView(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	dataview.name%TYPE
)
AS
	v_act_id						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_dataview_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the dataview with sid '||in_dataview_sid);
	END IF;

	securableobject_pkg.RenameSO(v_act_id, in_dataview_sid, REPLACE(in_name,'/','\'));
	-- the SO rename hits the DV RenameObject (earlier on in this pkg), so we have to set back to the desired name.
	UPDATE dataview
	   SET name = in_name
	 WHERE dataview_sid = in_dataview_sid;
END;

PROCEDURE GetDataView(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;

	OPEN out_cur FOR
		SELECT name, start_dtm, end_dtm, group_by, period_set_id, period_interval_id, chart_config_xml, 
			   chart_style_xml, description, dataview_type_id,
			   show_calc_trace, show_variance, show_abs_variance, show_variance_explanations, include_parent_region_names, 
			   sort_by_most_recent, treat_null_as_zero, parent_sid, rank_limit_left, rank_limit_left_type, 
			   rank_limit_right, rank_limit_right_type, rank_ind_sid, rank_filter_type, rank_reverse,
			   region_grouping_tag_group, anonymous_region_names, include_notes_in_table, show_region_events, suppress_unmerged_data_message,
			   aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start
		  FROM dataview 
		 WHERE dataview_sid = in_dataview_sid;
END;


PROCEDURE GetDataViewZones(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;

	OPEN out_cur FOR
		SELECT start_val_ind_sid, isd.description start_val_ind_description, 
			   start_val_region_sid, rsd.description start_val_region_description, 
			   start_val_start_dtm, start_val_end_dtm,
			   end_val_ind_sid, ied.description end_val_ind_description, 
			   end_val_region_sid, red.description end_val_region_description, 
			   end_val_start_dtm, end_val_end_dtm,
			   style_xml, dz.pos, dz.name, dz.type, dz.description,
			   dz.is_target, dz.target_direction
		  FROM dataview_zone dz, v$ind isd, v$ind ied, v$region rsd, v$region red
		 WHERE dataview_sid = in_dataview_sid
		   AND dz.start_val_ind_sid = isd.ind_sid
		   AND dz.start_val_region_sid = rsd.region_sid
		   AND dz.end_val_ind_sid = ied.ind_sid(+)
		   AND dz.end_val_region_sid = red.region_sid(+)
		 ORDER BY dz.pos;
END;

-- No security, only called after SaveDataView
PROCEDURE UNSEC_AddDataViewZone(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_pos							IN	dataview_zone.pos%TYPE,
	in_type							IN	dataview_zone.type%TYPE,
	in_name							IN	dataview_zone.name%TYPE,
	in_description					IN	dataview_zone.description%TYPE,
	in_start_val_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_val_region_sid			IN	security_pkg.T_SID_ID,
	in_start_val_start_dtm			IN	dataview_zone.start_val_start_dtm%TYPE,
	in_start_val_end_dtm			IN	dataview_zone.start_val_end_dtm%TYPE,
	in_end_val_ind_sid				IN	security_pkg.T_SID_ID,
	in_end_val_region_sid			IN	security_pkg.T_SID_ID,
	in_end_val_start_dtm			IN	dataview_zone.end_val_start_dtm%TYPE,
	in_end_val_end_dtm				IN	dataview_zone.end_val_end_dtm%TYPE,
	in_style_xml					IN	dataview_zone.style_xml%TYPE,
	in_is_target					IN	dataview_zone.is_target%TYPE,
	in_target_direction				IN	dataview_zone.target_direction%TYPE
)
AS
BEGIN
	INSERT INTO dataview_zone
		(dataview_sid, pos, name, start_val_ind_sid, start_val_region_sid,
		 start_val_start_dtm, start_val_end_dtm, end_val_ind_sid, end_val_region_sid,
		 end_val_start_dtm, end_val_end_dtm, style_xml, type, description, is_target,
		 target_direction)
	VALUES
		(in_dataview_sid, in_pos, in_name, in_start_val_ind_sid, in_start_val_region_sid,
		 in_start_val_start_dtm, in_start_val_end_dtm, in_end_val_ind_sid,
		 in_end_val_region_sid, in_end_val_start_dtm, in_end_val_end_dtm, in_style_xml,
		 in_type, in_description, in_is_target, in_target_direction);
END;

-- no security, only called after SaveDataView
PROCEDURE UNSEC_AddDataViewTrend(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_pos							IN	dataview_trend.pos%TYPE,
	in_name							IN	dataview_trend.name%TYPE,
	in_title						IN	dataview_trend.title%TYPE,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_months						IN	dataview_trend.months%TYPE,
	in_rounding_method				IN	dataview_trend.rounding_method%TYPE,
	in_rounding_digits				IN	dataview_trend.rounding_digits%TYPE
)
AS
BEGIN
	INSERT INTO dataview_trend
		(pos, name, title, dataview_sid, ind_sid, region_sid, months,
		rounding_method, rounding_digits) 
	VALUES
		(in_pos, in_name, in_title, in_dataview_sid, in_ind_sid, in_region_sid,
		in_months, in_rounding_method, in_rounding_digits);
END;


PROCEDURE GetDataViewTrends(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;

	OPEN out_cur FOR
		SELECT pos, name, title, ind_sid, region_sid, months, rounding_method, rounding_digits
		  FROM dataview_trend
		 WHERE dataview_sid = in_dataview_sid
		 ORDER BY pos;
END;


PROCEDURE GetChildDataViews(
	in_act_id			 IN security_pkg.T_ACT_ID,
	in_parent_sid		 IN security_pkg.T_SID_ID,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur				 OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing contents on the container with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT /*+ ALL_ROWS */ d.dataview_sid, d.parent_sid, d.name, d.start_dtm, d.end_dtm, d.group_by,
			   d.period_set_id, d.period_interval_id, d.chart_config_xml, d.chart_style_xml, d.dataview_type_id,
			   d.description, d.rank_ind_sid, 
			   CASE 
				 WHEN vd.sid_id IS NOT NULL THEN 1
				 ELSE 0
			   END 
			   AS can_delete
		  FROM dataview d
		  JOIN TABLE(securableobject_pkg.GetChildrenWithPermAsTable(in_act_id, in_parent_sid, security_pkg.PERMISSION_READ)) v ON v.sid_id = d.dataview_sid
		  LEFT JOIN TABLE(securableobject_pkg.GetChildrenWithPermAsTable(in_act_id, in_parent_sid, security_pkg.PERMISSION_DELETE)) vd ON vd.sid_id = d.dataview_sid
		 WHERE (dataview_type_id = in_dataview_type_id OR in_dataview_type_id = 0) 
		   AND d.parent_sid = in_parent_sid
		 ORDER BY d.name;
END;

PROCEDURE GetChildDataViewsByPos(
	in_act_id			 IN security_pkg.T_ACT_ID,
	in_parent_sid		 IN security_pkg.T_SID_ID,
	out_cur				 OUT SYS_REFCURSOR
)
AS
BEGIN
	GetChildDataViewsByPos(in_act_id, in_parent_sid, 0, out_cur);
END;

PROCEDURE GetChildDataViewsByPos(
	in_act_id			 IN security_pkg.T_ACT_ID,
	in_parent_sid		 IN security_pkg.T_SID_ID,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur				 OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing contents on the container with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT dataview_sid, name
		  FROM dataview 
		 WHERE parent_sid = in_parent_sid 
		   AND (dataview_type_id = in_dataview_type_id OR in_dataview_type_id = 0) 
	  ORDER BY pos;
END;

PROCEDURE GetInstanceDataViews(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_context			IN instance_dataview.context%TYPE,
	in_instance_Id	IN instance_dataview.instance_Id%TYPE,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_context, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing contents on the context with sid '||in_context);
	END IF;

	OPEN out_cur FOR
		SELECT d.dataview_sid, d.name, d.start_dtm, d.end_dtm, d.group_by, d.period_set_id, 
			   d.period_interval_id, d.chart_config_xml, d.chart_style_xml, d.dataview_type_id, 
			   d.description
		  FROM dataview d, instance_dataview id 
		 WHERE id.context = in_context AND id.instance_id = in_instance_id 
		   AND id.dataview_sid = d.dataview_sid
		   AND (dataview_type_id = in_dataview_type_id OR in_dataview_type_id = 0)
		 ORDER BY id.pos;
END;


PROCEDURE AddInstanceDataView(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_context						IN instance_dataview.context%TYPE,
	in_instance_id					IN instance_dataview.instance_Id%TYPE,
	in_dataview_sid					IN security_pkg.T_SID_ID,
	in_pos							IN instance_dataview.pos%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_context, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding an instance dataview to the context with sid '||in_context);
	END IF;

	BEGIN
		INSERT INTO instance_Dataview 
			(instance_id, context, dataview_sid, pos)
		SELECT in_instance_id, in_context, in_dataview_sid, NVL(in_pos, NVL(MAX(pos),0)+1)
			FROM instance_dataview 
		 WHERE instance_id = in_instance_id
		   AND context = in_context;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;


PROCEDURE RemoveInstanceDataView(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_context			IN instance_dataview.context%TYPE,
	in_instance_Id	IN instance_dataview.instance_Id%TYPE,
	in_dataview_sid	IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- well add /remove, same thing...
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_context, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied removing an instance dataview from the context with sid '||in_context);
	END IF;

	DELETE FROM instance_Dataview
	 WHERE instance_id = in_instance_id
	   AND context = in_context 
	   AND dataview_sid = in_dataview_sid;
END;


PROCEDURE GetDescendantDataViews(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_root_sid		IN security_pkg.T_SID_ID,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dataview_sid, name, start_dtm, end_dtm, group_by, period_set_id, period_interval_id,
			   chart_config_xml, chart_style_xml, dataview_type_id, description, 
			   securableobject_pkg.GetPathFromSID(in_act_id, dataview_sid) as dataview_path
		 FROM dataview
		WHERE (dataview_type_id = in_dataview_type_id OR in_dataview_type_id = 0) AND
			  parent_sid IN (
			  	SELECT sid_id FROM TABLE(securableobject_pkg.GetDescendantsAsTable(in_act_id, in_root_sid) )) 
		ORDER BY name;
END;

PROCEDURE CopyDataView(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_dataview_sid	IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
) AS
    CURSOR c IS
	    SELECT dataview_sid, parent_sid, name, start_dtm, end_dtm, group_by, period_set_id, 
	    	   period_interval_id, chart_config_xml, chart_style_xml, pos, description, 
	    	   dataview_type_id, show_calc_trace, 
	    	   show_variance, show_abs_variance, show_variance_explanations, include_parent_region_names,
			   sort_by_most_recent, treat_null_as_zero, last_updated_dtm, 
	    	   last_updated_sid, rank_filter_type, rank_limit_left, rank_ind_sid, rank_limit_right, 
	    	   rank_limit_left_type, rank_limit_right_type, rank_reverse
		  FROM dataview
         WHERE dataview_sid = in_copy_dataview_sid;
    r	c%ROWTYPE;
	v_duplicate_count	NUMBER(10);
	v_name			security_pkg.T_SO_NAME;
	v_try_again		BOOLEAN;
	v_user_sid		security_pkg.T_SID_ID;
BEGIN
	user_pkg.getsid (in_act_id, v_user_sid);	-- check permission is done by create SO 
    OPEN c;
    FETCH c INTO r;

    -- unique name
    v_name := replace(r.name,'/','\'); --'
	v_duplicate_count := 0;
	v_try_again := TRUE;
	WHILE v_try_again LOOP
		BEGIN
			SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, class_pkg.GetClassID('CSRDataView'),
				v_name, out_sid_id);
			v_try_again := FALSE;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_name := replace(r.name,'/','\') || ' (copy)'; --'
				v_duplicate_count := v_duplicate_count + 1;
				IF v_duplicate_count > 1 THEN
					v_name := r.name||' (copy '||v_duplicate_count||')';
				END IF;
				v_try_again := TRUE;
		END;
	END LOOP;

	INSERT INTO dataview (
		dataview_sid, parent_sid, name, start_dtm, end_dtm, group_by, period_set_id, period_interval_id, 
		chart_config_xml, chart_style_xml, pos, description, dataview_type_id,
		show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
		include_parent_region_names, sort_by_most_recent, treat_null_as_zero, last_updated_dtm, last_updated_sid,
		rank_filter_type, rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type,
		rank_limit_right_type, rank_reverse
	) VALUES (
		out_sid_id, in_parent_sid_id, r.name, r.start_dtm, r.end_dtm, r.group_by, r.period_set_id,
		r.period_interval_id, r.chart_config_xml, r.chart_style_xml, r.pos, r.description,
		r.dataview_type_id, r.show_calc_trace,
		r.show_variance, r.show_abs_variance, r.show_variance_explanations, r.include_parent_region_names,
		r.sort_by_most_recent, r.treat_null_as_zero, SYSDATE, v_user_sid,
		r.rank_filter_type, r.rank_limit_left, r.rank_ind_sid, r.rank_limit_right, 
		r.rank_limit_left_type, r.rank_limit_right_type, r.rank_reverse
	);

    -- copy regions
    INSERT INTO dataview_region_member (dataview_sid, region_sid, pos, tab_level)
		SELECT out_sid_id, region_sid, pos, tab_level
		  FROM dataview_region_member
		 WHERE dataview_sid = in_copy_dataview_sid;

	-- copy description overrides
	INSERT INTO dataview_region_description (dataview_sid, region_sid, lang, description)
		SELECT out_sid_id, region_sid, lang, description
		  FROM dataview_region_description
		 WHERE dataview_sid = in_copy_dataview_sid;

    -- copy indicators
    INSERT INTO dataview_ind_member (
		dataview_sid, ind_sid, calculation_type_id, pos, format_mask,
		measure_conversion_id, normalization_ind_sid, show_as_rank
	    ) 
		SELECT out_sid_id, ind_sid, calculation_type_id, pos, format_mask,
			   measure_conversion_id, normalization_ind_sid, show_as_rank
		  FROM dataview_ind_member
		 WHERE dataview_sid = in_copy_dataview_sid;
		 
	-- copy description overrides
	INSERT INTO dataview_ind_description (dataview_sid, pos, lang, description)
		SELECT out_sid_id, pos, lang, description
		  FROM dataview_ind_description
		 WHERE dataview_sid = in_copy_dataview_sid;

    -- copy history records
    INSERT INTO dataview_history 
              (name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos, description,
               dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id,
               version_num, dataview_sid)
        SELECT name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos, description,
               dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id,
               version_num, out_sid_id
          FROM dataview_history 
         WHERE dataview_sid = in_copy_dataview_sid;

    csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=> security_pkg.GetAct(),
		in_audit_type_id	=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid			=> security_pkg.GetApp(),
		in_object_sid		=> out_sid_id,
		in_description		=> 'Dataview copied from {0} ({1})',
		in_param_1			=> r.name,
		in_param_2			=> TO_CHAR(in_copy_dataview_sid)
		);

END;

PROCEDURE RemoveIndicators(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
)	
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;
	
	DELETE FROM dataview_ind_description
	 WHERE dataview_sid = in_sid_id;
	DELETE FROM dataview_ind_member
	 WHERE dataview_sid = in_sid_id;
END;

PROCEDURE AddIndicator(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_dataview_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_calculation_type_id		IN	security_pkg.T_SID_ID,
	in_format_mask				IN	ind.format_mask%TYPE,
	in_measure_conversion_id	IN	dataview_ind_member.measure_conversion_id%TYPE,
	in_normalization_ind_sid	IN	dataview_ind_member.normalization_ind_sid%TYPE,
	in_show_as_rank				IN	dataview_ind_member.show_as_rank%TYPE,
	in_langs					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_pos						NUMBER;
	v_format_mask				ind.format_mask%TYPE;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '|| in_dataview_sid);
	END IF;
	
	SELECT NVL(MAX(pos), 0) + 1
	  INTO v_pos
	  FROM dataview_ind_member
	 WHERE dataview_sid = in_dataview_sid;
	
	-- if the format mask has been overriden then save it, otherwise take it off
	-- the indicator every time.
	SELECT NVL(i.format_mask, m.format_mask)
	  INTO v_format_mask
	  FROM ind i
	  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
	 WHERE ind_sid = in_ind_sid;
	IF v_format_mask = in_format_mask THEN
		v_format_mask := NULL;
	ELSE
		v_format_mask := in_format_mask;
	END IF;
	
	INSERT INTO dataview_ind_member
		(dataview_sid, ind_sid, pos, calculation_type_id, format_mask,
		 measure_conversion_id, normalization_ind_sid, show_as_rank)
	VALUES
		(in_dataview_sid, in_ind_sid, v_pos, in_calculation_type_id, v_format_mask,
		 DECODE(in_measure_conversion_id, -1, null, in_measure_conversion_id), in_normalization_ind_sid,
		 in_show_as_rank);

	-- add translations where they differ from the base language
	FOR i IN 1 .. in_translations.COUNT LOOP
		INSERT INTO dataview_ind_description (dataview_sid, pos, lang, description)
			SELECT in_dataview_sid, v_pos, in_langs(i), in_translations(i)
			  FROM dual
			 WHERE in_translations(i) IS NOT NULL
			 MINUS
			SELECT in_dataview_sid, v_pos, lang, description
			  FROM ind_description
			 WHERE ind_sid = in_ind_sid
			   AND lang = in_langs(i);
	END LOOP;
END;

PROCEDURE GetIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_ind_cur						OUT SYS_REFCURSOR,
	out_ind_tag_cur					OUT SYS_REFCURSOR,
	out_normalisation_ind_cur		OUT SYS_REFCURSOR,
	out_ind_translations_cur		OUT SYS_REFCURSOR
)
AS
BEGIN							   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;

	-- should we be checking the security on the indicators?
	OPEN out_ind_cur FOR
		SELECT -- ind properties
			   i.ind_sid, i.name, 
			   NVL(did.description, i.description) description, i.lookup_key,
			   m.name measure_name, m.description measure_description, m.measure_sid,
			   i.gri, i.multiplier,	NVL(i.scale, m.scale) scale,
			   NVL(dim.format_mask, NVL(i.format_mask, m.format_mask)) format_mask, i.active,
			   i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.start_month, i.ind_type,
			   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, 
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation,
			   i.calc_description, i.target_direction, i.last_modified_dtm,
			   extract(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, i.aggregate,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.factor_type_id,
			   i.ind_activity_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
			   i.normalize, i.core, i.roll_forward, i.prop_down_region_tree_sid,
			   i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm,
			   i.calc_output_round_dp,
			   -- dataview_ind_member properties
			   dim.measure_conversion_id, dim.show_as_rank, dim.normalization_ind_sid,
			   dim.calculation_type_id calculation_type, dim.pos dataview_pos
		  FROM dataview_ind_member dim
		  JOIN v$ind i
		    ON dim.ind_sid = i.ind_sid
		  LEFT JOIN measure m
		    ON i.measure_sid = m.measure_sid
		  LEFT JOIN dataview_ind_description did 
		    ON dim.app_sid = did.app_sid AND did.dataview_sid = dim.dataview_sid
		   AND dim.pos = did.pos 
		   AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE dim.dataview_sid = in_sid_id
		 ORDER BY dim.pos;
		 
	OPEN out_normalisation_ind_cur FOR
		SELECT i.ind_sid, i.name, i.description, i.lookup_key, m.name measure_name, m.description measure_description,m.measure_sid,
			   i.gri, i.multiplier,	NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, i.active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   i.ind_type, i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, i.calc_description, 
			   i.target_direction, i.last_modified_dtm, extract(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, i.aggregate, 
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.factor_type_id, i.ind_activity_type_id, 
			   i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.normalize,
			   i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm,
			   i.calc_output_round_dp
		  FROM v$ind i 
			   LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE i.ind_sid IN (
		   		SELECT normalization_ind_sid
		   		  FROM dataview_ind_member
		   		 WHERE dataview_sid = in_sid_id);

	OPEN out_ind_translations_cur FOR
		SELECT dim.pos, id.lang, NVL(did.description, id.description) description
		  FROM dataview_ind_member dim
		  JOIN ind_description id
		    ON id.app_sid = dim.app_sid AND id.ind_sid = dim.ind_sid
		  LEFT JOIN dataview_ind_description did
		    ON did.app_sid = dim.app_sid AND did.dataview_sid = dim.dataview_sid 
		   AND did.pos = dim.pos
		   AND did.lang = id.lang
		 WHERE dim.dataview_sid = in_sid_id
		 ORDER BY dim.pos;

	OPEN out_ind_tag_cur FOR
		SELECT itg.ind_sid, itg.tag_id
		  FROM ind_tag itg
		 WHERE (itg.app_sid, itg.ind_sid) IN (
		 		SELECT app_sid, ind_sid
		 		  FROM dataview_ind_member
		 		 WHERE dataview_sid = in_sid_id
		 		 UNION ALL
		 		SELECT app_sid, normalization_ind_sid
		 		  FROM dataview_ind_member
		 		 WHERE dataview_sid = in_sid_id
		 		   AND normalization_ind_sid IS NOT NULL);
END;

/** 
 * Determines if an indicator is used in a data view for the purpose of normalisation.
 *
 *	@param in_ind_sid	
 *		The SID of the indicator to test.
 *
 *	@param in_check_children
 *		If specified, descendents of the specified indicator will also be checked.
 *
 *	@return 
 *		Returns 1, if the indicator is used for normalisation; otherwise, returns 0.
 */
FUNCTION IsIndicatorUsedInNormalisation(
	in_ind_sid						IN security_pkg.T_SID_ID,
	in_check_children				IN NUMBER DEFAULT(0)
) RETURN NUMBER
AS
	used_for_normalisation			NUMBER(1) := 0;
BEGIN
	IF in_check_children = 0 THEN
		-- Check if any data view indicators use in_ind_sid as a normalisation indicator
		SELECT CASE WHEN EXISTS( SELECT ind_sid FROM dataview_ind_member
								  WHERE normalization_ind_sid = in_ind_sid ) 
			THEN 1 ELSE 0 
		END
		INTO used_for_normalisation FROM dual;
	ELSE
		-- Check if in_ind_sid, or any of its descendent indicators, are used as a 
		-- normalisation indicator on a data view indicator.
		SELECT CASE 
			WHEN EXISTS (
				SELECT ind_sid 
				  FROM (
					-- Indicator hierachy rooted at in_ind_sid
					SELECT i.ind_sid
					  FROM ind i
					 START WITH i.ind_sid = in_ind_sid 
					CONNECT BY PRIOR i.ind_sid = i.parent_sid
				) 
				WHERE ind_sid in ( 
					SELECT normalization_ind_sid 
					  FROM dataview_ind_member 
				) 
			)
			THEN 1 ELSE 0
		END
		INTO used_for_normalisation FROM dual;
	END IF;
		
	RETURN used_for_normalisation;
END;

PROCEDURE RemoveRegions(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
)	
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;

	DELETE FROM tpl_report_tag_dv_region
	 WHERE dataview_sid = in_sid_id;

	DELETE FROM dataview_region_description
	 WHERE dataview_sid = in_sid_id;
	 
	DELETE FROM dataview_region_member
	 WHERE dataview_sid = in_sid_id;
END;

FUNCTION GetScenarioDescription(
	in_scenario_run_type	IN	csr.dataview_scenario_run.scenario_run_type%TYPE,
	in_scenario_sid			IN	csr.scenario.scenario_sid%TYPE,
	in_scenario_run_sid		IN	csr.scenario_run.scenario_run_sid%TYPE
) RETURN VARCHAR2
AS
	v_count				NUMBER;
	v_description		csr.scenario_run.description%TYPE;
BEGIN
	IF in_scenario_run_type = 0 THEN
		RETURN 'Merged data';
	ELSIF in_scenario_run_type = 1 THEN
		RETURN 'Unmerged data';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.scenario_run
	 WHERE scenario_sid = in_scenario_sid;
	
	SELECT CASE WHEN v_count < 2 THEN s.description ELSE sr.description END description
	  INTO v_description
	  FROM csr.scenario_run sr
	  JOIN csr.scenario s on sr.scenario_sid = s.scenario_sid
	 WHERE scenario_run_sid = in_scenario_run_sid
	   AND sr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	RETURN v_description;
END;

PROCEDURE GetScenarioRuns(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the dataview with sid '||in_dataview_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT CASE WHEN dsr.scenario_run_type < 2 THEN dsr.scenario_run_type ELSE dsr.scenario_run_sid END scenario_run_sid, GetScenarioDescription(dsr.scenario_run_type,sc.scenario_sid, sr.scenario_run_sid) description
		  FROM dataview_scenario_run dsr
		  LEFT JOIN scenario_run sr ON dsr.app_sid = sr.app_sid AND dsr.scenario_run_sid = sr.scenario_run_sid
		  LEFT JOIN csr.scenario sc ON sr.app_sid = sc.app_sid AND sr.scenario_sid = sc.scenario_sid
		 WHERE dsr.dataview_sid = in_dataview_sid;
END;

PROCEDURE SetScenarioRuns(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	in_scenario_run_sids			IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the dataview with sid '||in_dataview_sid);
	END IF;
	
	DELETE FROM dataview_scenario_run
	 WHERE dataview_sid = in_dataview_sid;	

	IF in_scenario_run_sids.COUNT = 0 OR (in_scenario_run_sids.COUNT = 1 AND in_scenario_run_sids(1) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just do nothing
		NULL;
	ELSE
		FORALL i IN INDICES OF in_scenario_run_sids
			INSERT INTO dataview_scenario_run (dataview_sid, scenario_run_type, scenario_run_sid)
			VALUES (in_dataview_sid, LEAST(2, in_scenario_run_sids(i)), CASE WHEN in_scenario_run_sids(i) < 2 THEN NULL ELSE in_scenario_run_sids(i) END);
	END IF;
END;

PROCEDURE AddRegion(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_sid_id					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_level					IN	NUMBER,
	in_langs					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations				IN	security_pkg.T_VARCHAR2_ARRAY
)	
AS						
	v_max_pos	NUMBER;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;
	
	SELECT NVL(MAX(pos), 0)
	  INTO v_max_pos
	  FROM dataview_region_member
	 WHERE dataview_sid = in_sid_id;
			
	INSERT INTO dataview_region_member
		(dataview_sid, region_sid, pos, tab_level)
	VALUES 
		(in_sid_id, in_region_sid, v_max_pos + 1, in_level);

	-- add translations where they differ from the base language
	FOR i IN 1 .. in_translations.COUNT LOOP
		INSERT INTO dataview_region_description (dataview_sid, region_sid, lang, description)
			SELECT in_sid_id, in_region_sid, in_langs(i), in_translations(i)
			  FROM dual
			 WHERE in_translations(i) IS NOT NULL
			 MINUS
			SELECT in_sid_id, in_region_sid, lang, description
			  FROM region_description
			 WHERE region_sid = in_region_sid
			   AND lang = in_langs(i);
	END LOOP;
END;

PROCEDURE AddTplReportRegion(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_tpl_report_tag_dataview_id	IN tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_tpl_region_type_id			IN tpl_report_tag_dv_region.tpl_region_type_id%TYPE,
	in_filter_by_tag				IN tpl_report_tag_dv_region.filter_by_tag%TYPE
)
AS
BEGIN							   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;
 
	INSERT INTO tpl_report_tag_dv_region (
		tpl_report_tag_dataview_id, dataview_sid, region_sid, tpl_region_type_id, filter_by_tag
	) VALUES (
		in_tpl_report_tag_dataview_id, in_sid_id, in_region_sid, in_tpl_region_type_id, in_filter_by_tag
	);
END;

PROCEDURE GetRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_region_cur					OUT SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR,
	out_region_translation_cur		OUT	SYS_REFCURSOR
)
AS
    CURSOR check_perm_cur IS
        SELECT region_sid
          FROM dataview_region_member
         WHERE dataview_sid = in_sid_id
           AND security_pkg.sql_IsAccessAllowedSID(in_act_id, region_sid, security_pkg.PERMISSION_READ)=0;
    check_perm number(10);
BEGIN							   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;

    -- Check the permissions on all the regions in this range. We want to throw an exception rather 
    -- than return missing regions which would only confuse the users.
    OPEN check_perm_cur;
    FETCH check_perm_cur INTO check_perm;
    IF check_perm_cur%FOUND THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
    END IF;

	-- should we be checking the security on the regions?
	OPEN out_region_cur FOR
		SELECT drm.region_sid, r.parent_sid, drm.pos, drm.tab_level, NVL(drd.description, r.description) description, r.active, r.name, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, 
			   r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref, r.info_xml
		  FROM dataview_region_member drm
		  JOIN v$region r ON drm.region_sid = r.region_sid
		  LEFT JOIN dataview_region_description drd
		    ON drm.app_sid = drd.app_sid AND drd.dataview_sid = drm.dataview_sid
		   AND drm.region_sid = drd.region_sid
		   AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE drm.dataview_sid = in_sid_id
		 ORDER BY pos;
		 
	OPEN out_region_translation_cur FOR
		SELECT drm.region_sid, rd.lang, NVL(drd.description, rd.description) description
		  FROM dataview_region_member drm
		  JOIN region_description rd
		    ON rd.app_sid = drm.app_sid AND rd.region_sid = drm.region_sid
		  LEFT JOIN dataview_region_description drd
		    ON drd.app_sid = drm.app_sid AND drd.dataview_sid = drm.dataview_sid 
		   AND drd.region_sid = drm.region_sid
		   AND drd.lang = rd.lang
		 WHERE drm.dataview_sid = in_sid_id
		 ORDER BY drm.pos;

	OPEN out_region_tag_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM dataview_region_member drm, region_tag rt
		 WHERE rt.app_sid = drm.app_sid AND rt.region_sid = drm.region_sid
		 ORDER BY rt.region_sid, rt.tag_id;
END;

PROCEDURE GetDataViewRegions(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
)
AS
	v_region_sids					security.T_ORDERED_SID_TABLE;
	v_ordered_region_sids			security.T_ORDERED_SID_TABLE;
	v_allowed_region_sids			security.T_SO_TABLE;
	v_first_sid						region.region_sid%TYPE;
BEGIN
	-- Check the permissions / existence of region sids as directed
	v_ordered_region_sids := security_pkg.SidArrayToOrderedTable(in_region_sids);
	v_allowed_region_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security_pkg.SidArrayToTable(in_region_sids), 
		security_pkg.PERMISSION_READ
	);

	-- skipping missing and denied can be done in one step
	-- paths: skip missing=M, skip denied=D MD; cases 00, 01, 10, 11
	IF in_skip_missing = 1 AND in_skip_denied = 1 THEN -- 11
		SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
		  BULK COLLECT INTO v_region_sids
		  FROM region r,
		  	   TABLE(v_ordered_region_sids) rp,
		  	   TABLE(v_allowed_region_sids) ar
		 WHERE r.region_sid = rp.sid_id
		   AND ar.sid_id = r.region_sid
		   AND ar.sid_id = rp.sid_id;
	-- otherwise check separately, according to preferences
	ELSE
		IF in_skip_missing = 1 THEN -- 10 (M=1 and D!=1 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_region_sids
			  FROM region r,
				   TABLE(v_ordered_region_sids) rp
			 WHERE r.region_sid = rp.sid_id;

			v_ordered_region_sids := v_region_sids;
		ELSE -- 00 or 01
			-- report missing, if any
			SELECT MIN(rr.sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_region_sids) rr
			  LEFT JOIN region r
				ON r.region_sid = rr.sid_id
			 WHERE r.region_sid IS NULL;

			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The region with sid '||v_first_sid||' does not exist');
			END IF;
		END IF;
		
		IF in_skip_denied = 1 THEN -- 01 (D=1 and M!=0 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_region_sids
			  FROM TABLE(v_allowed_region_sids) ar
			  JOIN TABLE(v_ordered_region_sids) rp
			    ON ar.sid_id = rp.sid_id;
		ELSE -- 00 or 10
			SELECT MIN(sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_region_sids) rp
			 WHERE sid_id NOT IN (
			 		SELECT sid_id
			 		  FROM TABLE(v_allowed_region_sids));
			
			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
					'Read permission denied on the region with sid '||v_first_sid);
			END IF;
			
			-- 00 => no region sids set, use input
			IF in_skip_missing = 0 THEN
				v_region_sids := v_ordered_region_sids;
			END IF;
		END IF;
	END IF;

	OPEN out_region_cur FOR
		SELECT NVL(rl.region_sid ,r.region_sid) region_sid,
			   r.name, r.description, -- same across region and linked region
			   NVL(rl.parent_sid ,r.parent_sid) parent_sid,
			   NVL(rl.pos, r.pos) pos,
			   extract(NVL(rl.info_xml, r.info_xml),'/').getClobVal() info_xml,
			   NVL(rl.active, r.active) active,
			   CASE WHEN r.link_to_region_sid IS NOT NULL THEN r.region_sid ELSE NULL END link_to_region_sid,
			   NVL(rl.region_type, r.region_type) region_type,
			   pr.region_type parent_region_type, -- useful for metering where the parent type is important for rates - we're not checking permission on the parent but we're not exactly leaking valuable information
			   region_pkg.INTERNAL_GetRegionPathString(r.region_sid) path,
			   region_pkg.INTERNAL_GetRegionPathString(rl.region_sid) link_to_region_path,
			   NVL(rl.geo_latitude, r.geo_latitude) geo_latitude,
			   NVL(rl.geo_longitude, r.geo_longitude) geo_longitude,
			   NVL(rl.geo_country, r.geo_country) geo_country,
			   NVL(rl.geo_region, r.geo_region) geo_region,
			   NVL(rl.geo_city_id, r.geo_city_id) geo_city_id,
			   NVL(rl.map_entity, r.map_entity) map_entity,
			   NVL(rl.egrid_ref, r.egrid_ref) egrid_ref,
			   NVL(rl.geo_type, r.geo_type) geo_type,
			   NVL(rl.disposal_dtm, r.disposal_dtm) disposal_dtm,
			   NVL(rl.acquisition_dtm, r.acquisition_dtm) acquisition_dtm,
			   NVL(rl.lookup_key, r.lookup_key) lookup_key,
			   NVL(rl.region_ref, r.region_ref) region_ref,
			   drm.tab_level
		  FROM TABLE(v_region_sids) rs
		  JOIN v$region r ON rs.sid_id = r.region_sid
		  JOIN dataview_region_member drm ON rs.sid_id = drm.region_sid AND r.app_sid = drm.app_sid AND in_dataview_sid = drm.dataview_sid
		  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid
		  LEFT JOIN region pr ON r.parent_sid = pr.region_sid AND r.app_sid = pr.app_sid
		 ORDER BY rs.pos;
		
	OPEN out_tag_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM TABLE(v_region_sids) s, region_tag rt
		 WHERE rt.region_sid = s.sid_id
		 ORDER BY rt.region_sid, rt.tag_id;
END;

PROCEDURE GetTplReportsRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN							   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_sid_id);
	END IF;
 
	OPEN out_cur FOR
		SELECT tpl_report_tag_dataview_id, dataview_sid, region_sid, tpl_region_type_id, filter_by_tag
		  FROM tpl_report_tag_dv_region
		 WHERE dataview_sid = in_sid_id;
END;

-- Note that calls to the following are constructed dynamically
-- as csr.dataview_pkg.Get{0}Translations
-- by C:\cvs\fproot\App_Code\Credit360\Web\JsonRpcHandler.cs

PROCEDURE GetIndicatorTranslations(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the indicator with sid '||in_ind_sid);
	END IF;

	OPEN out_cur FOR
		SELECT lang, description
		  FROM ind_description
		 WHERE ind_sid = in_ind_sid;
END;

PROCEDURE GetRegionTranslations(
	in_region_sid					IN	region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the region with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT lang, description
		  FROM region_description
		 WHERE region_sid = in_region_sid;
END;

PROCEDURE GetArbitraryPeriods(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the dataview with sid '||in_dataview_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT dataview_sid, start_dtm, end_dtm
		  FROM dataview_arbitrary_period dap
		 WHERE dap.dataview_sid = in_dataview_sid
		 ORDER BY start_dtm;
END;

PROCEDURE RecordHistoricArbitraryPeriods(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE
)
AS
    v_curr_version                  dataview.version_num%TYPE;
    v_last_version                  dataview.version_num%TYPE;
    v_max_versions                  customer.max_dataview_history%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_dataview_sid);
	END IF;
 
    -- This occurs during the update of a dataview.
	-- The maximum number of historical dataview versions to keep (NULL means unlimited)
	SELECT max_dataview_history
      INTO v_max_versions
	  FROM customer
	 WHERE app_sid = security_pkg.GetApp();

	SELECT version_num
      INTO v_curr_version
	  FROM dataview
	 WHERE app_sid = security_pkg.GetApp()
	   AND dataview_sid = in_dataview_sid;

    v_last_version := NVL(v_curr_version, 1) - 1;

	IF v_max_versions IS NULL OR v_max_versions > 0 THEN
		FOR r IN (SELECT dataview_sid, start_dtm, end_dtm
					FROM dataview_arbitrary_period
					WHERE dataview_sid = in_dataview_sid
					  FOR UPDATE)
		LOOP
			-- IF r.dataview_sid IS NOT NULL 
			INSERT INTO dataview_arbitrary_period_hist 
				  (dataview_sid, start_dtm, end_dtm, version_num)
			VALUES 
				  (in_dataview_sid, r.start_dtm, r.end_dtm, v_last_version);
		END LOOP;
	END IF;

   IF v_max_versions IS NULL OR v_max_versions > 0 THEN
		-- Clear down old records
		IF v_max_versions IS NOT NULL THEN
			DELETE FROM dataview_arbitrary_period_hist
			 WHERE dataview_sid = in_dataview_sid
			   AND version_num <= v_last_version - v_max_versions;
		END IF;
	END IF;
END;

PROCEDURE RemoveAllArbitraryPeriods(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_dataview_sid);
	END IF;
 
	DELETE FROM dataview_arbitrary_period 
	 WHERE dataview_sid = in_dataview_sid;
END;

PROCEDURE SetArbitraryPeriod(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE,
	in_start_dtm					IN	dataview_arbitrary_period.start_dtm%TYPE,
	in_end_dtm						IN	dataview_arbitrary_period.end_dtm%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the dataview with sid '||in_dataview_sid);
	END IF;
 
	INSERT INTO dataview_arbitrary_period (
		dataview_sid, start_dtm, end_dtm
	) VALUES (
		in_dataview_sid, in_start_dtm, in_end_dtm
	);
END;

END;
/
