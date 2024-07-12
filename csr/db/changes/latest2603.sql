-- Please update version.sql too -- this keeps clean builds in sync
define version=2603
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE (
	APP_SID				NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SAVED_FILTER_SID	NUMBER(10, 0)    NOT NULL,
	POS					NUMBER(10, 0)    NOT NULL,
	AGGREGATION_TYPE	NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_SAVED_FIL_AGGREGATION_TYP PRIMARY KEY (APP_SID, SAVED_FILTER_SID, POS)
)
;

CREATE TABLE CSRIMP.CHAIN_SAVED_FILTER_AGG_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SAVED_FILTER_SID	NUMBER(10, 0)    NOT NULL,
	POS					NUMBER(10, 0)    NOT NULL,
	AGGREGATION_TYPE	NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_CHAIN_SAVED_FIL_AGG_TYP PRIMARY KEY (CSRIMP_SESSION_ID, SAVED_FILTER_SID, POS),
	CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP UNIQUE (CSRIMP_SESSION_ID, SAVED_FILTER_SID, AGGREGATION_TYPE),
	CONSTRAINT FK_CHAIN_SAVED_FIL_AGG_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
)
;


-- Alter tables
ALTER TABLE chain.filter_value ADD (
	compound_filter_id_value		NUMBER(10),
	CONSTRAINT fk_filter_value_comp_filter FOREIGN KEY (app_sid, compound_filter_id_value)
		REFERENCES chain.compound_filter (app_sid, compound_filter_id) ON DELETE CASCADE
);

ALTER TABLE csrimp.chain_filter_value ADD (
	compound_filter_id_value		NUMBER(10)
);

create index csr.ix_non_comp_non_comp_type on csr.non_compliance (app_sid, non_compliance_type_id);
create index csr.ix_non_comp_defa_non_complianc on csr.non_comp_default (app_sid, non_compliance_type_id);
create index csr.ix_non_comp_type_internal_audi on csr.non_comp_type_audit_type (app_sid, internal_audit_type_id);
create index csr.ix_int_audit_type_group on csr.internal_audit_type (app_sid, internal_audit_type_group_id);
create index csr.ix_internal_audi_nc_score_type on csr.internal_audit_type (app_sid, nc_score_type_id);
create index chain.ix_filter_value_compound_filt on chain.filter_value (app_sid, compound_filter_id_value); 

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE table_owner = 'CSR'
	   AND table_name = 'INTERNAL_AUDIT'
	   AND (owner, index_name) IN (
		SELECT index_owner, index_name
		  FROM all_ind_columns
		 WHERE  table_owner = 'CSR'
		   AND table_name = 'INTERNAL_AUDIT'
		   AND column_name = 'APP_SID'
		   AND column_position = 1
		)
	   AND (owner, index_name) IN (
		SELECT index_owner, index_name
		  FROM all_ind_columns
		 WHERE  table_owner = 'CSR'
		   AND table_name = 'INTERNAL_AUDIT'
		   AND column_name = 'AUDITOR_USER_SID'
		   AND column_position = 2
		);
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'create index csr.ix_internal_audi_auditor_user_ on csr.internal_audit (app_sid, auditor_user_sid)';
	END IF;
END;
/

