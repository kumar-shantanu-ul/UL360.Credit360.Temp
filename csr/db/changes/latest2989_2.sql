-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

DROP TABLE csr.recent_teamroom;
DROP TABLE csr.user_follower;
DROP TABLE csr.unapproved_val;
DROP TABLE csr.user_survey_response;
DROP TABLE csr.pending_ind_rule;
DROP TABLE csr.validation_rule;
DROP SEQUENCE csr.validation_rule_id_seq;
DROP TABLE csr.val_accuracy;
DROP TABLE csr.val_trigger_fired;
DROP TABLE csr.val_trigger_region;
DROP TABLE csr.val_trigger;
DROP SEQUENCE csr.val_trigger_id_seq;

-- Alter tables

-- added in latest726 but not create_schema, and all NULL on live
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'FLOW'
		   AND column_name = 'DESCRIPTION'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.flow DROP COLUMN description';
	END LOOP;
END;
/

-- has been in create_schema since 2013 but was not in a latest script so not on live and not used
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'FUND'
		   AND column_name = 'SUPPLIER_SID'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.fund DROP COLUMN supplier_sid';
	END LOOP;
END;
/

-- not on live => not used
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'REGION_METRIC'
		   AND column_name = 'LOOKUP_KEY'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.region_metric DROP COLUMN lookup_key';
	END LOOP;
END;
/

-- renamed to XXX_INTERNAL_AUDIT_SID on live and no longer used
BEGIN
	FOR r IN (
		SELECT acc.constraint_name
		  FROM all_cons_columns acc
		  JOIN all_constraints ac ON acc.owner = ac.owner AND acc.constraint_name = ac.constraint_name
		 WHERE acc.owner = 'CSR'
		   AND acc.table_name = 'INTERNAL_AUDIT_FILE_DATA'
		   AND acc.column_name IN ('INTERNAL_AUDIT_SID', 'XXX_INTERNAL_AUDIT_SID')
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.internal_audit_file_data DROP CONSTRAINT ' || r.constraint_name;
	END LOOP;

	FOR r IN (
		SELECT column_name
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'INTERNAL_AUDIT_FILE_DATA'
		   AND column_name IN ('INTERNAL_AUDIT_SID', 'XXX_INTERNAL_AUDIT_SID')
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.internal_audit_file_data DROP COLUMN ' || r.column_name;
	END LOOP;
END;
/

-- not on live => not used
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tab_columns
		 WHERE owner = 'CSRIMP'
		   AND table_name = 'CMS_ALERT_TYPE'
		   AND column_name = 'HELPER_SP'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.cms_alert_type DROP COLUMN helper_sp';
	END LOOP;
END;
/

-- dropped in latest1331 but not removed from the csrimp schema at that time
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tab_columns
		 WHERE owner = 'CSRIMP'
		   AND table_name = 'MODEL_MAP'
		   AND column_name = 'EXCEL_NAME'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.model_map DROP COLUMN excel_name';
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- from C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number,
	error_code, alert, flags, source_id, entry_measure_conversion_id, entry_val_number,
	note, source_type_id, factor_a, factor_b, factor_c, changed_by_sid, changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		   ROUND(COALESCE(mc.a, mcp.a, 1) * POWER(v.entry_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0), 10) val_number,
		   v.error_code,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number,
		   v.note, v.source_type_id,
		   NVL(mc.a, mcp.a) factor_a,
		   NVL(mc.b, mcp.b) factor_b,
		   NVL(mc.c, mcp.c) factor_c,
		   v.changed_by_sid, v.changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);

-- from C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE FORCE VIEW csr.sheet_value_converted
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid,
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited,
	 status, last_sheet_value_change_id, alert, flag, factor_a, factor_b, factor_c,
	 start_dtm, end_dtm, actual_val_number, var_expl_note, is_na) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		 ROUND(COALESCE(mc.a, mcp.a, 1) * POWER(sv.entry_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0), 10) val_number,
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.a, mcp.a) factor_a,
         NVL(mc.b, mcp.b) factor_b,
         NVL(mc.c, mcp.c) factor_c,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number, var_expl_note,
		 sv.is_na
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
;

