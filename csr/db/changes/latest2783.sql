-- Please update version.sql too -- this keeps clean builds in sync
define version=2783
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.filter_page_column (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	column_name				VARCHAR2(255) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	width					NUMBER(10) DEFAULT 150 NOT NULL,
	fixed_width				NUMBER(1) DEFAULT 0 NOT NULL,
	hidden					NUMBER(1) DEFAULT 0 NOT NULL,
	group_sid				NUMBER(10),
	CONSTRAINT pk_filter_page_column PRIMARY KEY (app_sid, card_group_id, column_name),
	CONSTRAINT chk_fltr_pg_col_fix_width_1_0 CHECK (fixed_width IN (1, 0)),
	CONSTRAINT chk_fltr_pg_col_hidden_1_0 CHECK (hidden IN (1, 0)),
	CONSTRAINT fk_fltr_pkg_col_app_sid FOREIGN KEY (app_sid)
		REFERENCES csr.customer (app_sid),
	CONSTRAINT fk_fltr_pg_col_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_fltr_pg_col_group_sid FOREIGN KEY (group_sid)
		REFERENCES security.group_table (sid_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.chain_filter_page_column (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	column_name				VARCHAR2(255) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	width					NUMBER(10) DEFAULT 150 NOT NULL,
	fixed_width				NUMBER(1) DEFAULT 0 NOT NULL,
	hidden					NUMBER(1) DEFAULT 0 NOT NULL,
	group_sid				NUMBER(10),
	CONSTRAINT pk_filter_page_column PRIMARY KEY (csrimp_session_id, card_group_id, column_name),
	CONSTRAINT chk_fltr_pg_col_fix_width_1_0 CHECK (fixed_width IN (1, 0)),
	CONSTRAINT chk_fltr_pg_col_hidden_1_0 CHECK (hidden IN (1, 0)),
	CONSTRAINT fk_chain_fltr_page_column_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.plugin ADD (
	SAVED_FILTER_SID		NUMBER(10, 0),
	RESULT_MODE				NUMBER(10, 0)
);

ALTER TABLE csrimp.plugin ADD (
	SAVED_FILTER_SID		NUMBER(10, 0),
	RESULT_MODE				NUMBER(10, 0)
);

ALTER TABLE csr.score_threshold MODIFY (background_colour NULL);


BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.customer ADD status_from_parent_on_subdeleg NUMBER(1, 0) DEFAULT 0 NOT NULL';
EXCEPTION
	WHEN OTHERS THEN
		IF (SQLCODE = -1430) THEN
			null; -- No worries, table already has the column
		ELSE
			RAISE;
		END IF;
END;
/
-- I'm renaming chk_plugin_cms_tab_form to ck_plugin_refs because it's only one-third to do with cms now.
ALTER TABLE csr.plugin
ADD CONSTRAINT ck_plugin_refs 
	CHECK (
		(
			tab_sid IS NULL AND form_path IS NULL AND
			group_key IS NULL AND 
			saved_filter_sid IS NULL AND
			control_lookup_keys IS NULL
		) OR (
			app_sid IS NOT NULL AND
			(
				(
					tab_sid IS NOT NULL AND form_path IS NOT NULL AND 
					group_key IS NULL AND
					saved_filter_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NOT NULL AND
					saved_filter_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NULL AND
					saved_filter_sid IS NOT NULL
				)
			)
		)
	);

ALTER TABLE csr.plugin
DROP CONSTRAINT chk_plugin_cms_tab_form;

DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid);

ALTER TABLE csr.temp_initiative ADD (
	POS						NUMBER(10)
);

ALTER TABLE chain.tt_filter_object_data ADD (filter_value_id NUMBER(10));
ALTER TABLE chain.tt_filter_object_data DROP CONSTRAINT pk_filter_obj_data DROP INDEX;
ALTER TABLE chain.tt_filter_object_data ADD CONSTRAINT uk_filter_obj_data UNIQUE (data_type_id, agg_type_id, object_id, filter_value_id);

grant select, references on csr.ind to chain;
grant select, references on csr.initiative_metric to chain;

grant select on chain.aggregate_type to csr;
grant select on csr.v$ind to chain;

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT chk_svd_fil_agg_type;
ALTER TABLE chain.saved_filter_aggregation_type ADD (
	initiative_metric_id	NUMBER(10),
	ind_sid					NUMBER(10),
	CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL))
);

ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT FK_SVD_FIL_AGG_TYP_INIT_METRIC
	FOREIGN KEY (APP_SID, INITIATIVE_METRIC_ID)
	REFERENCES CSR.INITIATIVE_METRIC(APP_SID, INITIATIVE_METRIC_ID)
	ON DELETE CASCADE;
	
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT FK_SVD_FIL_AGG_TYP_IND
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND(APP_SID, IND_SID)
	ON DELETE CASCADE;

