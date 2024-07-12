CREATE OR REPLACE PACKAGE BODY CSR.templated_report_pkg AS

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
BEGIN
	NULL;
END;

PROCEDURE UNSEC_DeleteAllTags(
	in_sid_id		IN	security_pkg.T_SID_ID
) AS
BEGIN
	-- clear out eval condition tags
	DELETE FROM tpl_report_tag_eval_cond
	 WHERE tpl_report_tag_eval_id IN (
		SELECT rt.tpl_report_tag_eval_id
		  FROM tpl_report_tag_eval te, tpl_report_tag rt
		 WHERE te.tpl_report_tag_eval_id = rt.tpl_report_tag_eval_id
		   AND tpl_report_sid = in_sid_id
	 );

	DELETE FROM tpl_report_tag_eval
	 WHERE tpl_report_tag_eval_id IN (
		SELECT tpl_report_tag_eval_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );

	-- clear out dataview tags
	DELETE FROM tpl_report_tag_dv_region
	 WHERE tpl_report_tag_dataview_id IN (
		SELECT rt.tpl_report_tag_dataview_id
		  FROM tpl_report_tag_dataview td, tpl_report_tag rt
		 WHERE td.tpl_report_tag_dataview_id = rt.tpl_report_tag_dataview_id
		   AND tpl_report_sid = in_sid_id
	 );

	DELETE FROM tpl_report_tag_dataview
	 WHERE tpl_report_tag_dataview_id IN (
		SELECT tpl_report_tag_dataview_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );

	-- clear out logging form tags
	DELETE FROM tpl_report_Tag_logging_form
	 WHERE tpl_report_tag_logging_form_id IN (
		SELECT tpl_report_tag_logging_form_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );


	-- clear out ind tags
	DELETE FROM tpl_report_tag_ind
	 WHERE tpl_report_tag_ind_id IN (
		SELECT tpl_report_tag_ind_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );


	-- clear out text tags
	DELETE FROM tpl_report_tag_text
	 WHERE tpl_report_tag_text_id IN (
		SELECT tpl_report_tag_text_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );
	
	-- clear out approval note tags
	DELETE FROM tpl_report_tag_approval_note
	 WHERE tpl_report_tag_app_note_id IN (
		SELECT tpl_report_tag_app_note_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );
	 
	-- clear out approval note tags
	DELETE FROM tpl_report_tag_approval_matrix
	 WHERE tpl_report_tag_app_matrix_id IN (
		SELECT tpl_report_tag_app_matrix_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );

	-- clear out region data tags
	DELETE FROM tpl_report_tag_reg_data
	 WHERE tpl_report_tag_reg_data_id IN (
		SELECT tpl_report_tag_reg_data_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );

	-- clear out quick chart tags
	DELETE FROM tpl_report_tag_qchart
	WHERE tpl_report_tag_qchart_id IN (
		SELECT tpl_report_tag_qc_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
	 );

	-- clear out report tag
	DELETE FROM tpl_report_tag
	 WHERE tpl_report_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
) AS
BEGIN
	UNSEC_DeleteAllTags(in_sid_id);

	UPDATE approval_dashboard
	   SET tpl_report_sid = NULL
	 WHERE tpl_report_sid = in_sid_id;
	
	DELETE FROM TPL_REPORT
	 WHERE tpl_report_sid = in_sid_id;

    csr_data_pkg.WriteAuditLogEntry(
        security_pkg.GetAct(), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_sid_id,
        'Templated report deleted');
END;

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE tpl_report
	   SET parent_sid = in_new_parent_sid_id
	 WHERE tpl_report_sid= in_sid_id;
END;

PROCEDURE UNSEC_DeleteTag(
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE
)
AS
	v_tpl_report_tag_eval_id		tpl_report_tag.tpl_report_tag_eval_id%TYPE;
	v_tpl_report_tag_ind_id			tpl_report_tag.tpl_report_tag_ind_id%TYPE;
	v_tpl_report_tag_dataview_id	tpl_report_tag.tpl_report_tag_dataview_id%TYPE;
	v_tpl_report_tag_text_id		tpl_report_tag.tpl_report_tag_text_id%TYPE;
	v_tpl_report_tag_app_note_id	tpl_report_tag.tpl_report_tag_app_note_id%TYPE;
	v_tpl_report_tag_reg_data_id	tpl_report_tag.tpl_report_tag_reg_data_id%TYPE;
	v_tpl_report_tag_qc_id			tpl_report_tag.tpl_report_tag_qc_id%TYPE;
BEGIN
	BEGIN
		SELECT tpl_report_tag_eval_id, tpl_report_tag_ind_id, tpl_report_tag_dataview_id,
			   tpl_report_tag_text_id, tpl_report_tag_app_note_id, tpl_report_tag_reg_data_id,
			   tpl_report_tag_qc_id
		  INTO v_tpl_report_tag_eval_id, v_tpl_report_tag_ind_id, v_tpl_report_tag_dataview_id,
			   v_tpl_report_tag_text_id, v_tpl_report_tag_app_note_id, v_tpl_report_tag_reg_data_id,
			   v_tpl_report_tag_qc_id
		  FROM tpl_report_tag
		 WHERE tpl_report_sid = in_sid_id
		   AND tag = in_tag;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- doesn't exist which is ok
			RETURN;
	END;

	-- clear out report tag
	DELETE FROM tpl_report_tag
	 WHERE tpl_report_sid = in_sid_id
	   AND tag = in_tag;

	-- clear out eval condition tags
	DELETE FROM tpl_report_tag_eval_cond
	 WHERE tpl_report_tag_eval_id = v_tpl_report_tag_eval_id;

	DELETE FROM tpl_report_tag_eval
	 WHERE tpl_report_tag_eval_id = v_tpl_report_tag_eval_id;

	-- clear out dataview tags
	DELETE FROM tpl_report_tag_dv_region
	 WHERE tpl_report_tag_dataview_id = v_tpl_report_tag_dataview_id;

	DELETE FROM tpl_report_tag_dataview
	 WHERE tpl_report_tag_dataview_id = v_tpl_report_tag_dataview_id;

	-- clear out ind tags
	DELETE FROM tpl_report_tag_ind
	 WHERE tpl_report_tag_ind_id = v_tpl_report_tag_ind_id;

	-- clear out text tags
	DELETE FROM tpl_report_tag_text
	 WHERE tpl_report_tag_text_id = v_tpl_report_tag_text_id;

	-- clear out approval note tags
	DELETE FROM tpl_report_tag_approval_note
	 WHERE tpl_report_tag_app_note_id = v_tpl_report_tag_app_note_id;

	-- clear out region data tags
	DELETE FROM tpl_report_tag_reg_data
	 WHERE tpl_report_tag_reg_data_id = v_tpl_report_tag_reg_data_id;

	-- clear out quick chart tags
	DELETE FROM tpl_report_tag_qchart
	 WHERE tpl_report_tag_qchart_id = v_tpl_report_tag_qc_id;
END;

PROCEDURE SetTemplateFromCache(
	in_cache_key					IN	aspen2.filecache.cache_key%type,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
)
AS
	v_templated_reports_sid		security_pkg.T_SID_ID;
BEGIN
	v_templated_reports_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/TemplatedReports');
	SetTemplateFromCache(in_cache_key, in_name, in_description, in_period_set_id, in_period_interval_id, v_templated_reports_sid, out_templated_report_sid);
END;

PROCEDURE SetTemplateFromCache(
	in_cache_key					IN	aspen2.filecache.cache_key%type,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
)
AS
	v_word_doc			tpl_report.word_doc%TYPE;
	v_filename			aspen2.filecache.filename%TYPE;
BEGIN
	BEGIN
		SELECT object, filename
		  INTO v_word_doc, v_filename
		  FROM aspen2.filecache
		 WHERE cache_key = in_cache_key;
	EXCEPTION
		WHEN no_data_found THEN
			-- pah! not found
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END;

	SetTemplate(
		in_name 				=> in_name,
		in_description 			=> in_description,
		in_period_set_id 		=> in_period_set_id,
		in_period_interval_id	=> in_period_interval_id,
		in_parent_sid 			=> in_parent_sid,
		in_word_doc 			=> v_word_doc,
		in_filename				=> v_filename,
		out_templated_report_sid=> out_templated_report_sid
	);
END;