-- from C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE FORCE VIEW csr.PENDING_VAL_CONVERTED (
	pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id,
	 val_number, val_string, from_val_number, from_measure_conversion_id, action,
	 factor_a, factor_b, factor_c, start_dtm, end_dtm, actual_val_number
) AS
  SELECT pending_val_id, pending_ind_id, pending_region_id, pv.pending_period_id, approval_step_id,
	     COALESCE(mc.a, mcp.a, 1) * POWER(pv.from_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0) val_number,
		val_string,
		from_val_number,
		from_measure_conversion_id,
		action,
	    NVL(mc.a, mcp.a) factor_a,
	    NVL(mc.b, mcp.b) factor_b,
	    NVL(mc.c, mcp.c) factor_c,
	    pp.start_dtm,
	    pp.end_dtm,
	    pv.val_number actual_val_number
    FROM pending_val pv, pending_period pp, measure_conversion mc, measure_conversion_period mcp
   WHERE pp.pending_period_id = pv.pending_period_id
     AND pv.from_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (pp.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (pp.start_dtm < mcp.end_dtm or mcp.end_dtm is null);

-- from C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$imp_val_mapped AS
	SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm,
		   ii.description ind_description,
		   i.description maps_to_ind_description,
		   ir.description region_description,
		   i.aggregate,
		   iv.val,
		   COALESCE(mc.a, mcp.a, 1) factor_a,
		   COALESCE(mc.b, mcp.b, 1) factor_b,
		   COALESCE(mc.c, mcp.c, 0) factor_c,
		   m.description measure_description,
		   im.maps_to_measure_conversion_id,
		   mc.description from_measure_description,
		   NVL(i.format_mask, m.format_mask) format_mask,
		   ir.maps_to_region_sid,
		   iv.rowid rid,
		   ii.app_Sid, iv.note,
		   CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
		   icv.imp_conflict_id,
		   m.measure_sid,
		   iv.imp_ind_id, iv.imp_region_id,
		   CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
	  FROM imp_val iv
		   JOIN imp_ind ii
		   		 ON iv.imp_ind_id = ii.imp_ind_id
		   		AND iv.app_sid = ii.app_sid
		   		AND ii.maps_to_ind_sid IS NOT NULL
		   JOIN imp_region ir
		  		 ON iv.imp_region_id = ir.imp_region_id
		   		AND iv.app_sid = ir.app_sid
		   		AND ir.maps_to_region_sid IS NOT NULL
	  LEFT JOIN imp_measure im
	      		 ON iv.imp_ind_id = im.imp_ind_id
	      		AND iv.imp_measure_id = im.imp_measure_id
	      		AND iv.app_sid = im.app_sid
	  LEFT JOIN measure_conversion mc
				 ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
				AND im.app_sid = mc.app_sid
      LEFT JOIN measure_conversion_period mcp
				 ON mc.measure_conversion_id = mcp.measure_conversion_id
				AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
				AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
	  LEFT JOIN imp_conflict_val icv
				 ON iv.imp_val_id = icv.imp_val_id
				AND iv.app_sid = icv.app_sid
		   JOIN v$ind i
				 ON ii.maps_to_ind_sid = i.ind_sid
				AND ii.app_sid = i.app_sid
				AND i.ind_type = 0
	  LEFT JOIN region_metric rm
				 ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
			   JOIN measure m
				 ON i.measure_sid = m.measure_sid
				AND i.app_sid = m.app_sid;

-- from C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
			fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
			fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
			COALESCE(
				fv.description,
				CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' END,
				r.description,
				cu.full_name,
				cr.name,
				fv.str_value
			) description,
			ff.group_by_index,
			f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
			fv.filter_type, fv.null_filter
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\setup_body
@..\chain\type_capability_body
@..\comp_regulation_report_body
@..\comp_requirement_report_body
@..\csr_app_body
@..\energy_star_body
@..\energy_star_job_body
@..\incident_body
@..\indicator_body
@..\initiative_body
@..\initiative_grid_body
@..\issue_report_body
@..\measure_body
@..\meter_alarm_stat_body
@..\meter_body
@..\quick_survey_body
@..\region_body
@..\stored_calc_datasource_body
@..\teamroom_body
@..\templated_report_body

@update_tail
