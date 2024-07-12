-- Please update version.sql too -- this keeps clean builds in sync
define version=2525
@update_header

-- *** DDL ***

-- Fix issue created by latest2523
BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE NOT EXISTS (
			SELECT * FROM all_tab_columns WHERE owner='CSRIMP' AND table_name='TAG_GROUP' AND column_name='LOOKUP_KEY'
		)
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.tag_group ADD LOOKUP_KEY VARCHAR2(64)';
	END LOOP;
END;
/


DROP TYPE CHAIN.T_COMPANY_REL_SIDS_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_SIDS AS
	OBJECT (
		PRIMARY_COMPANY_SID			NUMBER(10),
		SECONDARY_COMPANY_SID		NUMBER(10),
		ACTIVE						NUMBER(1),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_COMPANY_RELATIONSHIP_SIDS AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN RPAD(PRIMARY_COMPANY_SID, 10) || '->' || RPAD(SECONDARY_COMPANY_SID, 10);
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_REL_SIDS_TABLE AS
	TABLE OF CHAIN.T_COMPANY_RELATIONSHIP_SIDS;
/


-- Create tables
CREATE SEQUENCE csr.non_compliance_type_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;
	
CREATE SEQUENCE csr.internal_audit_type_group_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER;
		
CREATE TABLE csr.non_compliance_type (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_compliance_type_id			NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	lookup_key						VARCHAR2(255),
	position						NUMBER(10) NOT NULL,
	colour_when_open				NUMBER(10) NOT NULL,
	colour_when_closed				NUMBER(10) NOT NULL,
	can_have_actions				NUMBER(1) DEFAULT 1 NOT NULL,
	closure_behaviour_id			NUMBER(10) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_non_compliance_type PRIMARY KEY (app_sid, non_compliance_type_id),
	CONSTRAINT uk_nc_type_lookup_key UNIQUE (app_sid, lookup_key),
	CONSTRAINT chk_nc_typ_can_have_actns_1_0 CHECK (can_have_actions IN (1, 0)),
	CONSTRAINT chk_nc_typ_closure_behaviour CHECK (closure_behaviour_id IN (1, 2, 3)),
	CONSTRAINT fk_non_compliance_type_cust FOREIGN KEY (app_sid) REFERENCES csr.customer(app_sid)
);

CREATE TABLE csr.non_comp_type_audit_type (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_compliance_type_id			NUMBER(10) NOT NULL,
	internal_audit_type_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_non_comp_type_audit_type PRIMARY KEY (app_sid, non_compliance_type_id, internal_audit_type_id),
	CONSTRAINT fk_nc_type_aud_type_nc_type FOREIGN KEY (app_sid, non_compliance_type_id) 
		REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id),
	CONSTRAINT fk_nc_type_aud_type_aud_type FOREIGN KEY (app_sid, internal_audit_type_id) 
		REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
);

CREATE TABLE csr.internal_audit_type_group (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	internal_audit_type_group_id	NUMBER(10,0) NOT NULL,
	label							VARCHAR2(255 BYTE) NOT NULL,
	lookup_key						VARCHAR2(255 BYTE),
	internal_audit_ref_prefix		VARCHAR2(255 BYTE),
	CONSTRAINT pk_audit_group PRIMARY KEY (app_sid, internal_audit_type_group_id),
	CONSTRAINT uk_audit_group UNIQUE (app_sid, lookup_key)
);

