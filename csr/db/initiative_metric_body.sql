CREATE OR REPLACE PACKAGE BODY CSR.initiative_metric_pkg
IS

FUNCTION MetricValArrayToTable(
	in_vals						IN T_METRIC_VALS
) RETURN T_INITIATIVE_METRIC_VAL_TABLE DETERMINISTIC
AS
	v_table 	T_INITIATIVE_METRIC_VAL_TABLE := T_INITIATIVE_METRIC_VAL_TABLE();
BEGIN
	IF in_vals.COUNT = 0 THEN
		RETURN v_table;
	END IF;

	FOR i IN in_vals.FIRST .. in_vals.LAST
	LOOP
		BEGIN
			v_table.extend;
			v_table(v_table.COUNT) := T_INITIATIVE_METRIC_VAL_ROW( in_vals(i), v_table.COUNT );
		END;
	END LOOP;

	RETURN v_table;
END;

FUNCTION INIT_EmptyMetricVals
RETURN initiative_metric_pkg.T_METRIC_VALS
AS
	v initiative_metric_pkg.T_METRIC_VALS;
BEGIN
	RETURN v;
END;


PROCEDURE SetNullMetricVal(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_measured_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_id_table 					security.T_SID_TABLE;
	v_spin						BOOLEAN;
BEGIN
	v_id_table := security_pkg.SidArrayToTable(in_measured_ids);
	v_spin := TRUE;
	WHILE v_spin
	LOOP
		BEGIN
			-- Insert optimistically
			INSERT INTO initiative_metric_val (initiative_metric_id, initiative_sid, project_sid)
				(
					SELECT m.initiative_metric_id, i.initiative_sid, i.project_sid
					  FROM initiative i, project_initiative_metric pm, initiative_metric m
					 WHERE i.initiative_sid = in_initiative_sid
					   AND pm.project_sid = i.project_sid
					   AND m.initiative_metric_id = pm.initiative_metric_id
					   AND pm.update_per_period = 0
					UNION
					SELECT m.initiative_metric_id, i.initiative_sid, i.project_sid
					  FROM initiative i, project_initiative_metric pm, initiative_metric m, TABLE(v_id_table) id
					 WHERE i.initiative_sid = in_initiative_sid
					   AND pm.project_sid = i.project_sid
					   AND m.initiative_metric_id = pm.initiative_metric_id
					   AND id.column_value = m.initiative_metric_id
					   AND pm.update_per_period = 1
				) MINUS (
					SELECT initiative_metric_id, initiative_sid, project_sid
					  FROM initiative_metric_val
					 WHERE initiative_sid = in_initiative_sid
				);

			DELETE FROM initiative_metric_val
			 WHERE (initiative_metric_id, initiative_sid, project_sid) IN (
			 	(
			 		SELECT initiative_metric_id, initiative_sid, project_sid
					  FROM initiative_metric_val
					 WHERE initiative_sid = in_initiative_sid
				) MINUS (
					SELECT m.initiative_metric_id, i.initiative_sid, i.project_sid
					  FROM initiative i, project_initiative_metric pm, initiative_metric m
					 WHERE i.initiative_sid = in_initiative_sid
					   AND pm.project_sid = i.project_sid
					   AND m.initiative_metric_id = pm.initiative_metric_id
					   AND pm.update_per_period = 0
					UNION
					SELECT m.initiative_metric_id, i.initiative_sid, i.project_sid
					  FROM initiative i, project_initiative_metric pm, initiative_metric m, TABLE(v_id_table) id
					 WHERE i.initiative_sid = in_initiative_sid
					   AND pm.project_sid = i.project_sid
					   AND m.initiative_metric_id = pm.initiative_metric_id
					   AND id.column_value = m.initiative_metric_id
					   AND pm.update_per_period = 1
				)
			 );

			-- Success
			v_spin := FALSE;

		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);
END;

PROCEDURE INTERNAL_BeginAuditMetrics(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_metrics					OUT	T_INIT_METRIC_AUDIT_TABLE
)
AS
BEGIN
	SELECT T_INIT_METRIC_AUDIT_ROW(initiative_metric_id, entry_measure_conversion_id, entry_val)
	  BULK COLLECT INTO out_metrics
	  FROM initiative_metric_val
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_sid = in_initiative_sid;
END;