ALTER TABLE csr.customer
ADD tolerance_checker_req_merged NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.customer
ADD CONSTRAINT ck_customer_tol_chk_req_mrgd CHECK (tolerance_checker_req_merged IN (0, 1, 2));

-- Now CSRIMP

ALTER TABLE csrimp.customer
ADD tolerance_checker_req_merged NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.customer
ADD CONSTRAINT ck_customer_tol_chk_req_mrgd CHECK (tolerance_checker_req_merged IN (0, 1, 2));
	
-- *** Grants ***
grant select, insert, update on chain.filter_page_column to csrimp;
grant select, insert, update, delete on csrimp.chain_filter_page_column to web_user;
grant select on chain.filter_page_column to csr;

-- ** Cross schema constraints ***
ALTER TABLE csr.plugin 
ADD CONSTRAINT fk_plugin_saved_filter 
FOREIGN KEY (app_sid, saved_filter_sid) 
REFERENCES chain.saved_filter(app_sid, saved_filter_sid);

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
CREATE OR REPLACE FORCE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, 
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_ind_id, r.active, r.region_type
	  FROM all_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id, atg.group_coordinator_noun,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label, ncst.format_mask nc_score_format_mask
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL 
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;
	 
CREATE OR REPLACE VIEW csr.v$my_initiatives AS
	SELECT  i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		r.role_sid, r.name role_name,
		MAX(fsr.is_editable) is_editable,
		rg.active,
		null owner_sid, i.internal_ref, i.name, i.project_sid
		FROM  region_role_member rrm
		JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
		JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
		JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
		JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
		JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
	 WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		r.role_sid, r.name,
		rg.active, i.internal_ref, i.name, i.project_sid
	 UNION ALL
	SELECT  i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		null role_sid,  null role_name,
		MAX(igfs.is_editable) is_editable,
		rg.active,
		iu.user_sid owner_sid, i.internal_ref, i.name, i.project_sid
		FROM initiative_user iu
		JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		JOIN initiative_project_user_group ipug 
		ON iu.initiative_user_group_id = ipug.initiative_user_group_id
		 AND iu.project_sid = ipug.project_sid
		JOIN initiative_group_flow_state igfs
		ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
		 AND ipug.project_sid = igfs.project_sid
		 AND ipug.app_sid = igfs.app_sid
		 AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
		JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
		LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
	 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		rg.active, iu.user_sid, i.internal_ref, i.name, i.project_sid;

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset, 
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id, 
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, nvl(dd.description, d.name) as description, dp.submit_confirmation_text as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;

CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset, 
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id, 
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT app_sid, delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml, note, group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset, 
			   is_note_mandatory, section_xml, editing_url, fully_delegated, grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period, delegation_date_schedule_id, layout_id, 
			   tag_visibility_matrix_group_id, period_set_id, period_interval_id, submission_offset, allow_multi_period, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;
	  
-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('CHAIN_FILTER_PAGE_COLUMN')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'FILTER_PAGE_COLUMN'
    );
    FOR I IN 1 .. v_list.count
 	LOOP
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23) || '_POLICY', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

-- Data
BEGIN
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class,
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Finding List',  '/csr/site/audit/controls/NonComplianceListTab.js', 'Audit.Controls.NonComplianceListTab',
			         'Credit360.Audit.Plugins.NonComplianceList', 'This tab shows a filterable list of findings.', NULL, NULL, NULL);
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin
		   SET description = 'Non-Compliance List',
		   	   js_include = '/csr/site/audit/controls/NonComplianceListTab.js',
			   cs_class = 'Credit360.Audit.Plugins.NonComplianceList',
		   	   details = 'This tab shows a filterable list of non-compliances.'
		 WHERE plugin_type_id = 13
		   AND js_class = 'Audit.Controls.NonComplianceListTab'
		   AND app_sid IS NULL
		   AND tab_sid IS NULL;
	END;
END;
/

DECLARE
	v_capability_id					NUMBER(10);
	v_card_group_id					NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;

	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE capability_type_id = 0
	   AND capability_name = 'Create company user without invitation';
	   
	UPDATE chain.card_group_card
	   SET required_capability_id = v_capability_id
	 WHERE card_group_id = (
		SELECT card_group_id
		  FROM chain.card_group
		 WHERE name = 'Company Invitation Wizard'
	 )
	   AND card_id IN (
		SELECT card_id
		  FROM chain.card
		 WHERE description IN (
			'Choose between creating new company or searching for and selecting existing company by company type',
			'Choose between adding new contacts or proceeding without adding any contacts',
			'Add new contacts',
			'Personalize invitation e-mail'
		 )
	 );
END;
/

-- FB 73431
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28168, 5, 'BBL', 6.28981056977507008421427, 1, 0, 1);
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28169, 24, '1/BBL', 0.1589873, 1, 0, 1);