ALTER TABLE CHAIN.SAVED_FILTER MODIFY COMPOUND_FILTER_ID NULL;
ALTER TABLE CHAIN.SAVED_FILTER ADD GROUP_BY_COMPOUND_FILTER_ID NUMBER(10);
ALTER TABLE CHAIN.SAVED_FILTER ADD SEARCH_TEXT VARCHAR2(255);
ALTER TABLE CHAIN.SAVED_FILTER ADD CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID 
    FOREIGN KEY (APP_SID, GROUP_BY_COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;
CREATE INDEX CHAIN.IX_SAVED_FIL_GB_CMP_FIL_ID ON CHAIN.SAVED_FILTER(APP_SID, GROUP_BY_COMPOUND_FILTER_ID)
;
-- no index for this FK because it's included in SAVED_FILTER_AGGREGATION_TYPE's primary key
ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE ADD CONSTRAINT FK_SAVED_FILTER_AGG_SAVED 
    FOREIGN KEY (APP_SID, SAVED_FILTER_SID)
    REFERENCES CHAIN.SAVED_FILTER(APP_SID, SAVED_FILTER_SID)
;
ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE ADD CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP
	UNIQUE (APP_SID, SAVED_FILTER_SID, AGGREGATION_TYPE)
;
ALTER TABLE CSRIMP.CHAIN_SAVED_FILTER MODIFY COMPOUND_FILTER_ID NULL;
ALTER TABLE CSRIMP.CHAIN_SAVED_FILTER ADD GROUP_BY_COMPOUND_FILTER_ID NUMBER(10);
ALTER TABLE CSRIMP.CHAIN_SAVED_FILTER ADD SEARCH_TEXT VARCHAR2(255);


-- *** Grants ***
grant select, references on chain.saved_filter_aggregation_type to csr;
grant select, insert, update, delete on csrimp.chain_saved_filter_agg_type to web_user;
grant select, insert, update on chain.saved_filter_aggregation_type to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;
	  
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref,
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, ncst.max_score nc_max_score, ncst.label nc_score_label, ncst.format_mask nc_score_format_mask
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
	  JOIN csr.csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
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

CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

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
		   AND t.table_name IN ('CHAIN_SAVED_FILTER_AGG_TYPE')
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

-- Data
UPDATE chain.card
   SET description = 'Non-compliance Filter Adapter',
       class_type = 'Credit360.Audit.Cards.NonComplianceFilterAdapter',
	   js_class_type = 'Credit360.Audit.Filters.NonComplianceFilterAdapter',
	   js_include = '/csr/site/audit/nonComplianceFilterAdapter.js'
 WHERE js_class_type = 'Credit360.Audit.Filters.NonComplianceAuditFilterAdapter';
 
UPDATE chain.card
   SET description = 'Internal Audit Filter Adapter',
       class_type = 'Credit360.Audit.Cards.AuditFilterAdapter',
	   js_class_type = 'Credit360.Audit.Filters.AuditFilterAdapter',
	   js_include = '/csr/site/audit/auditFilterAdapter.js'
 WHERE js_class_type = 'Credit360.Audit.Filters.AuditNonComplianceFilterAdapter';
 
UPDATE chain.filter_type
   SET description = 'Internal Audit Filter Adapter'
 WHERE description = 'Internal Audit Non-compliance Filter Adapter';
 
UPDATE chain.filter_type
   SET description = 'Non-compliance Filter Adapter'
 WHERE description = 'Non-compliance Audit Filter Adapter';
 
-- output from chain.card_pkg.dumpcard
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN	
	-- Credit360.Issues.Filters.IssuesFilterAdapter
	v_desc := 'Issue Filter Adapter';
	v_class := 'Credit360.Issues.Cards.IssuesFilterAdapter';
	v_js_path := '/csr/site/issues/IssuesFilter.jsi';
	v_js_class := 'Credit360.Issues.Filters.IssuesFilterAdapter';
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
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
BEGIN
	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Issues.Filters.IssuesFilterAdapter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Issue Filter Adapter', 'csr.issue_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	SELECT card_group_id
	  INTO v_group_id
	  FROM chain.card_group
	 WHERE LOWER(name) = LOWER('Issues Filter');
	
	FOR r IN (
		SELECT c.host, MAX(cgc.position) pos
		  FROM csr.customer c 
		  JOIN chain.card_group_card cgc ON c.app_sid = cgc.app_sid
		 WHERE cgc.card_group_id = v_group_id
		 GROUP BY c.host
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			INSERT INTO chain.card_group_card
			(card_group_id, card_id, position)
			VALUES
			(v_group_id, v_card_id, r.pos+1);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
		
	END LOOP;	
	security.user_pkg.logonadmin;
END;
/


-- Move all filters into charts / dataviews folders
-- We can use security.securableobject_pkg.MoveSO on the folders as they are
-- containers without security helper packages so don't need the CSR pacakges to compile
--
-- FOR REVIEW
-- ----------
--
-- There is no data on live that would have a duplicate name exception when this runs
-- but it would be possible (but very unlikely) on externally hosted systems / dev laptops. Do we need
-- to be more defensive?
DECLARE
	v_filters_sid		security.security_pkg.T_SID_ID;
	v_dataviews_sid		security.security_pkg.T_SID_ID;
	v_duplicates 		NUMBER;
	v_name				varchar2(2048);
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Move filters for super admins first as they don't have an application_sid on their SO
	-- It's not a good idea for super admins to store things against their personal SO, but
	-- this script ought to handle it
	FOR r IN (
		SELECT fso.sid_id filter_folder_sid, cso.sid_id charts_folder_sid
		  FROM csr.superadmin sa
		  JOIN security.securable_object cso
		    ON sa.csr_user_sid = cso.parent_sid_id
		   AND cso.name = 'Charts'
		  JOIN security.securable_object fso
		    ON sa.csr_user_sid = fso.parent_sid_id
		   AND fso.name = 'Filters'
		 WHERE fso.sid_id IN (
			SELECT DISTINCT parent_sid
			  FROM chain.saved_filter
		 )
	) LOOP
		security.securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY','ACT'), r.filter_folder_sid, r.charts_folder_sid);
	END LOOP;
	
	FOR c IN (
		SELECT host, app_sid
		  FROM csr.customer
		 WHERE app_sid IN (SELECT DISTINCT app_sid FROM chain.saved_filter)
	) LOOP
		security.user_pkg.LogonAdmin(c.host);
		
		-- Move shared filters to Dataviews
		BEGIN
			v_filters_sid	:= security.securableobject_pkg.GetSIDFROMPath(SYS_CONTEXT('SECURITY','ACT'),c.app_sid,'Filters');
			v_dataviews_sid	:= security.securableobject_pkg.GetSIDFROMPath(SYS_CONTEXT('SECURITY','ACT'),c.app_sid,'Dataviews');
			security.securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY','ACT'), v_filters_sid, v_dataviews_sid);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
		
		-- Move user's filters
		FOR r IN (
			SELECT fso.sid_id filter_folder_sid, cso.sid_id charts_folder_sid
			  FROM csr.csr_user cu
			  JOIN security.securable_object cso
				ON cu.csr_user_sid = cso.parent_sid_id
			   AND cso.name = 'Charts'
			  JOIN security.securable_object fso
				ON cu.csr_user_sid = fso.parent_sid_id
			   AND fso.name = 'Filters'
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND fso.sid_id IN (
				SELECT DISTINCT parent_sid
				  FROM chain.saved_filter
			 )
		) LOOP
			security.securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY','ACT'), r.filter_folder_sid, r.charts_folder_sid);
		END LOOP;
		
	END LOOP;
	
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT saved_filter_sid, name, parent_sid
		  FROM chain.saved_filter
	) LOOP
		
		-- Can't call security.securableobject_pkg.RenameSO on filters as that requires chain.filter_pkg
		-- compiling correctly, which we can't guarantee
		
		v_name := r.name;
		
		SELECT COUNT(*) INTO v_duplicates
		  FROM security.securable_object
		 WHERE parent_sid_id = (SELECT parent_sid_id FROM security.securable_object WHERE sid_id = r.saved_filter_sid)
		   AND LOWER(name) = LOWER(r.name)
		   AND sid_id <> r.saved_filter_sid;
		
		-- super admin filters in sites that have been cloned will have duplicates - rename these
		WHILE v_duplicates <> 0 LOOP
			v_name := v_name||' (clone)';
			
			SELECT COUNT(*) INTO v_duplicates
			  FROM security.securable_object
			 WHERE parent_sid_id = (SELECT parent_sid_id FROM security.securable_object WHERE sid_id = r.saved_filter_sid)
			   AND LOWER(name) = LOWER(v_name)
			   AND sid_id <> r.saved_filter_sid;
		END LOOP;
		
		IF v_name != r.name THEN
			dbms_output.put_line(v_name);
			UPDATE chain.saved_filter
			   SET name = v_name
			 WHERE saved_filter_sid = r.saved_filter_sid;
		END IF;
		
		UPDATE security.securable_object
		   SET name = v_name
		 WHERE sid_id = r.saved_filter_sid;
		
	END LOOP;
	
END;
/

-- ** New package grants **

-- *** Packages ***
@..\chain\filter_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\issue_report_pkg
@..\schema_pkg
@..\quick_survey_pkg

@..\chain\filter_body
@..\chain\chain_body
@..\chain\company_filter_body
@..\audit_report_body
@..\non_compliance_report_body
@..\issue_report_body
@..\enable_body
@..\audit_body
@..\schema_body
@..\csr_user_body
@..\quick_survey_body
@..\issue_body
@..\csr_app_body
@..\csrimp\imp_body

@update_tail