CREATE TABLE csrimp.non_compliance_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	non_compliance_type_id			NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	lookup_key						VARCHAR2(255),
	position						NUMBER(10) NOT NULL,
	colour_when_open				NUMBER(10) NOT NULL,
	colour_when_closed				NUMBER(10) NOT NULL,
	can_have_actions				NUMBER(1) DEFAULT 1 NOT NULL,
	closure_behaviour_id			NUMBER(10) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_non_compliance_type PRIMARY KEY (csrimp_session_id, non_compliance_type_id),
	CONSTRAINT uk_nc_type_lookup_key UNIQUE (csrimp_session_id, lookup_key),
	CONSTRAINT chk_nc_typ_can_have_actns_1_0 CHECK (can_have_actions IN (1, 0)),
	CONSTRAINT chk_nc_typ_closure_behaviour CHECK (closure_behaviour_id IN (1, 2, 3)),
	CONSTRAINT fk_non_compliance_type_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.non_comp_type_audit_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	non_compliance_type_id			NUMBER(10) NOT NULL,
	internal_audit_type_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_non_comp_type_audit_type PRIMARY KEY (csrimp_session_id, non_compliance_type_id, internal_audit_type_id),
	CONSTRAINT fk_nc_type_audit_type_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_compliance_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_compliance_type_id		NUMBER(10)	NOT NULL,
	new_non_compliance_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_non_compliance_type primary key (csrimp_session_id, old_non_compliance_type_id) USING INDEX,
	CONSTRAINT uk_map_non_compliance_type unique (csrimp_session_id, new_non_compliance_type_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMPLIANCE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.internal_audit_type_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	internal_audit_type_group_id	NUMBER(10,0) NOT NULL,
	label							VARCHAR2(255 BYTE) NOT NULL,
	lookup_key						VARCHAR2(255 BYTE),
	internal_audit_ref_prefix		VARCHAR2(255 BYTE),
	CONSTRAINT pk_audit_group PRIMARY KEY (csrimp_session_id, internal_audit_type_group_id),
	CONSTRAINT fk_intrnl_audit_type_group_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_type_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_inter_audit_type_group_id		NUMBER(10)	NOT NULL,
	new_inter_audit_type_group_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_inter_audit_type_group primary key (csrimp_session_id, old_inter_audit_type_group_id) USING INDEX,
	CONSTRAINT uk_map_inter_audit_type_group unique (csrimp_session_id, new_inter_audit_type_group_id) USING INDEX,
    CONSTRAINT FK_MAP_INT_AUDIT_TYPE_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.non_compliance ADD (
	non_compliance_type_id			NUMBER(10),
	CONSTRAINT fk_non_comp_non_comp_type FOREIGN KEY (app_sid, non_compliance_type_id) 
		REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id)
);

ALTER TABLE csr.non_compliance ADD (
	is_closed						NUMBER(1),
	CONSTRAINT chk_non_comp_is_closed_1_0 CHECK (is_closed IS NULL OR is_closed IN (1,0))
);

ALTER TABLE csr.internal_audit_type ADD (
	internal_audit_type_group_id 	NUMBER(10, 0) NULL
);

ALTER TABLE csr.internal_audit_type ADD (
	CONSTRAINT fk_internal_audit_type_group
		FOREIGN KEY (app_sid, internal_audit_type_group_id)
		REFERENCES csr.internal_audit_type_group(app_sid, internal_audit_type_group_id)
);
		
ALTER TABLE csr.internal_audit ADD (
	internal_audit_ref 				NUMBER(10, 0)
);

ALTER TABLE csr.issue ADD (
	issue_ref						NUMBER(10, 0)
);
  
CREATE UNIQUE INDEX csr.uk_internal_audit_ref_type 
		ON csr.internal_audit (
			CASE WHEN internal_audit_ref IS NULL THEN NULL 
				 ELSE app_sid ||'_'|| internal_audit_type_id ||'_'|| internal_audit_ref END
		);
		
CREATE UNIQUE INDEX csr.uk_issue_ref_type 
		ON csr.issue ( 
			CASE WHEN issue_ref IS NULL THEN NULL 
				 ELSE app_sid ||'_'|| issue_type_id ||'_'|| issue_ref END
		);

ALTER TABLE csr.internal_audit_type ADD (
	internal_audit_ref_helper_func    	VARCHAR2(255)
);

ALTER TABLE csr.issue_type ADD (
	internal_issue_ref_helper_func 	  	VARCHAR2(255),
    internal_issue_ref_prefix	      	VARCHAR2(255)
);
  
ALTER TABLE csrimp.non_compliance ADD (
	non_compliance_type_id			NUMBER(10),
	is_closed						NUMBER(1),
	CONSTRAINT chk_non_comp_is_closed_1_0 CHECK (is_closed IS NULL OR is_closed IN (1,0))
);

ALTER TABLE csrimp.issue ADD (
	issue_ref 						NUMBER(10, 0)
);
  
ALTER TABLE csrimp.internal_audit ADD (
	internal_audit_ref 				NUMBER(10, 0)
);

ALTER TABLE csrimp.internal_audit_type ADD (
	internal_audit_ref_helper_func 	VARCHAR2(255)
);
	
ALTER TABLE csrimp.issue_type ADD (
	internal_issue_ref_helper_func 	VARCHAR2(255),
    internal_issue_ref_prefix		VARCHAR2(255)
);


