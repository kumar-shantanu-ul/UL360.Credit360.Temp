-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COMPLIANCE_LOG_IDS (
	FLOW_STATE_LOG_ID	NUMBER(10)		NOT NULL,
	AUDIT_DTM			DATE			NOT NULL
) ON COMMIT DELETE ROWS;

ALTER TABLE csr.compliance_item_region ADD (
	CONSTRAINT uk_comp_item_reg_flow_item_id UNIQUE (app_sid, flow_item_id)
);

CREATE SEQUENCE CSR.ISSUE_COMPLIANCE_REGION_ID_SEQ;

CREATE TABLE CSR.ISSUE_COMPLIANCE_REGION (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_COMPLIANCE_REGION PRIMARY KEY (APP_SID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT FK_ISSUE_CMP_REG_CMP_ITM_REG FOREIGN KEY (APP_SID, FLOW_ITEM_ID)
		REFERENCES CSR.COMPLIANCE_ITEM_REGION (APP_SID, FLOW_ITEM_ID)
);

CREATE TABLE CSRIMP.ISSUE_COMPLIANCE_REGION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10) NOT NULL,
	FLOW_ITEM_ID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_COMPLIANCE_REGION PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT FK_ISSUE_COMPLIANCE_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_COMPLIANCE_REGION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_COMPLIANCE_REGION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_COMPLIANCE_REGION UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_COMPLIANCE_REG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;
ALTER TABLE CSR.ISSUE ADD (
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10),
	CONSTRAINT FK_ISS_ISS_COMPL_REG FOREIGN KEY (APP_SID, ISSUE_COMPLIANCE_REGION_ID)
		REFERENCES CSR.ISSUE_COMPLIANCE_REGION (APP_SID, ISSUE_COMPLIANCE_REGION_ID),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		CASE WHEN ISSUE_PENDING_VAL_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SHEET_VALUE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SURVEY_ANSWER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_NON_COMPLIANCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_ACTION_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ALARM_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_RAW_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_DATA_SOURCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_MISSING_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SUPPLIER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_INITIATIVE_ID IS NOT NULL THEN 1 ELSE 0 END + 
		CASE WHEN ISSUE_COMPLIANCE_REGION_ID IS NOT NULL THEN 1 ELSE 0 END
		IN (0, 1)
	)
);

ALTER TABLE CSRIMP.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;
ALTER TABLE CSRIMP.ISSUE ADD (
	ISSUE_COMPLIANCE_REGION_ID		NUMBER(10),
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		CASE WHEN ISSUE_PENDING_VAL_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SHEET_VALUE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SURVEY_ANSWER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_NON_COMPLIANCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_ACTION_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ALARM_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_RAW_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_DATA_SOURCE_ID IS NOT NULL THEN 1 ELSE 0 END +		
		-- pending new columns
		-- CASE WHEN ISSUE_METER_MISSING_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SUPPLIER_ID IS NOT NULL THEN 1 ELSE 0 END +
		-- CASE WHEN ISSUE_INITIATIVE_ID IS NOT NULL THEN 1 ELSE 0 END
		CASE WHEN ISSUE_COMPLIANCE_REGION_ID IS NOT NULL THEN 1 ELSE 0 END
		IN (0, 1)
	)
);

ALTER TABLE csr.temp_issue_search ADD (
	ISSUE_COMPLIANCE_REGION_ID	NUMBER(10)
);

CREATE INDEX csr.ix_issue_issue_complia ON csr.issue (app_sid, issue_compliance_region_id);
CREATE INDEX csr.ix_issue_complia_flow_item_id ON csr.issue_compliance_region (app_sid, flow_item_id);

-- *** Grants ***
-- FB106635 missing grants.
GRANT SELECT ON csr.tpl_report_tag_dataview TO chain;
GRANT SELECT ON csr.tpl_report_tag_logging_form TO chain;

grant select,insert,update,delete on csrimp.issue_compliance_region to tool_user;
grant select on csr.issue_compliance_region_id_seq to csrimp;
grant insert on csr.issue_compliance_region to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- ../create_views.sql
CREATE OR REPLACE VIEW csr.v$flow_item_transition AS 
  SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb,
		 fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
		 tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
		 fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path,
		 tfs.flow_state_nature_id,
		 fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
      FROM flow_item fi
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
		JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;

  CREATE OR REPLACE VIEW csr.v$flow_item_trans_role_member AS 
  SELECT fit.app_sid,fit.flow_sid,fit.flow_item_id,fit.flow_state_transition_id,fit.verb,fit.from_state_id,fit.from_state_label,
  		 fit.from_state_colour,fit.to_state_id,fit.to_state_label,fit.to_state_colour,fit.ask_for_comment,fit.transition_pos,
		 fit.button_icon_path,fit.survey_response_id,fit.dashboard_instance_id, r.role_sid, r.name role_name, rrm.region_sid, fit.flow_state_nature_id
	FROM v$flow_item_transition fit
		 JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
		 JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
		 JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid
   WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour,
	   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, 
	   c.more_info_1 correspondent_more_info_1, sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, 
	   ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, 
	   ist.enable_manual_comp_date, ist.comment_is_optional, ist.due_date_is_mandatory, ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, 
	   ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, 
	   i.first_priority_set_dtm, issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id,
	   issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id, issue_compliance_region_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Compliance Legal Register Filter';
	v_class := 'Credit360.Compliance.Cards.LegalRegisterFilter';
	v_js_path := '/csr/site/compliance/filters/LegalRegisterFilter.js';
	v_js_class := 'Credit360.Compliance.Filters.LegalRegisterFilter';
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
	security.user_pkg.LogonAdmin;
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(49, 'Compliance Register Filter', 'Allows filtering of local compliance items in the legal register', 'csr.compliance_register_report_pkg', '/csr/site/compliance/LegalRegister.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Compliance.Filters.LegalRegisterFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Compliance Legal Register Filter', 'csr.compliance_register_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.compliance_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 49, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
		 VALUES (49, 1, 'Number of items');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 2, 'Number of regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 3, 'Number of open regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 4, 'Number of requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 5, 'Number of open requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 6, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 7, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 8, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (49, 9, 'Number of closed actions');
		 
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	     VALUES (49, 1, 1, 'Compliance item region');
END;
/

BEGIN
	UPDATE csr.compliance_item_source
	   SET description = 'User-entered'
	 WHERE description = 'User entered';
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.compliance_register_report_pkg AS END;
/
	
GRANT EXECUTE ON csr.compliance_register_report_pkg to web_user;
GRANT EXECUTE ON csr.compliance_register_report_pkg to chain;


-- *** Conditional Packages ***

-- *** Packages ***
@@../csr_data_pkg
@@../compliance_pkg
@@../chain/filter_pkg
@@../compliance_library_report_pkg
@@../compliance_register_report_pkg
@@../schema_pkg
@@../csrimp/imp_pkg

@@../csr_app_body
@@../compliance_body
@@../compliance_library_report_body
@@../compliance_register_report_body
@@../enable_body
@@../schema_body
@@../csrimp/imp_body
@@../issue_body
@@../flow_body

@update_tail