-- FB 72407
INSERT INTO csr.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) 
	VALUES (37, 'm.kg^-1', 'm.kg^-1', 0, '#,##0', 'sum', NULL, 0, 1, -1, 0, 0, 0, 0, 0);
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
	VALUES (28170, 13, 'mm/hectare', 10000000, 1, 0, 1);	
INSERT INTO csr.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) 
	VALUES (28171, 37, 'mm/tonne', 1000000, 1, 0, 1);

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Credit360.Property.Filters.PropertyFilter
	v_desc := 'Initiative Filter';
	v_class := 'Credit360.Initiatives.Cards.InitiativeFilter';
	v_js_path := '/csr/site/initiatives/filters/InitiativeFilter.js';
	v_js_class := 'Credit360.Initiatives.Filters.InitiativeFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	WHERE card_id = v_card_id
	AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(45, 'Initiative Filter', 'Allows filtering of initiatives', 'csr.initiative_report_pkg', '/csr/site/initiatives/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Initiatives.Filters.InitiativeFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Initiative Filter', 'csr.initiative_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.initiatives_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 45, v_card_id, 0);
	END LOOP;
END;
/

INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
     VALUES (45, 1, 'Number of initiatives');
	 
-- Replaced constants with vals for change script.
-- INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
-- VALUES (chain.filter_pkg.FILTER_TYPE_INITIATIVES, csr.initiative_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Initiative region');
INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
VALUES (45, 1, 1, 'Initiative region');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (8, 'Set tolerance checker data requirement', 'Sets the tolerance checker requirement in regards to merged data. See wiki for details.', 'SetToleranceChkrMergedDataReq', 'W2405');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (8, 'Setting value (0 off, 1 merged, 2 submit)', 'The (side wide) setting to use.', 0);

BEGIN
	security.user_pkg.logonadmin();
END;
/

BEGIN
  FOR r IN (
    SELECT UNIQUE so.application_sid_id, c.name customername, so.sid_id, so.name, m.action, host
      FROM SECURITY.SECURABLE_OBJECT  so
      JOIN security.menu m on m.sid_id=so.sid_id
      JOIN csr.customer c on c.app_sid=so.application_sid_id
     WHERE class_id= (SELECT class_id FROM security.securable_object_class WHERE class_name='Menu')
       AND m.action LIKE '%text/admin/list.%'
       AND so.name LIKE 'csr_%'
     ORDER BY c.name)
  LOOP
    --dbms_output.put_line(r.host||': SO '||r.name);
    security.securableobject_pkg.RenameSO(security.security_pkg.getACT, r.sid_id, 'csr_text_admin_list');
  END LOOP;
END;
/

BEGIN
  FOR r IN (
    SELECT UNIQUE so.application_sid_id, c.name customername, so.sid_id, so.name, m.action, host
      FROM SECURITY.SECURABLE_OBJECT  so
      JOIN security.menu m on m.sid_id=so.sid_id
      JOIN csr.customer c on c.app_sid=so.application_sid_id
     WHERE class_id= (SELECT class_id FROM security.securable_object_class WHERE class_name='Menu')
       AND m.action LIKE '%text/admin/list2.%'
       AND so.name LIKE 'csr_%'
     ORDER BY c.name)
  LOOP
    --dbms_output.put_line(r.host||': SO '||r.name);
    security.securableobject_pkg.RenameSO(security.security_pkg.getACT, r.sid_id, 'csr_text_admin_list2');
  END LOOP;
END;
/
-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.initiative_report_pkg AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY csr.initiative_report_pkg AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/
GRANT EXECUTE ON csr.initiative_report_pkg TO web_user;
GRANT EXECUTE ON csr.initiative_report_pkg TO chain;

-- *** Packages ***
@../plugin_pkg
@..\delegation_pkg
@..\audit_pkg
@..\indicator_pkg
@..\chain\filter_pkg
@..\initiative_pkg
@..\initiative_report_pkg
@..\initiative_grid_pkg
@..\property_report_pkg
@..\schema_pkg
@../util_script_pkg
@../sheet_pkg

@..\calc_body
@..\imp_body
@..\enable_body
@../csr_app_body
@../csrimp/imp_body
@../sheet_body
@../delegation_body
@../deleg_plan_body
@../util_script_body
@..\chain\filter_body
@..\initiative_body
@..\initiative_report_body
@..\initiative_grid_body
@..\property_report_body
@..\non_compliance_report_body
@..\schema_body
@..\audit_body
@..\indicator_body
@..\audit_report_body
@..\chain\company_body
@..\chain\company_filter_body
@..\quick_survey_body
@..\property_body
@..\chain\setup_body
@../plugin_body
@..\section_search_pkg
@..\section_search_body

@update_tail