-- *** Grants ***
grant execute on chain.plugin_pkg to csr;

grant insert on csr.non_compliance_type to csrimp;
grant insert on csr.non_comp_type_audit_type to csrimp;
grant insert on csr.internal_audit_type_group to csrimp;
grant select,insert,update,delete on csrimp.non_compliance_type to web_user;
grant select,insert,update,delete on csrimp.non_comp_type_audit_type to web_user;
grant select,insert,update,delete on csrimp.internal_audit_type_group to web_user;
grant select on csr.non_compliance_type_id_seq to csrimp;
grant select on csr.internal_audit_type_group_seq to csrimp;


-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW CHAIN.v$questionnaire_type_status AS
	SELECT questionnaire_type_id, questionnaire_name, company_sid, MIN(status_id) status_id 
	  FROM (
		SELECT qt.questionnaire_type_id, qt.name questionnaire_name, c.company_sid,
			CASE 
				WHEN qs.has_expired = 1 THEN 20	 					--SHARED_DATA_EXPIRED
				WHEN qs.share_status_id IN (14, 19) THEN 14 		--SHARED_DATA_ACCEPTED, SHARED_DATA_RESENT -> SHARED_DATA_ACCEPTED
				WHEN qs.share_status_id = 12 THEN 12 				--SHARING_DATA
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm >= SYSDATE THEN 16	--NOT_SHARED -> NOT_SHARED_PENDING
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm < SYSDATE THEN 17	--NOT_SHARED -> NOT_SHARED_OVERDUE
				WHEN qs.share_status_id = 13 THEN 13				--SHARED_DATA_RETURNED
				WHEN i.invitation_status_id = 1 THEN 21				--ACTIVE-> QNR_INVITATION_NOT_ACCEPTED
				WHEN i.invitation_status_id = 5 THEN 16				--ACCEPTED-> NOT_SHARED_PENDING
				WHEN i.invitation_status_id IN (6,7,9,11,12) THEN 22 --REJECTED_NOT_EMPLOYEE, REJECTED_NOT_SUPPLIER, CANNOT_ACCEPT_TERMS, REJECTED_NOT_PARTNER, REJECTED_QNNAIRE_REQ-> QNR_INVITATION_DECLINED
				WHEN i.invitation_status_id = 2 THEN 23				--EXPIRED-> QNR_INVITATION_EXPIRED
				ELSE NULL
			END status_id
		  FROM company c
		  LEFT JOIN invitation i ON c.company_sid = i.to_company_sid
		  LEFT JOIN invitation_qnr_type iqt ON i.invitation_id = iqt.invitation_id
		  LEFT JOIN v$questionnaire_share qs 
			ON NVL(iqt.questionnaire_type_id, qs.questionnaire_type_id) = qs.questionnaire_type_id 
		   AND c.company_sid = qs.qnr_owner_company_sid 
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR qs.share_with_company_sid IN (i.on_behalf_of_company_sid, i.from_company_sid))
		  JOIN questionnaire_type qt ON NVL(iqt.questionnaire_type_id,qs.questionnaire_type_id) = qt.questionnaire_type_id
		 WHERE (qs.share_with_company_sid IS NULL OR qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IN (i.on_behalf_of_company_sid, i.from_company_sid))
	  ) 
	 WHERE status_id IS NOT NULL
	 GROUP BY questionnaire_type_id, questionnaire_name, company_sid;

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ' ' || ia.internal_audit_ref, null) custom_audit_id,
		   ia.auditor_user_sid, ca.full_name auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name, SUBSTR(ia.notes, 1, 50) short_notes,
		   ia.notes full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, ca.email auditor_email,
		   iat.filename as template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id, sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr.csr_user ca ON NVL(cvru.user_giving_cover_sid , ia.auditor_user_sid) = ca.csr_user_sid AND ia.app_sid = ca.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
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
	  JOIN csr.v$region r ON ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	 WHERE ia.deleted = 0;

CREATE OR REPLACE FORCE VIEW csr.v$issue AS
	SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || ' ' || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
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
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
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
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0
   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
	-- filter out issues from deleted audits
	SELECT inc.issue_non_compliance_id
	  FROM issue_non_compliance inc
	  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
	 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
   ));
	 
grant select on chain.v$questionnaire_type_status to csr;