PROCEDURE SetTemplate(
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	in_parent_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_word_doc						IN	tpl_report.word_doc%TYPE,
	in_filename						IN	aspen2.filecache.filename%TYPE,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct();
	v_app_id						security_pkg.T_SID_ID := security_pkg.GetApp();
	v_parent_sid					security_pkg.T_SID_ID;
BEGIN

	v_parent_sid := NVL(in_parent_sid, SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/TemplatedReports'));

	SecurableObject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid, class_pkg.GetClassID('CSRTemplatedReport'), REPLACE(in_name,'/','\'), out_templated_report_sid); --'

	INSERT INTO tpl_report (
		tpl_report_sid, parent_sid, filename, word_doc, name,
		description, app_sid, period_set_id, period_interval_id
	)
	VALUES (
		out_templated_report_sid, v_parent_sid, in_filename, in_word_doc, in_name,
			in_description, SYS_CONTEXT('SECURITY','APP'), in_period_set_id, in_period_interval_id
	);

	csr_data_pkg.AuditValueChange(
		v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_id,
		out_templated_report_sid, 'Description', null, in_description);

	csr_data_pkg.AuditValueChange(
		v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_id,
		out_templated_report_sid, 'Name', null, in_name);

	csr_data_pkg.WriteAuditLogEntry(
		security_pkg.GetAct(), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), out_templated_report_sid,
		'Templated report created');
END;

PROCEDURE CopyTemplate(
	in_from_tpl_report_sid			IN	security_pkg.T_SID_ID,
	in_tpl_folder_sid				IN	security_pkg.T_SID_ID,
	in_new_name						IN	tpl_report.name%TYPE,
	out_to_tpl_report_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_dummy						NUMBER(10);
	v_temp						NUMBER(10);
BEGIN
	-- Security check on reading the report to copy from
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_from_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied copying template.');
	END IF;

	-- This does security check on creating reports
	SecurableObject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), in_tpl_folder_sid, class_pkg.GetClassID('CSRTemplatedReport'), REPLACE(in_new_name,'/','\'), out_to_tpl_report_sid);--'

	-- Copy basic properties and template document
	INSERT INTO tpl_report (tpl_report_sid, parent_sid, filename, word_doc, name, description, 
		period_set_id, period_interval_id, thumb_img)
		SELECT out_to_tpl_report_sid, in_tpl_folder_sid, filename, word_doc, in_new_name, 
			   description, period_set_id, period_interval_id, thumb_img
		  FROM tpl_report
		 WHERE tpl_report_sid = in_from_tpl_report_sid;
	
	-- Copy ind tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_ind_id, rti.ind_sid sid, rti.month_offset,
			   rti.period_set_id, rti.period_interval_id, rti.measure_conversion_id, rti.format_mask, rti.show_full_path
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_ind rti ON rt.tpl_report_tag_ind_id = rti.tpl_report_tag_ind_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagInd(out_to_tpl_report_sid, t.tag, t.tag_type, t.sid, t.month_offset,
			t.period_set_id, t.period_interval_id, t.measure_conversion_id, t.format_mask, t.show_full_path, v_dummy);
	END LOOP;

	-- Copy dataview tags
	FOR t IN (
		SELECT rt.tag, rtd.tpl_report_tag_dataview_id, rt.tag_type,
			   NVL(rtd.dataview_sid, rtd.saved_filter_sid) dataview_sid, rtd.month_offset,
			   rtd.month_duration, rtd.period_set_id, rtd.period_interval_id, rtd.hide_if_empty, 
			   rtd.split_table_by_columns, rtd.filter_result_mode, rtd.aggregate_type_id
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_dataview rtd ON rt.tpl_report_tag_dataview_id = rtd.tpl_report_tag_dataview_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagDataview(out_to_tpl_report_sid, t.tag, t.tag_type, t.dataview_sid, t.month_offset, t.month_duration, 
			t.period_set_id, t.period_interval_id, t.hide_if_empty, 
			t.split_table_by_columns, t.filter_result_mode, t.aggregate_type_id, NULL, NULL, v_temp);
		
		FOR tr IN (
			SELECT region_sid, tpl_region_type_id, filter_by_tag
			  FROM tpl_report_tag_dv_region rtr
			 WHERE tpl_report_tag_dataview_id = t.tpl_report_tag_dataview_id
		) LOOP
			UNSEC_InsertTagRegion(v_temp, t.dataview_sid, tr.region_sid, tr.tpl_region_type_id, tr.filter_by_tag);
		END LOOP;
	END LOOP;

	-- Copy eval tags
	FOR t IN (
		SELECT rt.tag, rte.if_true, rte.if_false, rte.all_must_be_true, rte.month_offset,
			   rte.period_set_id, rte.period_interval_id, rte.tpl_report_tag_eval_id
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_eval rte ON rt.tpl_report_tag_eval_id = rte.tpl_report_tag_eval_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagEval(out_to_tpl_report_sid, t.tag, t.all_must_be_true, t.if_true, t.if_false,
			t.month_offset, t.period_set_id, t.period_interval_id, v_temp);

		FOR tc IN (
			SELECT left_ind_sid, operator, right_ind_sid, right_value
			  FROM tpl_report_tag_eval_cond
			 WHERE tpl_report_tag_eval_id = t.tpl_report_tag_eval_id
		) LOOP
			UNSEC_InsertTagCondition(v_temp, tc.left_ind_sid, tc.operator, tc.right_ind_sid, tc.right_value);
		END LOOP;

	END LOOP;

	-- Copy logging form tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, rtl.tab_sid, rtl.month_offset, rtl.month_duration,
			   rtl.period_set_id, rtl.period_interval_id,
			   rtl.region_column_name, rtl.tpl_region_type_id, rtl.date_column_name,
			   NVL(rtl.form_sid, rtl.filter_sid) view_sid
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_logging_form rtl
		    ON rt.tpl_report_tag_logging_form_id = rtl.tpl_report_tag_logging_form_id
		   AND rt.app_sid = rtl.app_sid
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagLoggingForm(out_to_tpl_report_sid, t.tag, t.tag_type, t.tab_sid, t.month_offset,
			t.month_duration, t.period_set_id, t.period_interval_id, t.region_column_name, 
			t.tpl_region_type_id, t.date_column_name, t.view_sid, v_dummy);
	END LOOP;

	-- Copy non-compliance tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, rnc.month_offset, rnc.month_duration, rnc.period_set_id,
			   rnc.period_interval_id, rnc.tpl_region_type_id, rnc.tag_id
		  FROM tpl_report_tag rt
		  JOIN tpl_report_non_compl rnc 
		    ON rt.tpl_report_non_compl_id = rnc.tpl_report_non_compl_id
		   AND rt.app_sid = rnc.app_sid
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagNonCompliance(out_to_tpl_report_sid, t.tag, t.tag_type, t.month_offset,
			t.month_duration, t.period_set_id, t.period_interval_id, t.tpl_region_type_id,
			t.tag_id, v_dummy);
	END LOOP;
	
	-- Copy custom tags (but still need to call custom helper_pkg)
	FOR t IN (
		SELECT rt.tag, rt.tag_type, rt.tpl_rep_cust_tag_type_id, ct.helper_pkg
		  FROM tpl_report_tag rt
		  JOIN tpl_rep_cust_tag_type ct ON rt.tpl_rep_cust_tag_type_id = ct.tpl_rep_cust_tag_type_id and rt.app_sid = ct.app_sid
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagCustom(out_to_tpl_report_sid, t.tag, t.tpl_rep_cust_tag_type_id);
		-- TODO: Should add a call to t.helper_pkg to copy custom data
	END LOOP;

	-- Copy text tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_text_id, rtt.label
		  FROM tpl_report_tag rt
			JOIN tpl_report_tag_text rtt ON rt.tpl_report_tag_text_id = rtt.tpl_report_tag_text_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagText(out_to_tpl_report_sid, t.tag, t.tag_type, t.label, v_dummy);
	END LOOP;
	
	-- Copy approval note tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, trtan.tab_portlet_id, trtan.approval_dashboard_sid
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_approval_note trtan ON rt.tpl_report_tag_app_note_id = trtan.tpl_report_tag_app_note_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagApprovalNote(out_to_tpl_report_sid, t.tag, t.tag_type, t.tab_portlet_id, t.approval_dashboard_sid, v_dummy);
	END LOOP;

	-- Copy region data tags
	FOR t IN (
		SELECT rt.tag, rt.tag_type, trtrd.tpl_report_reg_data_type_id
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_reg_data trtrd ON rt.tpl_report_tag_reg_data_id = trtrd.tpl_report_tag_reg_data_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagRegionData(out_to_tpl_report_sid, t.tag, t.tag_type, t.tpl_report_reg_data_type_id, v_dummy);
	END LOOP;

		-- Copy QuickChart 
	FOR t IN (
		SELECT rt.tag, rtqc.tpl_report_tag_qchart_id, rt.tag_type,
			  rtqc.saved_filter_sid, rtqc.month_offset,
			   rtqc.month_duration, rtqc.period_set_id, rtqc.period_interval_id, rtqc.hide_if_empty, 
			   rtqc.split_table_by_columns
		  FROM tpl_report_tag rt
		  JOIN tpl_report_tag_qchart rtqc ON rt.tpl_report_tag_dataview_id = rtqc.tpl_report_tag_qchart_id
		 WHERE rt.tpl_report_sid = in_from_tpl_report_sid
	) LOOP
		SetTagQuickChart(out_to_tpl_report_sid, t.tag, t.tag_type, t.saved_filter_sid, t.month_offset, t.month_duration, 
			t.period_set_id, t.period_interval_id, t.hide_if_empty, 
			t.split_table_by_columns, v_temp);
	END LOOP;
END;

PROCEDURE UpdateTemplate(
	in_tpl_report_sid				IN 	security_pkg.T_SID_ID,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE
)
AS
    CURSOR current_cursor IS 
        SELECT app_sid, name, description, period_set_id, period_interval_id
          FROM tpl_report 
         WHERE tpl_report_sid = in_tpl_report_sid
           FOR UPDATE;
    v_current_row                   current_cursor%ROWTYPE;
    v_act_id                        security_pkg.T_ACT_ID := security_pkg.GetAct();
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating template.');
	END IF;

    OPEN current_cursor;
    FETCH current_cursor INTO v_current_row;

    csr_data_pkg.WriteAuditLogEntry(
        security_pkg.GetAct(), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_tpl_report_sid,
        'Templated report modified');

    csr_data_pkg.AuditValueChange(
        v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_current_row.app_sid, 
        in_tpl_report_sid, 'Description', v_current_row.description, in_description);

    csr_data_pkg.AuditValueChange(
        v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_current_row.app_sid, 
        in_tpl_report_sid, 'Name', v_current_row.name, in_name);

    csr_data_pkg.AuditValueChange(
        v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_current_row.app_sid, 
        in_period_set_id, 'Period set', v_current_row.period_set_id, in_name);

    csr_data_pkg.AuditValueChange(
        v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_current_row.app_sid, 
        in_period_set_id, 'Period interval', v_current_row.period_set_id, in_name);

	UPDATE tpl_report
	   SET name = in_name,
		   description = in_description,
		   period_set_id = in_period_set_id,
		   period_interval_id = in_period_interval_id
	 WHERE CURRENT OF current_cursor;

    CLOSE current_cursor;

	securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, REPLACE(in_name,'/','\'));--'
END;

PROCEDURE SaveTemplateThumb(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_data							IN tpl_report.thumb_img%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		-- ok -- no matter -- maybe they're read only so just bail out
		RETURN;
	END IF;

	UPDATE tpl_report
	   SET thumb_img = in_data
	 WHERE tpl_report_sid = in_tpl_report_sid;
END;

PROCEDURE ChangeTemplate(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_cache_key					IN	aspen2.filecache.cache_key%type
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing template.');
	END IF;

    csr_data_pkg.WriteAuditLogEntry(
        security_pkg.GetAct(), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_tpl_report_sid,
        'Template document changed');

	-- update word doc
	UPDATE tpl_report
	   SET (word_doc, filename) = (
			SELECT object, filename
			  FROM aspen2.filecache
			 WHERE cache_key = in_cache_key
		 )
 	WHERE tpl_report_sid = in_tpl_report_sid;

	-- clean all tags, they'll got populated again in a second as per ashx page.
	-- The ASHX page will have sent back updated tags, so even if it's a small
	-- change in the document it'll repopulate correctly
	UNSEC_DeleteAllTags(in_tpl_report_sid);
END;

PROCEDURE GetImgKeys(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'),
		securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'TemplatedReports'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading TemplatedReports object.');
	END IF;

	UNSEC_GetImgKeys(out_cur);
END;

PROCEDURE UNSEC_GetImgKeys(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT key, path, image
		  FROM tpl_img
		 WHERE app_Sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetTemplate(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	tpl_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting template.');
	END IF;

	UNSEC_GetTemplate(in_tpl_report_sid, tpl_cur);
END;

PROCEDURE UNSEC_GetTemplate(
	in_tpl_report_sid	IN security_pkg.T_SID_ID,
	tpl_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN tpl_cur FOR
		SELECT tpl_report_sid, parent_sid, name, description, filename, word_doc, period_set_id, period_interval_id,
			   CASE WHEN thumb_img IS NOT NULL THEN 1 ELSE 0 END has_thumb
		  FROM tpl_report
		 WHERE tpl_report_sid = in_tpl_report_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetThumbnail(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	tpl_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting template thumbnail.');
	END IF;

	OPEN tpl_cur FOR
		SELECT thumb_img
	   	  FROM tpl_report
		 WHERE tpl_report_sid = in_tpl_report_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetTemplateList(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_templated_reports_sid		security_pkg.T_SID_ID;
BEGIN
	v_templated_reports_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/TemplatedReports');

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_templated_reports_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tpl_report_sid, filename, period_set_id, period_interval_id, 
			  name, description, CASE WHEN thumb_img IS NOT NULL THEN 1 ELSE 0 END has_thumb
		  FROM tpl_report
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), tpl_report_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY name;
END;

PROCEDURE GetChildReports(
	in_parent_sid					IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tpl_report_sid, parent_sid, filename, period_set_id, period_interval_id,
			   name, description, CASE WHEN thumb_img IS NOT NULL THEN 1 ELSE 0 END has_thumb
		  FROM tpl_report
		 WHERE parent_sid = in_parent_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), tpl_report_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY name;
END;

PROCEDURE GetTags(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_unmapped_cur			OUT SYS_REFCURSOR,
	out_ind_cur					OUT SYS_REFCURSOR,
	out_dataview_cur			OUT SYS_REFCURSOR,
	out_cond_cur				OUT SYS_REFCURSOR,
	out_logng_form_cur			OUT SYS_REFCURSOR,
	out_custom_cur				OUT SYS_REFCURSOR,
	out_text_cur				OUT SYS_REFCURSOR,
	out_non_compl_cur			OUT SYS_REFCURSOR,
	out_app_note_cur			OUT SYS_REFCURSOR,
	out_app_matrix_cur			OUT SYS_REFCURSOR,
	out_region_data_cur			OUT SYS_REFCURSOR,
	out_quick_chart_data_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting template.');
	END IF;
	
	UNSEC_GetTags(in_tpl_report_sid, out_unmapped_cur, out_ind_cur, out_dataview_cur, out_cond_cur, out_logng_form_cur, out_custom_cur, out_text_cur, out_non_compl_cur, out_app_note_cur, out_app_matrix_cur, out_region_data_cur, out_quick_chart_data_cur);
END;

PROCEDURE UNSEC_GetTags(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_unmapped_cur			OUT SYS_REFCURSOR,
	out_ind_cur					OUT SYS_REFCURSOR,
	out_dataview_cur			OUT SYS_REFCURSOR,
	out_cond_cur				OUT SYS_REFCURSOR,
	out_logng_form_cur			OUT SYS_REFCURSOR,
	out_custom_cur				OUT SYS_REFCURSOR,
	out_text_cur				OUT SYS_REFCURSOR,
	out_non_compl_cur			OUT SYS_REFCURSOR,
	out_app_note_cur			OUT SYS_REFCURSOR,
	out_app_matrix_cur			OUT SYS_REFCURSOR,
	out_region_data_cur			OUT SYS_REFCURSOR,
	out_quick_chart_data_cur	OUT SYS_REFCURSOR
)
AS
	v_ind_root_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;

	OPEN out_unmapped_cur FOR
		SELECT rt.tag, rt.tag_type
		  FROM tpl_report_tag rt
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
			-- don't forget to add to this list!
		   AND tpl_report_tag_ind_id IS NULL
		   AND tpl_report_tag_dataview_id IS NULL
		   AND tpl_report_tag_eval_id IS NULL
		   AND tpl_report_tag_logging_form_id IS NULL
		   AND tpl_rep_cust_tag_type_id IS NULL
		   AND tpl_report_tag_text_id IS NULL
		   AND tpl_report_non_compl_id IS NULL
		   AND tpl_report_tag_reg_data_id IS NULL
		 ORDER BY tag;

	OPEN out_ind_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_ind_id, i.ind_sid sid, i.description,
			   ip.path, -- if path is null, ind is trashed, dealt with in the cs.
			   rti.month_offset,
			   NVL(rti.period_set_id, r.period_set_id) period_set_id,
			   NVL(rti.period_interval_id, r.period_interval_id) period_interval_id,
			   i.measure_sid, rti.measure_conversion_id, rti.format_mask, rti.show_full_path
		  FROM tpl_report r
		  JOIN tpl_report_tag rt ON r.tpl_report_sid = rt.tpl_report_sid
		  JOIN tpl_report_tag_ind rti ON rt.tpl_report_tag_ind_id = rti.tpl_report_tag_ind_id
		  JOIN v$ind i ON rti.ind_sid = i.ind_sid
		  LEFT JOIN (SELECT x.ind_sid, REPLACE(SUBSTR(SYS_CONNECT_BY_PATH(REPLACE(x.description, CHR(1), '_'), ''), 2), '', ' / ') path
				   FROM v$ind x
				  START WITH parent_sid = v_ind_root_sid
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
		  )ip ON rti.ind_sid = ip.ind_sid
		 WHERE r.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_dataview_cur FOR
		SELECT rt.tag, rt.tag_type, NVL(rtd.dataview_sid, rtd.saved_filter_sid) dataview_sid, 
			   COALESCE(dv.name, sf.name, dvt.description) description, rrm.region_sid, NVL(drd.description, vr.description) region_description,
               trt.tpl_region_type_id, trt.label tpl_region_type_label,
			   rtd.month_offset, rtd.month_duration,
			   NVL(rtd.period_set_id, r.period_set_id) period_set_id,
			   NVL(rtd.period_interval_id, r.period_interval_id) period_interval_id,
			   rtr.filter_by_tag, rtd.hide_if_empty, rtd.split_table_by_columns,
			   rtd.filter_result_mode, rtd.aggregate_type_id, sf.card_group_id, sf.company_sid,
			   rtd.approval_dashboard_sid, rtd.ind_tag, NVL(dv.parent_sid, sf.parent_sid) parent_folder_sid
		  FROM tpl_report r
		  JOIN tpl_report_tag rt ON r.tpl_report_sid = rt.tpl_report_sid
          JOIN tpl_report_tag_dataview rtd ON rt.tpl_report_tag_dataview_id = rtd.tpl_report_tag_dataview_id
          LEFT JOIN dataview dv ON rtd.dataview_sid = dv.dataview_sid
          LEFT JOIN csr.trash dvt ON rtd.dataview_sid = dvt.trash_sid
          LEFT JOIN dataview_region_member rrm ON dv.dataview_sid = rrm.dataview_sid
          LEFT JOIN dataview_region_description drd ON rrm.app_sid = drd.app_sid AND rrm.dataview_sid = drd.dataview_sid AND rrm.region_sid = drd.region_sid
           AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANG'), 'en')
          LEFT JOIN v$region vr ON rrm.region_sid = vr.region_sid
          LEFT JOIN tpl_report_tag_dv_region rtr
            ON rtd.tpl_report_tag_dataview_id = rtr.tpl_report_tag_dataview_id
           AND rrm.dataview_sid = rtr.dataview_sid
           AND rrm.region_sid = rtr.region_sid
          LEFT JOIN tpl_region_type trt ON rtr.tpl_region_type_id = trt.tpl_region_type_id
		  LEFT JOIN chain.saved_filter sf ON rtd.saved_filter_sid = sf.saved_filter_sid
		 WHERE r.tpl_report_sid = in_tpl_report_sid
		 ORDER BY rt.tag, rrm.pos;

	OPEN out_cond_cur FOR
		SELECT rt.tag, rt.tag_type, rtec.left_ind_sid, rtec.OPERATOR, rtec.right_value, rtec.right_ind_sid,
               rte.if_true, rte.if_false, rte.all_must_be_true, il.description left_ind_description,
               ir.description right_ind_description, rte.month_offset, 
               NVL(rte.period_set_id, r.period_set_id) period_set_id,
			   NVL(rte.period_interval_id, r.period_interval_id) period_interval_id
		  FROM tpl_report r
		  JOIN tpl_report_tag rt  ON r.tpl_report_sid = rt.tpl_report_sid
          JOIN tpl_report_tag_eval rte ON rt.tpl_report_tag_eval_id = rte.tpl_report_tag_eval_id
          JOIN tpl_report_tag_eval_cond rtec ON rte.tpl_report_tag_eval_id = rtec.tpl_report_tag_eval_id
          JOIN v$ind il ON rtec.left_ind_sid = il.ind_sid
          LEFT JOIN v$ind ir ON rtec.right_ind_sid = ir.ind_sid
         WHERE r.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_logng_form_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_logging_form_id, t.tab_sid,
			   NVL(t.description, t.oracle_table) description, rtl.month_offset, rtl.month_duration,
			   NVL(rtl.period_set_id, r.period_set_id) period_set_id,
			   NVL(rtl.period_interval_id, r.period_interval_id) period_interval_id,
			   rtl.region_column_name, rtl.tpl_region_type_id, rtl.date_column_name,
			   NVL(rtl.saved_filter_sid, NVL(rtl.form_sid, rtl.filter_sid)) view_sid,
			   NVL(frm.form_xml, fil.filter_xml) view_xml,
			   CASE WHEN rtl.saved_filter_sid IS NOT NULL THEN 1 ELSE 0 END is_saved_filter,
			   rtc.column_sid region_column_sid, dtc.column_sid date_column_sid
		  FROM tpl_report r
		  JOIN tpl_report_tag rt ON r.tpl_report_sid = rt.tpl_report_sid
          JOIN tpl_report_tag_logging_form rtl ON rt.tpl_report_tag_logging_form_id = rtl.tpl_report_tag_logging_form_id AND rt.app_sid = rtl.app_sid
          JOIN cms.tab t ON rtl.tab_sid = t.tab_sid and rtl.app_sid = t.app_sid
          LEFT JOIN cms.v$form frm ON rtl.form_sid = frm.form_sid
          LEFT JOIN cms.filter fil ON rtl.filter_sid = fil.filter_sid
          LEFT JOIN cms.tab_column rtc ON rtl.tab_sid = rtc.tab_sid AND rtl.region_column_name = rtc.oracle_column
          LEFT JOIN cms.tab_column dtc ON rtl.tab_sid = dtc.tab_sid AND rtl.date_column_name = dtc.oracle_column
		 WHERE r.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_custom_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_rep_cust_tag_type_id, ct.cs_class, ct.js_include, ct.js_class, ct.description
		  FROM tpl_report_tag rt
		  JOIN tpl_rep_cust_tag_type ct ON rt.tpl_rep_cust_tag_type_id = ct.tpl_rep_cust_tag_type_id and rt.app_sid = ct.app_sid
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_text_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_text_id, rtt.label
		  FROM tpl_report_tag rt
          JOIN tpl_report_tag_text rtt ON rt.tpl_report_tag_text_id = rtt.tpl_report_tag_text_id
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_non_compl_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_non_compl_id, rtnc.month_offset,
			   rtnc.month_duration, NVL(rtnc.period_set_id, r.period_set_id) period_set_id,
			   NVL(rtnc.period_interval_id, r.period_interval_id) period_interval_id, rtnc.tpl_region_type_id, tag_id
		  FROM tpl_report r
		  JOIN tpl_report_tag rt ON r.tpl_report_sid = rt.tpl_report_sid AND r.app_sid = rt.app_sid
          JOIN tpl_report_non_compl rtnc ON rt.tpl_report_non_compl_id = rtnc.tpl_report_non_compl_id AND rt.app_sid = rtnc.app_sid
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;
	
	OPEN out_app_note_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_app_note_id, trtan.tab_portlet_id, trtan.approval_dashboard_sid
		  FROM tpl_report r
		  JOIN tpl_report_tag rt 			 		ON r.tpl_report_sid = rt.tpl_report_sid AND r.app_sid = rt.app_sid
		  JOIN tpl_report_tag_approval_note trtan 	ON rt.tpl_report_tag_app_note_id = trtan.tpl_report_tag_app_note_id AND rt.app_sid = trtan.app_sid
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;
	
	OPEN out_app_matrix_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_app_matrix_id, trtam.approval_dashboard_sid
		  FROM tpl_report r
		  JOIN tpl_report_tag rt 			 		ON r.tpl_report_sid = rt.tpl_report_sid AND r.app_sid = rt.app_sid
		  JOIN tpl_report_tag_approval_matrix trtam ON rt.tpl_report_tag_app_matrix_id = trtam.tpl_report_tag_app_matrix_id AND rt.app_sid = trtam.app_sid
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_region_data_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_reg_data_id, trrdt.tpl_report_reg_data_type_id, trrdt.description
		  FROM tpl_report r
		  JOIN tpl_report_tag rt 			 		ON r.tpl_report_sid = rt.tpl_report_sid AND r.app_sid = rt.app_sid
		  JOIN tpl_report_tag_reg_data trtrd 		ON rt.tpl_report_tag_reg_data_id = trtrd.tpl_report_tag_reg_data_id AND rt.app_sid = trtrd.app_sid
		  JOIN tpl_report_reg_data_type trrdt       ON trtrd.tpl_report_reg_data_type_id = trrdt.tpl_report_reg_data_type_id
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;

	OPEN out_quick_chart_data_cur FOR
		SELECT rt.tag, rt.tag_type, rt.tpl_report_tag_qc_id,trtqc.saved_filter_sid,
			   trtqc.month_offset, trtqc.month_duration,
			   trtqc.hide_if_empty, trtqc.split_table_by_columns,
			    sf.card_group_id, sf.company_sid,
		  NVL(trtqc.period_set_id, r.period_set_id) period_set_id,
			   NVL(trtqc.period_interval_id, r.period_interval_id) period_interval_id, sf.Name Description
		  FROM tpl_report r
		  JOIN tpl_report_tag rt ON r.tpl_report_sid = rt.tpl_report_sid AND r.app_sid = rt.app_sid
		  JOIN tpl_report_tag_qchart trtqc ON rt.tpl_report_tag_qc_id = trtqc.tpl_report_tag_qchart_id AND rt.app_sid = trtqc.app_sid
	 LEFT JOIN chain.saved_filter sf ON trtqc.saved_filter_sid = sf.saved_filter_sid
		 WHERE rt.tpl_report_sid = in_tpl_report_sid
		 ORDER BY tag;
END;

PROCEDURE GetTagNames(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT tag 
		  FROM TPL_REPORT_TAG 
		 WHERE tpl_report_sid = in_tpl_report_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE SetTagUnmapped(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type
		) VALUES (
			in_tpl_report_sid, v_tag, templated_report_pkg.TPL_RPT_TAG_TYPE_UNMAPPED
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UNSEC_DeleteTag(in_tpl_report_sid, in_tag);
			SetTagUnmapped(in_tpl_report_sid, in_tag);
			RETURN;
	END;
END;

PROCEDURE SetTagInd(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_ind.month_offset%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_measure_conversion_id		IN	tpl_report_tag_ind.measure_conversion_id%TYPE,
	in_format_mask					IN	tpl_report_tag_ind.format_mask%TYPE,
	in_show_full_path				IN	tpl_report_tag_ind.show_full_path%TYPE,
	out_tpl_report_tag_ind_id		OUT	tpl_report_tag_ind.tpl_report_tag_ind_id%TYPE
)
AS
	v_tag						tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_ind_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_ind_id_seq.nextval
		) RETURNING tpl_report_tag_ind_id INTO out_tpl_report_tag_ind_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_ind_id
			  INTO out_tpl_report_tag_ind_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;

			IF out_tpl_report_tag_ind_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagInd(in_tpl_report_sid, in_tag, in_tag_type, in_ind_sid, in_month_offset, 
					in_period_set_id, in_period_interval_id, in_measure_conversion_id,
					in_format_mask, in_show_full_path, out_tpl_report_tag_ind_id);
				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;

	BEGIN
		INSERT INTO tpl_report_tag_ind (
			tpl_report_tag_ind_id, ind_sid, month_offset, period_set_id, period_interval_id,
			measure_conversion_id, format_mask, show_full_path
		) VALUES (
			out_tpl_report_tag_ind_id, in_ind_sid, in_month_offset, in_period_set_id,
			in_period_interval_id, in_measure_conversion_id, in_format_mask, in_show_full_path
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_ind
			   SET ind_sid = in_ind_sid,
				   month_offset = in_month_offset,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id,
				   measure_conversion_id = in_measure_conversion_id,
				   format_mask = in_format_mask,
				   show_full_path = in_show_full_path
			 WHERE tpl_report_tag_ind_id = out_tpl_report_tag_ind_id;
	END;
END;

PROCEDURE SetTagEval(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_all_must_be_true	 			IN	tpl_report_tag_eval.all_must_be_true%TYPE,
	in_if_true						IN	tpl_report_tag_eval.if_true%TYPE,
	in_if_false						IN	tpl_report_tag_eval.if_false%TYPE,
	in_month_offset					IN	tpl_report_tag_eval.month_offset%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	out_tpl_report_tag_eval_id		OUT	tpl_report_tag_eval.tpl_report_tag_eval_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_eval_id
		) VALUES (
			in_tpl_report_sid, v_tag, templated_report_pkg.TPL_RPT_TAG_TYPE_IND_COND, tpl_report_tag_eval_id_seq.nextval
		) RETURNING tpl_report_tag_eval_id INTO out_tpl_report_tag_eval_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_eval_id
			  INTO out_tpl_report_tag_eval_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;

			IF out_tpl_report_tag_eval_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagEval(in_tpl_report_sid, in_tag, in_all_must_be_true, in_if_true, in_if_false,
					in_month_offset, in_period_set_id, in_period_interval_id, out_tpl_report_tag_eval_id);
				RETURN;
			END IF;
	END;

	BEGIN
		INSERT INTO tpl_report_tag_eval (
			tpl_report_tag_eval_id, if_true, if_false, all_must_be_true, month_offset,
			period_set_id, period_interval_id
		) VALUES (
			out_tpl_report_tag_eval_id, in_if_true, in_if_false, in_all_must_be_true,
			in_month_offset, in_period_set_id, in_period_interval_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_Tag_eval
			   SET if_true = in_if_true,
				   if_false = in_if_false,
				   all_must_be_true = in_all_must_be_true,
				   month_offset = in_month_offset,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id
			 WHERE tpl_report_tag_eval_id = out_tpl_report_tag_eval_id;

			-- clean child table
			DELETE FROM tpl_report_tag_eval_cond
			 WHERE tpl_report_tag_eval_id = out_tpl_report_tag_eval_id;
	END;
END;

PROCEDURE SetTagDataview(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_dataview.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_dataview.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_hide_if_empty				IN	tpl_report_tag_dataview.hide_if_empty%TYPE,
	in_split_table_by_columns		IN	tpl_report_tag_dataview.split_table_by_columns%TYPE,
	in_filter_result_mode			IN	tpl_report_tag_dataview.filter_result_mode%TYPE,
	in_aggregate_type_id			IN	tpl_report_tag_dataview.aggregate_type_id%TYPE,
	in_approval_dashboard_sid		IN  tpl_report_tag_dataview.approval_dashboard_sid%TYPE			DEFAULT NULL,
	in_ind_tag						IN  tpl_report_tag_dataview.ind_tag%TYPE						DEFAULT NULL,
	out_tpl_report_tag_dataview_id	OUT	tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
	v_dataview_sid					security_pkg.T_SID_ID;
	v_saved_filter_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_dataview_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_dataview_id_seq.nextval
		) RETURNING tpl_report_tag_dataview_id INTO out_tpl_report_tag_dataview_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_dataview_id
			  INTO out_tpl_report_tag_dataview_id
			  FROM tpl_report_Tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;

			IF out_tpl_report_tag_dataview_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagDataview(in_tpl_report_sid, in_tag, in_tag_type, in_dataview_sid, in_month_offset,
					in_month_duration, in_period_set_id, in_period_interval_id, in_hide_if_empty, 
					in_split_table_by_columns, in_filter_result_mode, in_aggregate_type_id, NULL, NULL,
					out_tpl_report_tag_dataview_id);
				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;

	BEGIN
		-- See if its a dataview
		SELECT dv.dataview_sid
		  INTO v_dataview_sid
		  FROM dataview dv
		 WHERE dv.dataview_sid = in_dataview_sid;
	EXCEPTION
		WHEN no_data_found THEN
			-- not a dataview, try saved filter
			SELECT sf.saved_filter_sid
			  INTO v_saved_filter_sid
			  FROM chain.saved_filter sf
			 WHERE sf.saved_filter_sid = in_dataview_sid;	
	END;
	
	BEGIN
		INSERT INTO tpl_report_tag_dataview (
			tpl_report_tag_dataview_id, dataview_sid, month_offset, month_duration,
			period_set_id, period_interval_id, hide_if_empty, split_table_by_columns,
			filter_result_mode, aggregate_type_id, saved_filter_sid
		) VALUES (
			out_tpl_report_tag_dataview_id, v_dataview_sid, in_month_offset, in_month_duration, 
			in_period_set_id, in_period_interval_id, in_hide_if_empty, in_split_table_by_columns,
			in_filter_result_mode, in_aggregate_type_id, v_saved_filter_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- clear out child table
			DELETE FROM tpl_report_tag_dv_region
			 WHERE tpl_report_tag_dataview_id = out_tpl_report_tag_dataview_id;

			UPDATE tpl_report_tag_dataview
			   SET dataview_sid = v_dataview_sid,
			       saved_filter_sid = v_saved_filter_sid,
				   month_offset = in_month_offset,
				   month_duration = in_month_duration,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id,
				   hide_if_empty = in_hide_if_empty,
				   split_table_by_columns = in_split_table_by_columns,
				   filter_result_mode = in_filter_result_mode,
				   aggregate_type_id = in_aggregate_type_id
			 WHERE tpl_report_tag_dataview_id = out_tpl_report_tag_dataview_id;
	END;
END;

PROCEDURE SetTagCustom(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_custom_tag_type_id			IN	tpl_report_tag.tpl_rep_cust_tag_type_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
	v_custom_tag_type_id			tpl_report_tag.tpl_rep_cust_tag_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_rep_cust_tag_type_id
		) VALUES (
			in_tpl_report_sid, v_tag, templated_report_pkg.TPL_RPT_TAG_TYPE_CUSTOM, in_custom_tag_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_rep_cust_tag_type_id
			  INTO v_custom_tag_type_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag
			   AND app_sid = security_pkg.GetApp;

			IF v_custom_tag_type_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagCustom(in_tpl_report_sid, in_tag, in_custom_tag_type_id);
				RETURN;
			ELSE
				UPDATE tpl_report_tag
				   SET tag_type = templated_report_pkg.TPL_RPT_TAG_TYPE_CUSTOM,
				       tpl_rep_cust_tag_type_id = in_custom_tag_type_id
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag
				   AND app_sid = security_pkg.GetApp;
			END IF;
	END;
END;

PROCEDURE SetTagCustom(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_custom_tag_cs_class			IN	tpl_rep_cust_tag_type.cs_class%TYPE
)
AS
	v_tag_type_id					tpl_rep_cust_tag_type.tpl_rep_cust_tag_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	SELECT tpl_rep_cust_tag_type_id
	  INTO v_tag_type_id
	  FROM tpl_rep_cust_tag_type
	 WHERE app_sid = security_pkg.GetApp
	   AND cs_class = in_custom_tag_cs_class;

	SetTagCustom(in_tpl_report_sid, in_tag, v_tag_type_id);
END;

PROCEDURE SetTagLoggingForm(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tab_sid						IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_logging_form.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_logging_form.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_region_column_name			IN	tpl_report_tag_logging_form.region_column_name%TYPE,
	in_tpl_region_type_id			IN	tpl_report_tag_logging_form.tpl_region_type_id%TYPE,
	in_date_column_name				IN	tpl_report_tag_logging_form.date_column_name%TYPE,
	in_view_sid						IN	security_pkg.T_SID_ID,
	out_tpl_report_tag_lgng_frm_id	OUT	tpl_report_tag_logging_form.tpl_report_tag_logging_form_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
	v_form_sid						security_pkg.T_SID_ID;
	v_filter_sid					security_pkg.T_SID_ID;
	v_saved_filter_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_logging_form_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_logging_frm_seq.nextval
		) RETURNING tpl_report_tag_logging_form_id INTO out_tpl_report_tag_lgng_frm_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_logging_form_id
			  INTO out_tpl_report_tag_lgng_frm_id
			  FROM tpl_report_Tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag
			   AND app_sid = security_pkg.GetApp;

			IF out_tpl_report_tag_lgng_frm_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagLoggingForm(in_tpl_report_sid, in_tag, in_tag_type, in_tab_sid, in_month_offset,
					in_month_duration, in_period_set_id, in_period_interval_id, in_region_column_name,
					in_tpl_region_type_id, in_date_column_name, in_view_sid,
					out_tpl_report_tag_lgng_frm_id);
				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag
				   AND app_sid = security_pkg.GetApp;
			END IF;
	END;

	SELECT MIN(form_sid)
	  INTO v_form_sid
	  FROM cms.v$form
	 WHERE form_sid = in_view_sid;

	SELECT MIN(filter_sid)
	  INTO v_filter_sid
	  FROM cms.filter
	 WHERE filter_sid = in_view_sid;
	
	SELECT MIN(saved_filter_sid)
	  INTO v_saved_filter_sid
	  FROM chain.saved_filter
	 WHERE saved_filter_sid = in_view_sid;

	BEGIN
		INSERT INTO tpl_report_tag_logging_form (
			tpl_report_tag_logging_form_id, tab_sid, month_offset, month_duration, period_set_id,
			period_interval_id, region_column_name, tpl_region_type_id, date_column_name, form_sid,
			filter_sid, saved_filter_sid
		) VALUES (
			out_tpl_report_tag_lgng_frm_id, in_tab_sid, in_month_offset, in_month_duration,
			in_period_set_id, in_period_interval_id, in_region_column_name, in_tpl_region_type_id,
			in_date_column_name, v_form_sid, v_filter_sid, v_saved_filter_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_logging_form
			   SET tab_sid = in_tab_sid,
			       month_offset = in_month_offset,
			       month_duration = in_month_duration,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id,
			       region_column_name = in_region_column_name,
			       tpl_region_type_id = in_tpl_region_type_id,
			       date_column_name = in_date_column_name,
			       form_sid = v_form_sid,
			       filter_sid = v_filter_sid,
			       saved_filter_sid = v_saved_filter_sid
			 WHERE tpl_report_tag_logging_form_id = out_tpl_report_tag_lgng_frm_id
			   AND app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE SetTagNonCompliance(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_month_offset					IN	tpl_report_non_compl.month_offset%TYPE,
	in_month_duration				IN	tpl_report_non_compl.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_tpl_region_type_id			IN	tpl_report_non_compl.tpl_region_type_id%TYPE,
	in_tag_id						IN	tpl_report_non_compl.tag_id%TYPE,
	out_tpl_report_non_cmpl_id		OUT	tpl_report_non_compl.tpl_report_non_compl_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE := LOWER(in_tag); -- always make lower case
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_non_compl_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_non_compl_id_seq.nextval
		) RETURNING tpl_report_non_compl_id INTO out_tpl_report_non_cmpl_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_non_compl_id
			  INTO out_tpl_report_non_cmpl_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag
			   AND app_sid = security_pkg.GetApp;

			IF out_tpl_report_non_cmpl_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagNonCompliance(in_tpl_report_sid, in_tag, in_tag_type, in_month_offset,
					in_month_duration, in_period_set_id, in_period_interval_id,
					in_tpl_region_type_id, in_tag_id, out_tpl_report_non_cmpl_id);
				RETURN;
			ELSE
				UPDATE tpl_report_tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag
				   AND app_sid = security_pkg.GetApp;
			END IF;
	END;

	BEGIN
		INSERT INTO tpl_report_non_compl (
			tpl_report_non_compl_id, month_offset, month_duration, period_set_id,
			period_interval_id, tpl_region_type_id, tag_id
		) VALUES (
			out_tpl_report_non_cmpl_id, in_month_offset, in_month_duration,
			in_period_set_id, in_period_interval_id, in_tpl_region_type_id, in_tag_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_non_compl
			   SET period_set_id = in_period_set_id,
			   	   period_interval_id = in_period_interval_id,
			   	   month_offset = in_month_offset,
			       month_duration = in_month_duration,
			       tpl_region_type_id = in_tpl_region_type_id,
			       tag_id = in_tag_id
			 WHERE tpl_report_non_compl_id = out_tpl_report_non_cmpl_id
			   AND app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE SetTagText(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_label						IN	tpl_report_tag_text.label%TYPE,
	out_tpl_report_tag_text_id		OUT	tpl_report_tag_text.tpl_report_tag_text_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_text_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_text_id_seq.nextval
		) RETURNING tpl_report_tag_text_id INTO out_tpl_report_tag_text_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_text_id
			  INTO out_tpl_report_tag_text_id
			  FROM tpl_report_Tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;

			IF out_tpl_report_tag_text_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagText(in_tpl_report_sid, in_tag, in_tag_type, in_label, out_tpl_report_tag_text_id);
				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;

	BEGIN
		INSERT INTO tpl_report_tag_text (
			tpl_report_tag_text_id, label
		) VALUES (
			out_tpl_report_tag_text_id, in_label
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_text
			   SET label = in_label
			 WHERE tpl_report_tag_text_id = out_tpl_report_tag_text_id;
	END;
END;

PROCEDURE SetTagApprovalNote(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tab_portlet_id				IN  tpl_report_tag_approval_note.tab_portlet_id%TYPE,
	in_approval_dashboard_sid		IN	tpl_report_tag_approval_note.approval_dashboard_sid%TYPE,
	out_tpl_report_tag_app_note_id	OUT	tpl_report_tag_approval_note.tpl_report_tag_app_note_id%TYPE
)
AS
	v_tag								tpl_report_tag.tag%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);
	
	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_app_note_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_app_note_id_seq.nextval
		) RETURNING tpl_report_tag_app_note_id INTO out_tpl_report_tag_app_note_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_app_note_id 
			  INTO out_tpl_report_tag_app_note_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;
			 
			IF out_tpl_report_tag_app_note_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagApprovalNote(in_tpl_report_sid, in_tag, in_tag_type, in_tab_portlet_id, in_approval_dashboard_sid, out_tpl_report_tag_app_note_id);
				RETURN;
			ELSE
				UPDATE tpl_report_tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;
	
	BEGIN
		INSERT INTO tpl_report_tag_approval_note (
			tpl_report_tag_app_note_id, tab_portlet_id, approval_dashboard_sid
		) VALUES (
			out_tpl_report_tag_app_note_id, in_tab_portlet_id, in_approval_dashboard_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_approval_note
			   SET tab_portlet_id 			= in_tab_portlet_id,
				   approval_dashboard_sid 	= in_approval_dashboard_sid
			 WHERE tpl_report_tag_app_note_id = out_tpl_report_tag_app_note_id;
	END;

END;
	
PROCEDURE SetTagApprovalMatrix(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_approval_dashboard_sid		IN	tpl_report_tag_approval_matrix.approval_dashboard_sid%TYPE,
	out_tpl_rep_tag_app_mtx_id	OUT	tpl_report_tag_approval_matrix.tpl_report_tag_app_matrix_id%TYPE
)
AS
	v_tag								tpl_report_tag.tag%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);
	
	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_app_matrix_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_rep_tag_app_matrix_id_seq.nextval
		) RETURNING tpl_report_tag_app_matrix_id INTO out_tpl_rep_tag_app_mtx_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_app_matrix_id 
			  INTO out_tpl_rep_tag_app_mtx_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;
			 
			IF out_tpl_rep_tag_app_mtx_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagApprovalMatrix(in_tpl_report_sid, in_tag, in_tag_type, in_approval_dashboard_sid, out_tpl_rep_tag_app_mtx_id);
				RETURN;
			ELSE
				UPDATE tpl_report_tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;
	
	BEGIN
		INSERT INTO tpl_report_tag_approval_matrix (
			tpl_report_tag_app_matrix_id, approval_dashboard_sid
		) VALUES (
			out_tpl_rep_tag_app_mtx_id, in_approval_dashboard_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_approval_matrix
			   SET approval_dashboard_sid 	= in_approval_dashboard_sid
			 WHERE tpl_report_tag_app_matrix_id = out_tpl_rep_tag_app_mtx_id;
	END;
END;

PROCEDURE SetTagRegionData(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tpl_report_reg_data_type_id	IN	tpl_report_reg_data_type.tpl_report_reg_data_type_id%TYPE,
	out_tpl_report_tag_reg_data_id OUT	tpl_report_tag_reg_data.tpl_report_tag_reg_data_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_reg_data_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_reg_data_id_seq.nextval
		) RETURNING tpl_report_tag_reg_data_id INTO out_tpl_report_tag_reg_data_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_reg_data_id
			  INTO out_tpl_report_tag_reg_data_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;

			IF out_tpl_report_tag_reg_data_id IS NULL THEN
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid, v_tag);
				SetTagRegionData(in_tpl_report_sid, in_tag, in_tag_type, in_tpl_report_reg_data_type_id,
					out_tpl_report_tag_reg_data_id);
				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;

	BEGIN
		INSERT INTO tpl_report_tag_reg_data (
			tpl_report_tag_reg_data_id, tpl_report_reg_data_type_id
		) VALUES (
			out_tpl_report_tag_reg_data_id, in_tpl_report_reg_data_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_reg_data
			   SET tpl_report_reg_data_type_id = in_tpl_report_reg_data_type_id
			 WHERE tpl_report_tag_reg_data_id = out_tpl_report_tag_reg_data_id;
	END;
END;

PROCEDURE SetTagQuickChart(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_qchart.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_qchart.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_hide_if_empty				IN	tpl_report_tag_qchart.hide_if_empty%TYPE,
	in_split_table_by_columns		IN	tpl_report_tag_qchart.split_table_by_columns%TYPE,
	out_tpl_report_tag_qc_id		OUT	tpl_report_tag_qchart.tpl_report_tag_qchart_id%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_tag (
			tpl_report_sid, tag, tag_type, tpl_report_tag_qc_id
		) VALUES (
			in_tpl_report_sid, v_tag, in_tag_type, tpl_report_tag_qc_id_seq.nextval
		) RETURNING tpl_report_tag_qc_id INTO out_tpl_report_tag_qc_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT tpl_report_tag_qc_id
			  INTO out_tpl_report_tag_qc_id
			  FROM tpl_report_tag
			 WHERE tpl_report_sid = in_tpl_report_sid
			   AND tag = v_tag;
			
			IF out_tpl_report_tag_qc_id IS NULL THEN
				
				-- hmm -- they've changed the type
				UNSEC_DeleteTag(in_tpl_report_sid,v_tag);
				SetTagQuickChart(in_tpl_report_sid, in_tag, in_tag_type, in_saved_filter_sid, in_month_offset, in_month_duration, 
					in_period_set_id, in_period_interval_id, in_hide_if_empty, 
					in_split_table_by_columns, out_tpl_report_tag_qc_id);


				RETURN;
			ELSE
				UPDATE tpl_report_Tag
				   SET tag_type = in_tag_type
				 WHERE tpl_report_sid = in_tpl_report_sid
				   AND tag = v_tag;
			END IF;
	END;


	BEGIN
		INSERT INTO tpl_report_tag_qchart (
			tpl_report_tag_qchart_id, month_offset, month_duration,
			period_set_id, period_interval_id, hide_if_empty, split_table_by_columns,
			saved_filter_sid
		) VALUES (
			out_tpl_report_tag_qc_id, in_month_offset, in_month_duration, 
			in_period_set_id, in_period_interval_id, in_hide_if_empty, in_split_table_by_columns,
			in_saved_filter_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_tag_qchart
			   SET saved_filter_sid = in_saved_filter_sid,
				   month_offset = in_month_offset,
				   month_duration = in_month_duration,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id,
				   hide_if_empty = in_hide_if_empty,
				   split_table_by_columns = in_split_table_by_columns
			 WHERE tpl_report_tag_qchart_id = out_tpl_report_tag_qc_id;
	END;
END;

PROCEDURE UNSEC_InsertTagRegion(
	in_tpl_report_tag_dataview_id	IN tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE,
	in_dataview_sid					IN security_pkg.T_SID_ID,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_tpl_region_type_id			IN tpl_report_tag_dv_region.tpl_region_type_id%TYPE,
	in_filter_by_tag				IN tpl_report_tag_dv_region.filter_by_tag%TYPE
)
AS
BEGIN
	INSERT INTO tpl_report_tag_dv_region (
		tpl_report_tag_dataview_id, dataview_sid, region_sid, tpl_region_type_id, filter_by_tag
	) VALUES (
		in_tpl_report_tag_dataview_id, in_dataview_sid, in_region_sid, in_tpl_region_type_id, in_filter_by_tag
	);
END;

PROCEDURE UNSEC_InsertTagCondition(
	in_tpl_report_tag_eval_id		IN tpl_report_tag_eval.tpl_report_tag_eval_id%TYPE,
	in_left_ind_sid					IN security_pkg.T_SID_ID,
	in_operator						IN tpl_report_tag_eval_cond.operator%TYPE,
	in_right_ind_sid				IN security_pkg.T_SID_ID,
	in_right_value					IN tpl_report_tag_eval_cond.right_value%TYPE
)
AS
BEGIN
	INSERT INTO tpl_report_tag_eval_cond (
		tpl_report_tag_eval_id, left_ind_sid, operator, right_ind_sid, right_value
	) VALUES (
		in_tpl_report_tag_eval_id, in_left_ind_sid, in_operator, in_right_ind_sid, in_right_value
	);
END;

PROCEDURE GetRegionParent(
	in_region_sid					IN	region.region_sid%TYPE,
	out_parent_sid					OUT	region.parent_sid%TYPE
)
AS
BEGIN
	SELECT
		CASE
			WHEN rp.region_type = csr_data_pkg.REGION_TYPE_ROOT THEN r.region_sid -- if it's a root, then just return this region
			ELSE r.parent_sid
		END
	  INTO out_parent_sid
	  FROM region r, region rp
	 WHERE r.region_sid = in_region_sid
	   AND r.parent_sid = rp.region_sid;
END;

PROCEDURE GetRegionFromTop(
	in_region_sid					IN	region.region_sid%TYPE,
	in_depth						IN	NUMBER,
	out_region_sid					OUT	region.region_sid%TYPE
)
AS
BEGIN
	SELECT region_sid
	  INTO out_region_sid
	  FROM (
		SELECT region_sid, level lvl, MAX(level) OVER () max_lvl
		  FROM region r
			   START WITH region_sid = in_region_sid
			   CONNECT BY PRIOR parent_sid = region_sid AND region_type != csr_data_pkg.REGION_TYPE_ROOT
		)
	 WHERE lvl = GREATEST(1, max_lvl - in_depth);
END;

PROCEDURE GetChildrenAtLevel(
	in_region_sid					IN	region.region_sid%TYPE,
	in_level						IN	NUMBER,
	in_include_inactive				IN	NUMBER,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
	v_table	T_GENERIC_SO_TABLE := T_GENERIC_SO_TABLE();
BEGIN
	-- Collect the region_sids and descriptions in the right order: Parent by description then child by description as they appear in the region tree.
	SELECT T_GENERIC_SO_ROW(sid_id, description, position)
	  BULK COLLECT INTO v_table
	  FROM (
			SELECT region_sid sid_id, description, rownum position
			  FROM (
					SELECT r.app_sid, r.region_sid, rd.description, r.link_to_region_sid, level lvl
					  FROM region r
					  LEFT JOIN region rl
							 ON r.link_to_region_sid = rl.region_sid
							AND r.app_sid = rl.app_sid
					  JOIN region_description rd
							 ON r.app_sid = rd.app_sid
							AND NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
							AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
					  START WITH r.parent_sid = in_region_sid
							AND (in_include_inactive = 1 OR NVL(rl.active, r.active) = 1)
					CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
							AND (in_include_inactive = 1 OR NVL(rl.active, r.active) = 1)
							AND level <= in_level
					  ORDER SIBLINGS BY REGEXP_SUBSTR(LOWER(description), '^\D*') NULLS FIRST
					 )
			 WHERE lvl = in_level
			 );

	OPEN out_region_cur FOR
		SELECT r.region_sid, r.parent_sid, t.description, 
			   NVL(rl.active, r.active) active,
			   r.pos, r.name, r.geo_latitude, r.geo_longitude, r.geo_country,
			   r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm,
			   r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM TABLE (v_table) t
		  JOIN region r ON r.region_sid = t.sid_id
		  LEFT JOIN region rl
					 ON r.link_to_region_sid = rl.region_sid
					AND r.app_sid = rl.app_sid
		 ORDER BY t.position;

	OPEN out_region_tag_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM region_tag rt
		  JOIN TABLE (v_table) t 
				 ON rt.region_sid = t.sid_id
				AND rt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCustomerTagTypes (
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tpl_rep_cust_tag_type_id, cs_class, js_include, js_class, description
		  FROM tpl_rep_cust_tag_type
		 WHERE app_sid = security_pkg.GetApp;
END;


PROCEDURE GetTemplateImages(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_report_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_report_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'TemplatedReports');

	-- Check that user can add templated reports
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_report_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit templated report images if no access to templated reports');
	END IF;

	OPEN out_cur FOR
		SELECT key, key old_key, path, filename
		  FROM tpl_img
		 WHERE app_sid = security_pkg.GetApp
		 ORDER BY UPPER(key);
END;

PROCEDURE DeleteTemplateImage(
	in_key							IN	tpl_img.key%TYPE
)
AS
	v_report_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_report_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'TemplatedReports');

	-- Check that user can add templated reports
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_report_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit templated report images if no access to templated reports');
	END IF;

	DELETE FROM tpl_img
	 WHERE app_sid = security_pkg.GetApp
	   AND key=in_key;
END;

PROCEDURE SaveTemplateImage(
	in_old_key						IN	tpl_img.key%TYPE,
	in_key							IN	tpl_img.key%TYPE,
	in_path							IN	score_threshold.description%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_report_root_sid				security_pkg.T_SID_ID;
BEGIN
	v_report_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'TemplatedReports');

	-- Check that user can add templated reports
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_report_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit templated report images if no access to templated reports');
	END IF;

	IF in_old_key IS NULL THEN
		INSERT INTO tpl_img (key, path)
		VALUES (in_key, in_path);
	ELSE
		UPDATE tpl_img
		   SET key = in_key,
				path = in_path
		 WHERE app_sid = security_pkg.GetApp
		   AND key = in_old_key;
	END IF;
	OPEN out_cur FOR
		SELECT key, key old_key, path, filename
		  FROM tpl_img
		 WHERE app_sid = security_pkg.GetApp
		   AND key=in_key;
END;

PROCEDURE ChangeTemplateImage(
	in_key							IN	tpl_img.key%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%type
)
AS
	v_report_root_sid				security_pkg.T_SID_ID;
BEGIN
	v_report_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'TemplatedReports');

	-- Check that user can add templated reports
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_report_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit templated report images if no access to templated reports');
	END IF;

	IF in_cache_key IS NULL THEN
		UPDATE tpl_img
		   SET image = NULL,
		       filename = NULL
		 WHERE app_sid = security_pkg.GetApp
		   AND key = in_key;
	ELSE
		-- update image
		UPDATE tpl_img
		   SET (image, filename, mime_type) = (
				SELECT object, filename, mime_type
				  FROM aspen2.filecache
				 WHERE cache_key = in_cache_key
			 )
		 WHERE app_sid = security_pkg.GetApp
		   AND key = in_key;
	END IF;

END;

PROCEDURE GetTemplateImage(
	in_key							IN	tpl_img.key%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - it's just an image

	OPEN out_cur FOR
		SELECT image, filename, mime_type
		  FROM tpl_img
		 WHERE app_sid = security_pkg.GetApp
		   AND key=in_key;
END;

PROCEDURE GetFolderPath(
	in_folder_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, Name
		  FROM security.securable_object
			START WITH sid_id = in_folder_sid AND class_id = 4
			CONNECT BY sid_id = PRIOR parent_sid_id AND class_id = 4
		ORDER BY LEVEL DESC;
END;

PROCEDURE SetBatchJob(
	in_settings_xml		IN	CLOB,
	in_user_sid			IN	batch_job_templated_report.user_sid%TYPE,
	in_schedule_sid		IN	batch_job_templated_report.schedule_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_TEMPLATED_REPORT,
		in_requesting_user => in_user_sid,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_templated_report
	  (batch_job_id, templated_report_request_xml, user_sid, schedule_sid)
	  VALUES 
      (out_batch_job_id, XMLTYPE(in_settings_xml), in_user_sid, in_schedule_sid);
END;

PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT templated_report_request_xml, user_sid, schedule_sid
		  FROM batch_job_templated_report
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetSettingsFromBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT templated_report_request_xml, run.description scenario_run_description
		  FROM batch_job_templated_report bjtr
	 LEFT JOIN scenario_run run ON bjtr.TEMPLATED_REPORT_REQUEST_XML.EXTRACT('TemplatedReportRequest/ScenarioSid/text()').getStringVal() = run.scenario_run_sid
		 WHERE batch_job_id = in_batch_job_id;

END;

PROCEDURE UpdateBatchJob(
	in_batch_job_id		IN NUMBER,
	in_report_data		IN batch_job_templated_report.report_data%TYPE
)
AS
BEGIN
	UPDATE batch_job_templated_report
	   SET report_data = in_report_data
	 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetBatchJobReportData(
	in_batch_job_id		IN	batch_job_templated_report.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF CanDownloadReport(in_batch_job_id) = FALSE THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied downloading report data.');
	END IF;
		
	
	OPEN out_cur FOR
		SELECT report_data
		  FROM batch_job_templated_report
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE CanDownloadReport(
	in_batch_job_id			IN	batch_job_templated_report.batch_job_id%TYPE,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF CanDownloadReport(in_batch_job_id) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

FUNCTION CanDownloadReport(
	in_batch_job_id			IN	batch_job_templated_report.batch_job_id%TYPE
) RETURN BOOLEAN
AS
	v_report_user_sid				security_pkg.T_SID_ID;
	v_schedule_user_sid				security_pkg.T_SID_ID;
	v_current_user_sid				security_pkg.T_SID_ID;
	v_job_app_sid					security_pkg.T_SID_ID;
BEGIN
	
	v_current_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	
	--Paranoid app check. Just in case RLS have briefly dropped, etc
	BEGIN
		SELECT app_sid
		  INTO v_job_app_sid
		  FROM batch_job
		 WHERE batch_job_id = in_batch_job_id;
		 
		IF v_job_app_sid != SYS_CONTEXT('SECURITY', 'APP') THEN
			RETURN FALSE;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	IF csr_user_pkg.IsSuperAdmin = 1 THEN
		RETURN TRUE;
	END IF;
	
	--Capability check
	IF csr_data_pkg.CheckCapability('Download all templated reports') THEN
		RETURN TRUE;
	END IF;
	
	SELECT requested_by_user_sid
	  INTO v_report_user_sid
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id
	   AND app_sid		= SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_report_user_sid = v_current_user_sid THEN
		RETURN TRUE;
	END IF;
	
	BEGIN
		SELECT trs.owner_user_sid
		  INTO v_schedule_user_sid
		  FROM batch_job_templated_report bjtr
		  JOIN tpl_report_schedule trs ON trs.schedule_sid = bjtr.schedule_sid
		 WHERE bjtr.batch_job_id = in_batch_job_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--It's not a schedule, so no further checks
			RETURN FALSE;
	END;

	RETURN NVL(v_schedule_user_sid = v_current_user_sid, FALSE);
END;

PROCEDURE ScheduledBatchJobDataTidy(
	in_blank		IN NUMBER DEFAULT NULL
)
AS
	v_expiry_date	batch_job.completed_dtm%TYPE;
BEGIN
	--Any batch job templated reports before this date will have their blob data cleared.
	v_expiry_date := sysdate - 10;

	FOR r IN (
		SELECT bj.batch_job_id bjid
		  FROM batch_job bj
		  JOIN batch_job_templated_report bjtr on bj.batch_job_id = bjtr.batch_job_id
		 WHERE bj.batch_job_type_id = 8
		   AND bjtr.report_data IS NOT NULL
		   AND bj.completed_dtm < v_expiry_date
    ) 
	LOOP
		UPDATE batch_job_templated_report
	       SET report_data = NULL
	     WHERE batch_job_id = r.bjid;
		 
		UPDATE batch_job
           SET result     = 'Report expired', 
		       result_url = NULL
	     WHERE batch_job_id = r.bjid;
	END LOOP;
END;

PROCEDURE ReRunBatchJob(
	in_batch_job_id		IN	batch_job_templated_report.batch_job_id%TYPE,
	in_user_sid			IN	batch_job_templated_report.user_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
)
AS
	v_request_xml		batch_job_templated_report.templated_report_request_xml%TYPE;
BEGIN

	BEGIN
		SELECT templated_report_request_xml
		  INTO v_request_xml
		  FROM batch_job_templated_report
		 WHERE batch_job_id = in_batch_job_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Batch job ' || in_batch_job_id || ' could not be found');
	END;

	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_TEMPLATED_REPORT,
		in_requesting_user => in_user_sid,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_templated_report
	  (batch_job_id, templated_report_request_xml, user_sid, schedule_sid)
	  VALUES 
      (out_batch_job_id, v_request_xml, in_user_sid, null);
END;

PROCEDURE GetTemplateJobs(
	in_template_sid			IN TPL_REPORT.tpl_report_sid%TYPE,
	in_start_row			IN NUMBER,
	in_end_row				IN NUMBER,
	in_order_by				IN VARCHAR2,
	in_order_dir			IN VARCHAR2,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_can_download_all		NUMBER;
BEGIN

	IF csr_data_pkg.CheckCapability('Download all templated reports') OR csr_user_pkg.IsSuperAdmin = 1 THEN
		v_can_download_all := 1;
	ELSE
		v_can_download_all := 0;
	END IF;

	OPEN out_cur FOR
		SELECT *
			FROM (
			SELECT q.*, ROWNUM rn, count(*) over() total_rows
			  FROM (
			  SELECT bj.batch_job_id, bj.completed_dtm run_time, bj.result, bj.result_url, bjtr.templated_report_request_xml request_data, cu.full_name run_by, 
				  tr.period_set_id, tr.period_interval_id,
					-- Do separately to avoid ORA-00600 errors.
					(
					SELECT EXTRACTVALUE(sd.TEMPLATED_REPORT_REQUEST_XML, 'TemplatedReportRequest/ProxyStartDtm')
					  FROM csr.batch_job_templated_report sd
					 WHERE batch_job_id = bjtr.batch_job_id
					) start_dtm,
					( 
					SELECT run.description
					  FROM scenario_run run
					 WHERE EXTRACTVALUE(bjtr.TEMPLATED_REPORT_REQUEST_XML, 'TemplatedReportRequest/ScenarioSid') = run.scenario_run_sid
					) scenario_run_description
				FROM csr.batch_job_templated_report bjtr
				JOIN csr.batch_job bj	ON bjtr.BATCH_JOB_ID = bj.BATCH_JOB_ID
				JOIN csr.csr_user cu	ON cu.csr_user_sid = bj.requested_by_user_sid
				JOIN csr.tpl_report tr	ON tr.tpl_report_sid = in_template_sid
			   WHERE bjtr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 AND EXTRACTVALUE(bjtr.TEMPLATED_REPORT_REQUEST_XML, 'TemplatedReportRequest/TplReportSid') = in_template_sid
				 AND bj.completed_dtm IS NOT NULL
				 AND (0 = 1 OR bj.REQUESTED_BY_USER_SID = SYS_CONTEXT('SECURITY', 'SID'))
			   ORDER BY
			  -- To avoid dynamic SQL, do many case statements
			  CASE WHEN in_order_dir = 'ASC' OR in_order_dir IS NULL THEN
			   CASE (in_order_by)
				WHEN 'period' THEN TO_DATE(start_dtm, 'DD/MM/YYYY HH24:MI:SS')
				WHEN 'runTime' THEN bj.completed_dtm
			   END 
			  END ASC,
			  CASE WHEN in_order_dir = 'ASC' OR in_order_dir IS NULL THEN
			   CASE (in_order_by)
				WHEN 'runBy' THEN cu.full_name
			   END
			  END ASC,
			  CASE WHEN in_order_dir = 'DESC' THEN
			   CASE (in_order_by)
				WHEN 'period' THEN TO_DATE(start_dtm, 'DD/MM/YYYY HH24:MI:SS')
				WHEN 'runTime' THEN bj.completed_dtm
			   END
			  END DESC,
			  CASE WHEN in_order_dir = 'DESC' THEN
			   CASE (in_order_by)
				WHEN 'runBy' THEN cu.full_name
			   END
			  END DESC,
			  CASE WHEN in_order_dir = 'ASC' OR in_order_dir IS NULL THEN bj.completed_dtm END DESC,
			  CASE WHEN in_order_dir = 'DESC' THEN bj.completed_dtm END ASC
				) q
			  )
		   WHERE rn > in_start_row AND rn <= in_end_row;
END;

PROCEDURE CheckCanReadRegions(
	in_regions				IN	security_pkg.T_SID_IDS,
	out_result				OUT NUMBER
)
AS
	v_regions				security.T_SID_TABLE;
BEGIN
	v_regions := security_pkg.SidArrayToTable(in_regions);

	FOR r IN (
		SELECT column_value FROM TABLE(v_regions)
	)
	LOOP
		IF security_pkg.sql_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) = 0 THEN
			out_result := 0;
			RETURN;
		END IF;
	END LOOP;
	out_result := 1;
	
END;

PROCEDURE GetPortletDetails(
	in_tab_portlet_id			IN	TAB_PORTLET.tab_portlet_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT adsrp.maps_to_tag_type tag_type_id, tp.state
		  FROM APP_DASH_SUP_REPORT_PORTLET adsrp
		  JOIN PORTLET p 			ON p.type 					= adsrp.portlet_type
		  JOIN CUSTOMER_PORTLET cp 	ON cp.portlet_id 			= p.portlet_id
		  JOIN TAB_PORTLET tp 		ON tp.customer_portlet_sid 	= cp.customer_portlet_sid
		 WHERE tp.tab_portlet_id = in_tab_portlet_id;
END;

PROCEDURE GetRegionDataTypes(
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security needed - fetching global combobox values
	OPEN out_cur FOR
		SELECT tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled
		  FROM csr.tpl_report_reg_data_type
		 ORDER BY pos;
END;

PROCEDURE CheckForInactiveRegions(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	out_invalid_count	OUT NUMBER
)
AS
	t_region_sids 		security.T_SID_TABLE;
BEGIN
	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);

	SELECT COUNT(r.region_sid)
	  INTO out_invalid_count
	  FROM region r
	  LEFT JOIN region rl ON rl.region_sid = r.link_to_region_sid
	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND r.region_sid IN (SELECT COLUMN_VALUE FROM TABLE(t_region_sids))
	   AND NVL(rl.active, r.active) = 0;
END;

--Variant
PROCEDURE GetTemplateVariants(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting template variants.');
	END IF;

	OPEN out_cur FOR
		SELECT master_template_sid, language_code, filename, word_doc, mime_type
		  FROM tpl_report_variant
		 WHERE master_template_sid = in_tpl_report_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		 ORDER BY language_code;
		 
	OPEN out_tags FOR
		SELECT tpl_report_sid, language_code, tag
		  FROM tpl_report_variant_tag
		 WHERE tpl_report_sid = in_tpl_report_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tpl_report_sid;
END;

PROCEDURE GetTemplateVariant(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_language_code				IN tpl_report_variant.language_code%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting template variant.');
	END IF;

	OPEN out_cur FOR
		SELECT master_template_sid, language_code, filename, word_doc, mime_type
		  FROM tpl_report_variant
		 WHERE master_template_sid = in_tpl_report_sid
		   AND language_code = in_language_code
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SaveTemplateVariant(
	in_master_template_sid			IN	tpl_report_variant.master_template_sid%TYPE,
	in_language_code				IN	tpl_report_variant.language_code%TYPE,
	in_filename						IN	tpl_report_variant.filename%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_variant_exists				NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_master_template_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating template variants.');
	END IF;

	BEGIN
		INSERT INTO tpl_report_variant (
			master_template_sid, language_code, filename, word_doc, mime_type
		)
			SELECT in_master_template_sid, in_language_code, in_filename, object, mime_type
			  FROM aspen2.filecache
			 WHERE cache_key = in_cache_key;

		IF SQL%ROWCOUNT = 0 THEN
			-- path not found
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE tpl_report_variant
			   SET (filename, word_doc, mime_type) = (SELECT in_filename, object, mime_type FROM aspen2.filecache WHERE cache_key = in_cache_key)
			 WHERE master_template_sid = in_master_template_sid
			   AND language_code = in_language_code;
			   
			IF SQL%ROWCOUNT = 0 THEN
				-- path not found
				RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
			END IF;
	END;
END;

PROCEDURE DeleteTemplateVariant(
	in_master_template_sid			IN security_pkg.T_SID_ID,
	in_language_code				IN tpl_report_variant.language_code%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_master_template_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting template variants.');
	END IF;

	DELETE FROM tpl_report_variant
	 WHERE master_template_sid = in_master_template_sid
	   AND language_code = in_language_code;
END;

PROCEDURE DeleteLangVariantTags(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_language_code				IN	tpl_report_variant.language_code%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting template variants tags.');
	END IF;
	
	DELETE FROM tpl_report_variant_tag
	 WHERE tpl_report_sid = in_tpl_report_sid 
	   AND language_code = in_language_code;
END;

PROCEDURE SetLangVariantTag(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_language_code				IN	tpl_report_variant.language_code%TYPE,
	in_tag							IN	tpl_report_tag.tag%TYPE
)
AS
	v_tag							tpl_report_tag.tag%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_tpl_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting tag for language variant report template.');
	END IF;

	-- always make lower case
	v_tag := LOWER(in_tag);

	BEGIN
		INSERT INTO tpl_report_variant_tag (
			tpl_report_sid, language_code, tag
		) VALUES (
			in_tpl_report_sid, in_language_code, v_tag
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RETURN;
	END;
END;

FUNCTION GetParentLanguage(
	in_lang					IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE
AS
	v_parent_lang			aspen2.lang.lang%TYPE;
BEGIN
	BEGIN
		SELECT parent.lang
		  INTO v_parent_lang
		  FROM aspen2.lang l
		  JOIN aspen2.lang parent ON l.parent_lang_id = parent.lang_id
		 WHERE l.lang = in_lang;
	EXCEPTION
		WHEN no_data_found THEN v_parent_lang := NULL;
	END;
	
	RETURN v_parent_lang;
END;

PROCEDURE GetDescendantReports(
	in_root_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tpl_report_sid, parent_sid, filename, period_set_id, period_interval_id,
			   name, description, CASE WHEN thumb_img IS NOT NULL THEN 1 ELSE 0 END has_thumb
		 FROM tpl_report
		WHERE parent_sid IN (
			  	SELECT sid_id FROM TABLE(securableobject_pkg.GetDescendantsAsTable(SYS_CONTEXT('SECURITY', 'ACT'), in_root_sid) )) 
		ORDER BY name;
END;

END;
/