PROCEDURE INTERNAL_EndAuditMetrics(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_metrics					IN	T_INIT_METRIC_AUDIT_TABLE
)
AS
BEGIN
	-- Look for removed metrics...
	FOR r IN (
		SELECT x.initiative_metric_id, m.label
		  FROM TABLE(in_metrics) x
		  JOIN initiative_metric m ON m.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND m.initiative_metric_id = x.initiative_metric_id
		 WHERE NOT EXISTS (
		 	SELECT 1
		 	  FROM initiative_metric_val v
		 	 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND v.initiative_sid = in_initiative_sid
		 	   AND v.initiative_metric_id = x.initiative_metric_id
		 )
	) LOOP
		-- Removed
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Metric {0} removed.',
			r.label
		);
	END LOOP;

	-- Look for added metrics...
	FOR r IN (
		SELECT v.initiative_metric_id, m.label
		  FROM initiative_metric_val v
		  JOIN initiative_metric m ON m.app_sid = v.app_sid AND m.initiative_metric_id = v.initiative_metric_id
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.initiative_sid = in_initiative_sid
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM TABLE(in_metrics) x
		 	 WHERE x.initiative_metric_id = v.initiative_metric_id
		 )
	) LOOP
		-- Added
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Metric {0} added.',
			r.label
		);
	END LOOP;

	-- Look for values that have changed (present in both tables, before and after)
	FOR r IN (
		SELECT v.initiative_metric_id, m.label,
				v.entry_val new_val, v.entry_measure_conversion_id new_conversion_id, NVL(mcn.description, ms.description) new_conversion_desc,
				x.val old_val, x.conversion_id old_conversion_id, NVL(mco.description, ms.description) old_conversion_desc
		  FROM initiative_metric_val v
		  JOIN TABLE(in_metrics) x ON v.initiative_metric_id = x.initiative_metric_id
		  JOIN initiative_metric m ON m.app_sid = v.app_sid AND m.initiative_metric_id = v.initiative_metric_id
		  JOIN measure ms ON ms.app_sid = v.app_sid AND ms.measure_sid = v.measure_sid
		  LEFT JOIN measure_conversion mcn ON mcn.app_sid = ms.app_sid AND mcn.measure_sid = ms.measure_sid AND mcn.measure_conversion_id = v.entry_measure_conversion_id
		  LEFT JOIN measure_conversion mco ON mco.app_sid = ms.app_sid AND mco.measure_sid = ms.measure_sid AND mco.measure_conversion_id = x.conversion_id
		 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.initiative_sid = in_initiative_sid
	) LOOP
		-- Audit value cahnges
		csr_data_pkg.AuditValueChange(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Metric '||r.label,
			r.old_val,
			r.new_val
		);
		-- Audit conversion changes
		csr_data_pkg.AuditValueDescChange(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Metric measure for '||r.label,
			r.old_conversion_id,
			r.new_conversion_id,
			r.old_conversion_desc,
			r.new_conversion_desc
		);
	END LOOP;
END;

PROCEDURE INTERNAL_UpsertMetricVal(
	in_initiative_metric_id		IN	initiative_metric.initiative_metric_id%TYPE,
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_entry_val				IN	initiative_metric_val.entry_val%TYPE,
	in_dtm						IN	DATE
)
AS
BEGIN
	BEGIN
		INSERT INTO initiative_metric_val
			(initiative_metric_id, initiative_sid, project_sid, measure_sid, entry_measure_conversion_id, entry_val, val)
		VALUES
			(in_initiative_metric_id, in_initiative_sid, in_project_sid, in_measure_sid, in_measure_conversion_id, in_entry_val,
				measure_pkg.UNSEC_GetBaseValue(in_entry_val, in_measure_conversion_id, in_dtm));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE initiative_metric_val
			   SET measure_sid = in_measure_sid,
			       entry_measure_conversion_id = in_measure_conversion_id,
			       entry_val = in_entry_val,
				   val = measure_pkg.UNSEC_GetBaseValue(in_entry_val, in_measure_conversion_id, in_dtm)
			 WHERE initiative_sid = in_initiative_sid
			   AND initiative_metric_id = in_initiative_metric_id;
	END;
END;

-- NOTE: This procedure is used by the UI. The procedure  assumes that if any
-- metric value is missing from the input set then that metric's value should be
-- set to NULL. If you want to set metric values without this behaviour then use
-- RawSetMetricVals or RawSetMetricVal.
-- NOTE: If the metric has the is_external falg set then this procedure will *not* modify it's value.
PROCEDURE SetMetricVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	initiative_metric_pkg.T_METRIC_VALS,
	in_uoms						IN	security_pkg.T_SID_IDS
)
AS
	v_id_table					security.T_ORDERED_SID_TABLE;
	v_val_table					T_INITIATIVE_METRIC_VAL_TABLE;
	v_uom_table					security.T_ORDERED_SID_TABLE;
	v_audit_table				T_INIT_METRIC_AUDIT_TABLE;