-- *** Data changes ***
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
		   AND t.table_name IN ('NON_COMPLIANCE_TYPE', 'NON_COMP_TYPE_AUDIT_TYPE', 'MAP_NON_COMPLIANCE_TYPE')
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
CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	BEGIN
		chain.temp_RegisterCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'Terminate company business relationships', 1, 0);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Terminate company business relationships', 1, 1);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Terminate company business relationships (supplier => purchaser)', 1, 1);
	END;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1051,'Supply Chain Questionnaire Summary','Credit360.Portlets.Chain.QuestionnaireSummary',EMPTY_CLOB(),'/csr/site/portal/portlets/Chain/QuestionnaireSummary.js');

@latest2525_packages

BEGIN
	security.user_pkg.LogonAdmin;
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RETURNED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{toCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QNR_SUBMITTED_NO_REVIEW, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{toCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_REJECTED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{toCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_REJECTED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{reCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{companySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_APPROVED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{reCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_APPROVED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromcompanySid', 
		in_value 					=> '{toCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_OVERDUE, 
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_param_name 				=> 'fromcompanySid', 
		in_value 					=> '{reCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_EXPIRED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{toCompanySid}'
	);
END;
/

DECLARE
    v_card_id         chain.card.card_id%TYPE;
    v_desc            chain.card.description%TYPE;
    v_class           chain.card.class_type%TYPE;
    v_js_path         chain.card.js_include%TYPE;
    v_js_class        chain.card.js_class_type%TYPE;
    v_css_path        chain.card.css_include%TYPE;
    v_actions         chain.T_STRING_LIST;
BEGIN
    -- Generated from:
    -- upd@aspen> exec chain.card_pkg.dumpcard('Chain.Cards.AddBusinessRelationship');
    
    -- Chain.Cards.AddBusinessRelationship
    v_desc := 'Creates business relationships when inviting a company';
    v_class := 'Credit360.Chain.Cards.AddBusinessRelationship';
    v_js_path := '/csr/site/chain/cards/addBusinessRelationship.js';
    v_js_class := 'Chain.Cards.AddBusinessRelationship';
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

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_card_pkg;
DROP PACKAGE chain.temp_chain_pkg;

DECLARE
	v_filter_field_id NUMBER(10);
BEGIN
	FOR r IN (
		SELECT app_sid, filter_id, survey_sid, status_id
		  FROM csr.qs_filter_by_status
	) LOOP
		BEGIN
			SELECT filter_field_id
			  INTO v_filter_field_id
			  FROM chain.filter_field
			 WHERE app_sid = r.app_sid
			   AND filter_id = r.filter_id
			   AND name = 'QuestionnaireStatus.'||r.survey_sid;
		EXCEPTION
			WHEN no_data_found THEN	
				INSERT INTO chain.filter_field (app_sid, filter_field_id, filter_id, name, comparator, group_by_index, show_all)
					 VALUES (r.app_sid, chain.filter_field_id_seq.NEXTVAL, r.filter_id, 'QuestionnaireStatus.'||r.survey_sid, 'contains', NULL, 0)
				  RETURNING filter_field_id INTO v_filter_field_id;
		END;
		
		INSERT INTO chain.filter_value (app_sid, filter_value_id, filter_field_id, num_value, description)
		     VALUES (r.app_sid, chain.filter_value_id_seq.NEXTVAL, v_filter_field_id, r.status_id, r.status_id);
			 
	END LOOP;
END;
/


DROP TABLE csrimp.qs_filter_by_status;
DROP TABLE csr.qs_filter_by_status;

BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
			VALUES (17, 'audit', 'Finding type', 0, 3);
			
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (18, 'audit', 'Close findings', 1, 2);
		
	INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
	SELECT fs.app_sid, csr.FLOW_STATE_RL_CAP_ID_SEQ.nextval, fs.flow_state_id, 17, fx.role_sid, fx.flow_involvement_type_id, 3
	  FROM csr.flow_state fs
	  JOIN (
		SELECT flow_state_id, role_sid, null flow_involvement_type_id, app_sid
		  FROM csr.flow_state_role fsr
		 UNION
		SELECT flow_state_id, null, flow_involvement_type_id, app_sid
		  FROM csr.flow_state_involvement fsi
	  ) fx ON fx.flow_state_id = fs.flow_state_id AND fx.app_sid = fs.app_sid
	 WHERE EXISTS (
		SELECT *
		  FROM csr.flow_state_role_capability fsrc
		 WHERE fsrc.flow_state_id = fs.flow_state_id
		   AND fsrc.app_sid = fs.app_sid
		   AND fsrc.flow_capability_id != 17
	 ) AND NOT EXISTS (
		SELECT *
		  FROM csr.flow_state_role_capability fsrc
		 WHERE fsrc.flow_state_id = fs.flow_state_id
		   AND fsrc.app_sid = fs.app_sid
		   AND fsrc.flow_capability_id = 17
	 );
	 
	INSERT INTO csr.flow_state_role_capability(app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
	SELECT fs.app_sid, csr.FLOW_STATE_RL_CAP_ID_SEQ.nextval, fs.flow_state_id, 18, fx.role_sid, fx.flow_involvement_type_id, 2
	  FROM csr.flow_state fs
	  JOIN (
		SELECT flow_state_id, role_sid, null flow_involvement_type_id, app_sid
		  FROM csr.flow_state_role fsr
		 UNION
		SELECT flow_state_id, null, flow_involvement_type_id, app_sid
		  FROM csr.flow_state_involvement fsi
	  ) fx ON fx.flow_state_id = fs.flow_state_id AND fx.app_sid = fs.app_sid
	 WHERE EXISTS (
		SELECT *
		  FROM csr.flow_state_role_capability fsrc
		 WHERE fsrc.flow_state_id = fs.flow_state_id
		   AND fsrc.app_sid = fs.app_sid
		   AND fsrc.flow_capability_id != 18
	 ) AND NOT EXISTS (
		SELECT *
		  FROM csr.flow_state_role_capability fsrc
		 WHERE fsrc.flow_state_id = fs.flow_state_id
		   AND fsrc.app_sid = fs.app_sid
		   AND fsrc.flow_capability_id = 18
	 );
END;
/

CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_description					IN  csr.plugin.description%TYPE,
	in_js_include					IN  csr.plugin.js_include%TYPE,
	in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
							details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
					 in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE plugin 
		   SET description = in_description,
			   js_include = in_js_include,
			   cs_class = in_cs_class,
			   details = in_details,
			   preview_image_path = in_preview_image_path,
			   form_path = in_form_path
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = in_js_class
		   AND app_sid IS NULL
		   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
			   RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;
/

DECLARE
	v_plugin_id     csr.plugin.plugin_id%TYPE;
begin
	v_plugin_id := csr.temp_SetCorePlugin (
		in_plugin_type_id		=> 13, --csr.csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB,
		in_js_class				=> 'Audit.Controls.FindingTab',
		in_description			=> 'Findings',
		in_js_include			=> '/csr/site/audit/controls/FindingTab.js',
		in_cs_class				=> 'Credit360.Audit.Plugins.FindingTab',
		in_details				=> 'Findings'
	);
end;
/

DROP FUNCTION csr.Temp_SetCorePlugin;

BEGIN
	BEGIN
		INSERT INTO csr.audit_type_group (audit_type_group_id, description)
		VALUES (4, 'Chain objects');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.audit_type (audit_type_group_id, audit_type_id, label)
		VALUES (4, 200, 'Business relationships');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

-- ** New package grants **
grant execute on aspen2.error_pkg to chain;


-- *** Packages ***
@../chain/chain_pkg
@../chain/company_pkg
@../chain/business_relationship_pkg
@../chain/dashboard_pkg
@../chain/plugin_pkg
@../chain/message_pkg
@../chain/questionnaire_pkg
@../chain/company_filter_pkg
@../chain/chain_link_pkg
@../schema_pkg
@../quick_survey_pkg
@../supplier_pkg
@../audit_pkg
@../csr_data_pkg

@../chain/chain_body
@../chain/company_body
@../chain/business_relationship_body
@../chain/dashboard_body
@../chain/plugin_body
@../chain/message_body
@../chain/questionnaire_body
@../chain/company_filter_body
@../chain/invitation_body
@../chain/chain_link_body
@../chain/setup_body
@../plugin_body
@../schema_body
@../quick_survey_body
@../supplier_body
@../csrimp/imp_body
@../audit_body
@../unit_test_body
@../issue_body
@../csr_user_body
@../csr_app_body
@../enable_body
@../../../aspen2/db/error_body

@update_tail