BEGIN
	INTERNAL_BeginAuditMetrics(in_initiative_sid, v_audit_table);
	v_id_table := security_pkg.SidArrayToOrderedTable(in_ids);
	v_val_table := MetricValArrayToTable(in_vals);
	v_uom_table := security_pkg.SidArrayToOrderedTable(in_uoms);

	FOR r IN (
		-- XXX: If the metric is not in v_id_table then the value is set to null, this
		-- means we have to filter out periodic metrics here to prevent the check-boxes
		-- from being set on the create page when an initiative metric value is saved.
		-- NOTE: If the metric has the is_external falg set then this procedure will *not* modify it's value.
		SELECT i.project_sid, im.measure_sid, im.initiative_metric_id, v.item entry_val,
			NVL(i.project_start_dtm, i.running_start_dtm) dtm,
			DECODE(u.sid_id, -1, NULL, u.sid_id) measure_conversion_id
		  FROM initiative i, initiative_metric im, project_initiative_metric pim,
		  	TABLE(v_id_table) id, TABLE(v_val_table) v, TABLE(v_uom_table) u
		 WHERE i.initiative_sid = in_initiative_sid
		   AND pim.project_sid = i.project_sid
		   AND pim.initiative_metric_id = im.initiative_metric_id
		   AND pim.update_per_period = 0 -- Filter out periodic metrics
		   AND im.is_external = 0 -- Do not touch metrics marked as external
		   AND id.sid_id(+) = pim.initiative_metric_id
		   AND v.pos(+) = id.pos
		   AND u.pos(+) = id.pos
		   	ORDER by id.pos
	) LOOP
		INTERNAL_UpsertMetricVal(
			r.initiative_metric_id,
			in_initiative_sid,
			r.project_sid,
			r.measure_sid,
			r.measure_conversion_id,
			r.entry_val,
			r.dtm
		);
	END LOOP;

	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);
	INTERNAL_EndAuditMetrics(in_initiative_sid, v_audit_table);
END;

-- Set a single metric value
PROCEDURE RawSetMetricVal(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_id						IN	initiative_metric.initiative_metric_id%TYPE,
	in_val						IN	initiative_metric_val.entry_val%TYPE,
	in_uom						IN	initiative_metric_val.entry_measure_conversion_id%TYPE
)
AS
	v_ids						security_pkg.T_SID_IDS;
	v_vals						initiative_metric_pkg.T_METRIC_VALS;
	v_uoms						security_pkg.T_SID_IDS;
BEGIN

	-- Use RawSetMetricVals procedure to do the
	-- update so need to pass in unit lenght arrays
	v_ids(0) := in_id;
	v_vals(0) := in_val;
	v_uoms(0) := in_uom;

	RawSetMetricVals(
		in_initiative_sid,
		v_ids,
		v_vals,
		v_uoms
	);
END;

PROCEDURE RawSetMetricVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	initiative_metric_pkg.T_METRIC_VALS,
	in_uoms						IN	security_pkg.T_SID_IDS
)
AS
	v_id_table					security.T_ORDERED_SID_TABLE;
	v_val_table					T_INITIATIVE_METRIC_VAL_TABLE;
	v_uom_table					security.T_ORDERED_SID_TABLE;
	v_audit_table				T_INIT_METRIC_AUDIT_TABLE;
BEGIN
	INTERNAL_BeginAuditMetrics(in_initiative_sid, v_audit_table);
	v_id_table := security_pkg.SidArrayToOrderedTable(in_ids);
	v_val_table := MetricValArrayToTable(in_vals);
	v_uom_table := security_pkg.SidArrayToOrderedTable(in_uoms);

	FOR r IN (
		-- This version only updates those metrics matching the ids that have been passed in
		SELECT i.project_sid, im.measure_sid, im.initiative_metric_id, v.item entry_val,
			NVL(i.project_start_dtm, i.running_start_dtm) dtm,
			DECODE(u.sid_id, -1, NULL, u.sid_id) measure_conversion_id
		  FROM initiative i, initiative_metric im, project_initiative_metric pim,
		  	TABLE(v_id_table) id, TABLE(v_val_table) v, TABLE(v_uom_table) u
		 WHERE i.initiative_sid = in_initiative_sid
		   AND pim.project_sid = i.project_sid
		   AND pim.initiative_metric_id = im.initiative_metric_id
		   AND id.sid_id = pim.initiative_metric_id
		   AND v.pos(+) = id.pos
		   AND u.pos(+) = id.pos
		   	ORDER by id.pos
	) LOOP
		INTERNAL_UpsertMetricVal(
			r.initiative_metric_id,
			in_initiative_sid,
			r.project_sid,
			r.measure_sid,
			r.measure_conversion_id,
			r.entry_val,
			r.dtm
		);
	END LOOP;

	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);
	INTERNAL_EndAuditMetrics(in_initiative_sid, v_audit_table);
END;

PROCEDURE GetProjectMetrics(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_metrics FOR
		SELECT p.project_sid, p.pos, p.update_per_period, p.default_value, p.input_dp, p.flow_sid, p.info_text,
			m.initiative_metric_id, m.measure_sid, m.is_saving, m.per_period_duration, m.one_off_period, m.is_during, m.is_running, m.is_rampable, m.label, m.lookup_key,
			g.pos_group, g.is_group_mandatory, g.label group_label, g.info_text group_info_text,
			mfs.flow_state_id, mfs.mandatory is_mandatory, DECODE(mfs.flow_state_id, fl.default_state_id, 1, 0) is_default,
			val.entry_measure_conversion_id, val.entry_val, val.val, DECODE (val.initiative_metric_id, NULL, 0, 1) measured_checked
		  FROM project_initiative_metric p
		  JOIN initiative_metric m
		    ON m.initiative_metric_id = p.initiative_metric_id
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN initiative_metric_group g
		    ON g.project_sid = p.project_sid
		   AND g.pos_group = p.pos_group
		  JOIN project_init_metric_flow_state mfs
		    ON mfs.project_sid = p.project_sid
		   AND mfs.initiative_metric_id = m.initiative_metric_id
		  JOIN flow fl
		    ON fl.flow_sid = mfs.flow_sid
		  LEFT JOIN initiative_metric_val val
		    ON val.initiative_metric_id = m.initiative_metric_id
		   AND val.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND val.initiative_sid = in_initiative_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.project_sid = in_project_sid
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   --AND mfs.flow_state_id = fl.default_state_id
		   AND mfs.visible = 1
		   AND m.is_external = 0;

	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM project_initiative_metric pim, initiative_metric im, measure m, measure_conversion mc
		 WHERE pim.project_sid = in_project_sid
		   AND im.initiative_metric_id = pim.initiative_metric_id
		   AND m.measure_sid = im.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;

	OPEN out_assoc FOR
		SELECT proposed_metric_id, measured_metric_id
		  FROM initiative_metric_assoc
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND project_sid = in_project_sid
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), project_sid, security_pkg.PERMISSION_READ) = 1;
END;


PROCEDURE GetInitiativeMetrics(
	out_metrics				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage initiative metrics');
	END IF;

	OPEN out_metrics FOR
		SELECT initiative_metric_id, label, measure_sid, is_during, is_running, is_rampable,
			per_period_duration, one_off_period, divisibility, lookup_key, is_external
		  FROM initiative_metric
		 ORDER BY label;

END;

PROCEDURE GetInitiativeMetrics(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- XXX: should this be an outer join on project_init_metric_Flow_State?
	OPEN out_metrics FOR
		SELECT p.project_sid, p.pos, p.update_per_period, p.default_value, p.input_dp, p.flow_sid, p.info_text,
			m.initiative_metric_id, m.measure_sid, m.is_saving, m.per_period_duration, m.one_off_period, m.is_during, m.is_running, m.is_rampable, m.label, m.lookup_key,
			val.entry_measure_conversion_id, val.entry_val, val.val,
			g.pos_group, g.is_group_mandatory, g.label group_label, g.info_text group_info_text,
			mfs.mandatory is_mandatory, 1 is_default /* Make sure the metrics are selected by the create/edit page */ ,
			DECODE (val.initiative_metric_id, NULL, 0, 1) measured_checked
		  FROM project_initiative_metric p
		  JOIN initiative_metric m
		    ON m.initiative_metric_id = p.initiative_metric_id
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN initiative_metric_group g
		    ON g.project_sid = p.project_sid
		   AND g.pos_group = p.pos_group
		  JOIN initiative init
		    ON init.project_sid = p.project_sid
		  JOIN flow_item fl
		    ON fl.flow_item_id = init.flow_item_id
		  JOIN project_init_metric_flow_state mfs
		    ON mfs.project_sid = p.project_sid
		   AND mfs.initiative_metric_id = m.initiative_metric_id
		   AND mfs.flow_state_id = fl.current_state_id
		  LEFT JOIN initiative_metric_val val
		    ON val.initiative_metric_id = m.initiative_metric_id
		   AND val.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND val.initiative_sid = in_initiative_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND mfs.visible = 1
		   AND m.is_external = 0
		   AND init.initiative_sid = in_initiative_sid;

	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM initiative i, project_initiative_metric pim, initiative_metric im, csr.measure m, csr.measure_conversion mc
		 WHERE i.initiative_sid = in_initiative_sid
		   AND pim.project_sid = i.project_sid
		   AND im.initiative_metric_id = pim.initiative_metric_id
		   AND m.measure_sid = im.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;

	OPEN out_assoc FOR
		SELECT proposed_metric_id, measured_metric_id
		  FROM initiative i, initiative_metric_assoc a
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.initiative_sid = in_initiative_sid
		   AND a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.project_sid = i.project_sid
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), a.project_sid, security_pkg.PERMISSION_READ) = 1;
END;

-- gets a list of initiative metrics that are visible for the current flow state of the initiative
-- where values are set.
-- XXX: doesn't use initiative_metric_assoc (proposed_metric_id, measured_metric_id) etc -- should it?
PROCEDURE GetInitiativeMetricVals(
	in_initiative_sid	IN 	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading initiative sid '||in_initiative_sid);
	END IF;

	OPEN out_cur FOR
		SELECT img.pos_group, img.label group_label, img.info_text group_info_text,
	        im.initiative_metric_id, im.is_saving, im.label, im.lookup_key,
	        NVL(mc.description, m.description) measure_description,
	        imi.entry_val, m.format_mask
	      FROM initiative i
	      JOIN flow_item fi ON i.flow_item_id = fi.flow_item_Id AND i.app_sid = fi.app_sid
	      JOIN project_initiative_metric pim on i.project_sid = pim.project_sid AND i.app_sid = pim.app_sid
	      JOIN initiative_metric im ON pim.initiative_metric_id = im.initiative_metric_id AND i.app_sid = im.app_sid
	      JOIN initiative_metric_group img ON pim.project_sid = img.project_sid AND pim.app_sid = img.app_sid AND pim.pos_group = img.pos_group
	      LEFT JOIN project_init_metric_flow_state pimfs
	        ON pim.initiative_metric_id = pimfs.initiative_metric_id AND pim.app_sid = pimfs.app_sid
	        AND pim.project_sid = pimfs.project_sid AND pim.app_sid = pimfs.app_sid
	        AND fi.current_state_id = pimfs.flow_state_id
	      JOIN initiative_metric_val imi
	        ON im.initiative_metric_id = imi.initiative_metric_id AND im.app_sid = imi.app_sid
	        AND i.initiative_sid = imi.initiative_sid
	      JOIN measure m ON im.measure_sid = m.measure_sid AND im.app_sid = m.app_sid
	      LEFT JOIN measure_conversion mc ON imi.entry_measure_conversion_id = mc.measure_conversion_id AND imi.app_sid = mc.app_sid
	     WHERE i.initiative_sid = in_initiative_sid
	       AND NVL(pimfs.visible, 1) = 1
	       AND im.is_external = 0
	       AND val IS NOT NULL
	     ORDER BY img.pos_group;
END;

PROCEDURE GetAllMetrics(
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_metrics FOR
		SELECT p.project_sid, p.pos, p.update_per_period, p.default_value, p.input_dp, p.flow_sid, p.info_text,
			m.initiative_metric_id, m.measure_sid, m.is_saving, m.per_period_duration, m.one_off_period, m.is_during, m.is_running, m.is_rampable, m.label, m.lookup_key,
			g.pos_group, g.is_group_mandatory, g.label group_label, g.info_text group_info_text,
			mfs.flow_state_id, mfs.mandatory is_mandatory, DECODE(mfs.flow_state_id, fl.default_state_id, 1, 0) is_default
		  FROM project_initiative_metric p, initiative_metric m, initiative_metric_group g, project_init_metric_flow_state mfs, flow fl
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.initiative_metric_id = p.initiative_metric_id
		   AND g.project_sid = p.project_sid
		   AND g.pos_group = p.pos_group
		   AND mfs.project_sid = p.project_sid
		   AND mfs.initiative_metric_id = m.initiative_metric_id
		   --AND mfs.flow_state_id = fl.default_state_id
		   AND mfs.visible = 1
		   AND m.is_external = 0
		   AND fl.flow_sid = mfs.flow_sid;

	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM project_initiative_metric pim, initiative_metric im, csr.measure m, csr.measure_conversion mc
		 WHERE im.initiative_metric_id = pim.initiative_metric_id
		   AND m.measure_sid = im.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;

	OPEN out_assoc FOR
		SELECT proposed_metric_id, measured_metric_id
		  FROM initiative_metric_assoc
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), project_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE LookupIndSids (
	in_dummy					IN	security_pkg.T_SID_ID,
	in_metric_keys				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_keys						security.T_VARCHAR2_TABLE;
BEGIN

	t_keys := security_pkg.Varchar2ArrayToTable(in_metric_keys);

	OPEN out_cur FOR
		SELECT ind_sid, lookup_key
		  FROM ind i, TABLE(t_keys) k
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND UPPER(i.lookup_key) = UPPER(k.value)
		   -- XXX: This security check is crippling performance
		   --AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), i.ind_sid, security_pkg.PERMISSION_READ) = 1
	;
END;

PROCEDURE SyncFilterAggregateTypes
AS
	v_customer_aggregate_type_id	NUMBER;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit metrics');
	END IF;

	FOR r IN (
		SELECT im.initiative_metric_id
		  FROM initiative_metric im
		  LEFT JOIN chain.customer_aggregate_type cuat ON im.initiative_metric_id = cuat.initiative_metric_id AND cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_INITIATIVES
		 WHERE cuat.customer_aggregate_type_id IS NULL
	) LOOP
		v_customer_aggregate_type_id := chain.filter_pkg.UNSEC_AddCustomerAggregateType(
			in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_INITIATIVES,
			in_initiative_metric_id		=> r.initiative_metric_id
		);
	END LOOP;

	FOR r IN (
		SELECT customer_aggregate_type_id
		  FROM chain.customer_aggregate_type
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_INITIATIVES
		   AND initiative_metric_id IS NOT NULL
		   AND initiative_metric_id NOT IN (
			SELECT im.initiative_metric_id
			  FROM initiative_metric im
			)
	) LOOP
		chain.filter_pkg.UNSEC_RemoveCustomerAggType(r.customer_aggregate_type_id);
	END LOOP;
END;

PROCEDURE AddInitiativeMetric(
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	initiative_metric.label%TYPE,
	in_is_during				IN	initiative_metric.is_during%TYPE,
	in_is_running				IN	initiative_metric.is_running%TYPE,
	in_is_rampable				IN	initiative_metric.is_rampable%TYPE,
	in_per_period_duration		IN	initiative_metric.per_period_duration%TYPE,
	in_one_off_period			IN	initiative_metric.one_off_period%TYPE,
	in_divisibility				IN	initiative_metric.divisibility%TYPE,
	in_lookup_key				IN	initiative_metric.lookup_key%TYPE,
	in_is_external				IN	initiative_metric.is_external%TYPE,
	out_initiative_metric_id	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage initiative metrics');
	END IF;

	INSERT INTO initiative_metric(initiative_metric_id, measure_sid, label, is_during, is_running,
		is_rampable, per_period_duration, one_off_period, divisibility, lookup_key, is_external)
	VALUES(initiative_metric_id_seq.NEXTVAL, in_measure_sid, in_label, in_is_during, in_is_running,
		in_is_rampable, in_per_period_duration, in_one_off_period, in_divisibility, in_lookup_key, in_is_external)
	RETURNING initiative_metric_id INTO out_initiative_metric_id;

	SyncFilterAggregateTypes;
END;

PROCEDURE SaveInitiativeMetric(
	in_initiative_metric_id		IN	security_pkg.T_SID_ID,
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	initiative_metric.label%TYPE,
	in_is_during				IN	initiative_metric.is_during%TYPE,
	in_is_running				IN	initiative_metric.is_running%TYPE,
	in_is_rampable				IN	initiative_metric.is_rampable%TYPE,
	in_per_period_duration		IN	initiative_metric.per_period_duration%TYPE,
	in_one_off_period			IN	initiative_metric.one_off_period%TYPE,
	in_divisibility				IN	initiative_metric.divisibility%TYPE,
	in_lookup_key				IN	initiative_metric.lookup_key%TYPE,
	in_is_external				IN	initiative_metric.is_external%TYPE
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage initiative metrics');
	END IF;

	UPDATE initiative_metric
	   SET measure_sid = in_measure_sid, label = in_label, is_during = in_is_during, is_running = in_is_running,
			is_rampable = in_is_rampable, per_period_duration = in_per_period_duration, one_off_period = in_one_off_period,
			divisibility = in_divisibility, lookup_key = in_lookup_key, is_external = in_is_external
	 WHERE initiative_metric_id = in_initiative_metric_id;
END;

PROCEDURE DeleteInitiativeMetric(
	in_initiative_metric_id		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage initiative metrics');
	END IF;

	DELETE FROM initiative_metric
	 WHERE initiative_metric_id = in_initiative_metric_id;
END;

--
-- INITIATIVE AGGREGATE TAG GROUP
--

PROCEDURE GetAggrTagGroupsAndMembers (
	out_cur_tag_groups				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_tags					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to view aggregate tag groups.');
	END IF;

	OPEN out_cur_tag_groups FOR
		SELECT atg.aggr_tag_group_id, atg.lookup_key, atg.label, DECODE(COUNT(imti.ind_sid), 0, 0, 1) in_use
		  FROM aggr_tag_group atg
		  LEFT JOIN initiative_metric_tag_ind imti ON atg.aggr_tag_group_id = imti.aggr_tag_group_id
		 WHERE atg.app_sid = security_pkg.getapp
		 GROUP BY atg.aggr_tag_group_id, atg.lookup_key, atg.label;

	OPEN out_cur_tags FOR
		SELECT atgm.aggr_tag_group_id, atgm.tag_id, t.tag label
		  FROM aggr_tag_group_member atgm
		  JOIN v$tag t ON atgm.tag_id = t.tag_id
		 WHERE atgm.app_sid = security_pkg.getapp;
END;

PROCEDURE SaveAggregateTagGroup (
	in_aggr_tag_group_id			IN	aggr_tag_group.aggr_tag_group_id%TYPE,
	in_label						IN	aggr_tag_group.label%TYPE,
	in_lookup_key					IN	aggr_tag_group.lookup_key%TYPE,
	in_aggr_tag_group_members		IN	security_pkg.T_SID_IDS
)
AS
	v_tag_group_members				security.T_SID_TABLE;
	v_aggr_tag_group_id				aggr_tag_group.aggr_tag_group_id%TYPE;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to create or edit aggregate tag groups.');
	END IF;

	v_tag_group_members := security_pkg.SidArrayToTable(in_aggr_tag_group_members);

	IF in_aggr_tag_group_id > 0 THEN
		UPDATE aggr_tag_group
		   SET label = in_label, lookup_key = in_lookup_key
		 WHERE aggr_tag_group_id = in_aggr_tag_group_id;

		-- clear out tag group members
		DELETE FROM aggr_tag_group_member WHERE aggr_tag_group_id = in_aggr_tag_group_id;

		INSERT INTO aggr_tag_group_member (app_sid, aggr_tag_group_id, tag_id)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_aggr_tag_group_id, column_value
		  FROM TABLE(v_tag_group_members);
	ELSE
		INSERT INTO aggr_tag_group (aggr_tag_group_id, lookup_key, label)
		VALUES (aggr_tag_group_id_seq.NEXTVAL, in_lookup_key, in_label)
		RETURNING aggr_tag_group_id INTO v_aggr_tag_group_id;

		INSERT INTO aggr_tag_group_member (app_sid, aggr_tag_group_id, tag_id)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), v_aggr_tag_group_id, column_value
		  FROM TABLE(v_tag_group_members);
	END IF;
END;

PROCEDURE DeleteAggregateTagGroup (
	in_aggr_tag_group_id			IN	aggr_tag_group.aggr_tag_group_id%TYPE
)
AS
	v_count 					NUMBER(10);
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to delete aggregate tag groups.');
	END IF;

	SELECT COUNT(aggr_tag_group_id)
	  INTO v_count
	  FROM initiative_metric_tag_ind
	 WHERE aggr_tag_group_id = in_aggr_tag_group_id;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot delete an aggregate tag group that is in use.');
	ELSE
		DELETE FROM aggr_tag_group_member WHERE aggr_tag_group_id = in_aggr_tag_group_id;
		DELETE FROM aggr_tag_group WHERE aggr_tag_group_id = in_aggr_tag_group_id;
	END IF;
END;

--
-- INITIATIVE METRIC MAPPING
--

PROCEDURE GetInitiativeMetricMappingData (
	out_cur_metrics					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_flow_state_groups		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_aggr_tag_groups			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur_metrics FOR
		SELECT initiative_metric_id, label
		  FROM initiative_metric
		 WHERE app_sid = security_pkg.getapp;

	OPEN out_cur_flow_state_groups FOR
		SELECT flow_state_group_id, label
		  FROM flow_state_group
		 WHERE app_sid = security_pkg.getapp;

	OPEN out_cur_aggr_tag_groups FOR
		SELECT aggr_tag_group_id, label
		  FROM aggr_tag_group
		 WHERE app_sid = security_pkg.getapp;
END;

PROCEDURE GetInitiativeMetricMapping (
	out_mappings				OUT	security_pkg.T_OUTPUT_CUR,
	out_agg_tag_groups			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_state_groups		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage metric mappings.');
	END IF;

	OPEN out_mappings FOR
		SELECT m.initiative_metric_id, m.label initiative_metric_label,
			   si.ind_sid, i.description ind_description
		  FROM initiative_metric m
		  JOIN initiative_metric_state_ind si ON si.initiative_metric_id = m.initiative_metric_id
		  JOIN v$ind i ON si.ind_sid = i.ind_sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		UNION
		SELECT m.initiative_metric_id, m.label initiative_metric_label,
			   ti.ind_sid, i.description ind_description
		  FROM initiative_metric m
		  JOIN initiative_metric_tag_ind ti ON ti.initiative_metric_id = m.initiative_metric_id
		  JOIN v$ind i ON ti.ind_sid = i.ind_sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_agg_tag_groups FOR
		SELECT ti.initiative_metric_id, ti.ind_sid,ti.aggr_tag_group_id
		  FROM initiative_metric_tag_ind ti
		 WHERE ti.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_flow_state_groups FOR
		SELECT si.initiative_metric_id, si.ind_sid,si.flow_state_group_id
		  FROM initiative_metric_state_ind si
		 WHERE si.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveInitiativeMetricMapping (
	in_metric_id				IN	initiative_metric.initiative_metric_id%TYPE,
	in_ind_sid					IN	initiative_metric_state_ind.ind_sid%TYPE,
	in_flow_state_group_ids		IN	security_pkg.T_SID_IDS,
	in_aggr_tag_group_ids		IN	security_pkg.T_SID_IDS
)
AS
	v_measure_sid				SECURITY_PKG.T_SID_ID;
	v_flow_state_groups			security.T_SID_TABLE;
	v_aggr_tag_groups			security.T_SID_TABLE;
	v_aggr_ind_group_id			NUMBER(10);
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage metric state mappings.');
	END IF;

	SELECT measure_sid
	  INTO v_measure_sid
	  FROM initiative_metric
	 WHERE initiative_metric_id = in_metric_id;

	-- clear existing mappings before save
	DeleteInitiativeMetricMapping(in_metric_id, in_ind_sid);

	v_flow_state_groups := security_pkg.SidArrayToTable(in_flow_state_group_ids);

	INSERT INTO initiative_metric_state_ind (app_sid, initiative_metric_id, flow_state_group_id, ind_sid, measure_sid, net_period)
		SELECT security_pkg.getapp, in_metric_id, t.column_value flow_state_group_id, in_ind_sid, v_measure_sid, null
		  FROM TABLE(v_flow_state_groups) t;

	v_aggr_tag_groups := security_pkg.SidArrayToTable(in_aggr_tag_group_ids);

	INSERT INTO initiative_metric_tag_ind (app_sid, initiative_metric_id, aggr_tag_group_id, ind_sid, measure_sid)
		SELECT security_pkg.getapp, in_metric_id, t.column_value in_aggr_tag_group_id, in_ind_sid, v_measure_sid
		  FROM TABLE(v_aggr_tag_groups) t;

	v_aggr_ind_group_id := aggregate_ind_pkg.setGroup('INITIATIVE_INDS', 'csr.initiative_aggr_pkg.GetIndicatorValues');

	BEGIN
		INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
		VALUES (v_aggr_ind_group_id, in_ind_sid);
	EXCEPTION
	  WHEN DUP_VAL_ON_INDEX THEN
		NULL; -- Ignore dupes
	END;
	
	indicator_pkg.SetAggregateIndicator(
		in_ind_sid			=> in_ind_sid,
		in_is_aggregate_ind => 1
	);
END;

PROCEDURE DeleteInitiativeMetricMapping (
	in_metric_id				IN	initiative_metric.initiative_metric_id%TYPE,
	in_ind_sid					IN	security_pkg.T_SID_ID
)
AS
	v_aggr_ind_group_id			NUMBER(10);
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to delete metric mappings.');
	END IF;

	v_aggr_ind_group_id := aggregate_ind_pkg.setGroup('INITIATIVE_INDS', 'csr.initiative_aggr_pkg.GetIndicatorValues');

	DELETE FROM initiative_metric_tag_ind WHERE ind_sid = in_ind_sid AND initiative_metric_id = in_metric_id;
	DELETE FROM initiative_metric_state_ind WHERE ind_sid = in_ind_sid AND initiative_metric_id = in_metric_id;

	DELETE FROM aggregate_ind_group_member
	 WHERE ind_sid = in_ind_sid
	   AND aggregate_ind_group_id = v_aggr_ind_group_id
	   AND ind_sid NOT IN (
			SELECT ind_sid
			  FROM initiative_metric_tag_ind
			 UNION
			SELECT ind_sid
			  FROM initiative_metric_state_ind);

	indicator_pkg.SetAggregateIndicator(
		in_ind_sid			=> in_ind_sid,
		in_is_aggregate_ind => 0
	);
END;

END initiative_metric_pkg;
/
