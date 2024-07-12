-- Please update version.sql too -- this keeps clean builds in sync
define version=1912
@update_header

/* ---------------------------------------------------------------------- */
/* Add table "TAB_COLUMN_LINK"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CMS.TAB_COLUMN_LINK (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COLUMN_SID_1 NUMBER(10) NOT NULL,
    ITEM_ID_1 NUMBER(10) NOT NULL,
    COLUMN_SID_2 NUMBER(10) NOT NULL,
    ITEM_ID_2 NUMBER(10) NOT NULL,
    CONSTRAINT PK_TAB_COLUMN_LINK PRIMARY KEY (APP_SID, COLUMN_SID_1, ITEM_ID_1, COLUMN_SID_2, ITEM_ID_2)
);

/* ---------------------------------------------------------------------- */
/* Add table "TAB_COLUMN_LINK_TYPE"                                       */
/* ---------------------------------------------------------------------- */


CREATE TABLE CMS.TAB_COLUMN_LINK_TYPE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COLUMN_SID NUMBER(10) NOT NULL,
    LINK_COLUMN_SID NUMBER(10) NOT NULL,
    LABEL VARCHAR2(255) NOT NULL,
    BASE_LINK_URL VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_TAB_COLUMN_LINK_TYPE PRIMARY KEY (APP_SID, COLUMN_SID, LINK_COLUMN_SID)
);

ALTER TABLE CMS.TAB_COLUMN_LINK ADD CONSTRAINT FK_TAB_COL_TAB_COL_LINK_2 
    FOREIGN KEY (APP_SID, COLUMN_SID_2) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);

ALTER TABLE CMS.TAB_COLUMN_LINK ADD CONSTRAINT FK_TAB_COL_TAB_COL_LINK_1 
    FOREIGN KEY (APP_SID, COLUMN_SID_1) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);

ALTER TABLE CMS.TAB_COLUMN_LINK_TYPE ADD CONSTRAINT FK_TAB_COL_TAB_COL_LNK_TYP 
    FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);

ALTER TABLE CMS.TAB_COLUMN_LINK_TYPE ADD CONSTRAINT FK_TAB_COL_TAB_COL_LNK_TYP_LNK 
    FOREIGN KEY (APP_SID, LINK_COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);
	
CREATE TABLE CSRIMP.CMS_TAB_COLUMN_LINK (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    TAB_COLUMN_LINK_ID NUMBER(10) NOT NULL,
    COLUMN_SID_1 NUMBER(10) NOT NULL,
    ITEM_ID_1 NUMBER(10) NOT NULL,
    COLUMN_SID_2 NUMBER(10) NOT NULL,
    ITEM_ID_2 NUMBER(10) NOT NULL,
    CONSTRAINT PK_TAB_COLUMN_LINK PRIMARY KEY (CSRIMP_SESSION_ID, TAB_COLUMN_LINK_ID),
    CONSTRAINT UK_TAB_COLUMN_LINK UNIQUE (CSRIMP_SESSION_ID, COLUMN_SID_1, ITEM_ID_1, COLUMN_SID_2, ITEM_ID_2),
	CONSTRAINT FK_CMS_TAB_COLUMN_LINK_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_TAB_COLUMN_LINK_TYPE (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    COLUMN_SID NUMBER(10) NOT NULL,
    LINK_COLUMN_SID NUMBER(10) NOT NULL,
    LABEL VARCHAR2(255) NOT NULL,
    BASE_LINK_URL VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_TAB_COLUMN_LINK_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, COLUMN_SID, LINK_COLUMN_SID),
	CONSTRAINT FK_CMS_TAB_COLUMN_LINK_TYP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_tab_column_link (
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_column_link_id		NUMBER(10) NOT NULL,
	new_column_link_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_cms_map_tab_column_link PRIMARY KEY (old_column_link_id) USING INDEX,
	CONSTRAINT uk_cms_map_tab_column_link UNIQUE (new_column_link_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_TAB_COLUMN_LINK_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on cms.tab_column_link to csrimp;
grant insert on cms.tab_column_link_type to csrimp;
	
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'TAB_COLUMN_LINK',
		'TAB_COLUMN_LINK_TYPE'
	);
	for i in 1 .. v_list.count loop
		begin
			dbms_rls.add_policy(
				object_schema   => 'CMS',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
				function_schema => 'CMS',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive );
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
		end;
	end loop;
end;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'CMS_TAB_COLUMN_LINK',
		'CMS_TAB_COLUMN_LINK_TYPE',
		'MAP_CMS_TAB_COLUMN_LINK'
	);
	for i in 1 .. v_list.count loop
		begin					
			dbms_rls.add_policy(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => (SUBSTR(v_list(i), 1, 26) || '_POL') , 
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> TRUE,
				policy_type     => dbms_rls.context_sensitive);
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
		end;
	end loop;
end;
/

CREATE TABLE csr.group_user_cover (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_cover_id			NUMBER(10) NOT NULL,
	user_giving_cover_sid	NUMBER(10, 0)    NOT NULL,
    user_being_covered_sid	NUMBER(10, 0)    NOT NULL,
	group_sid				NUMBER(10) NOT NULL,
	CONSTRAINT pk_group_user_cover PRIMARY KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid, group_sid),
	CONSTRAINT fk_group_user_cover_id FOREIGN KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid) REFERENCES csr.user_cover(app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid)
);

CREATE TABLE csr.role_user_cover (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_cover_id			NUMBER(10) NOT NULL,
	user_giving_cover_sid	NUMBER(10, 0)    NOT NULL,
    user_being_covered_sid	NUMBER(10, 0)    NOT NULL,
	role_sid				NUMBER(10) NOT NULL,
	region_sid				NUMBER(10) NOT NULL,
	CONSTRAINT pk_role_user_cover PRIMARY KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid, role_sid, region_sid),
	CONSTRAINT fk_role_user_cover_id FOREIGN KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid) REFERENCES csr.user_cover(app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid)
);

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN
	v_list := t_tabs(
	   'GROUP_USER_COVER',
	   'ROLE_USER_COVER'
	);
	FOR I IN 1 .. v_list.count
	LOOP
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSR',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

ALTER TABLE csr.issue_type ADD DELETABLE_BY_OWNER NUMBER(1,0) DEFAULT 0 NOT NULL; 
ALTER TABLE csr.issue_type ADD DELETABLE_BY_ADMINISTRATOR NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.issue_type ADD DELETABLE_BY_OWNER NUMBER(1,0) DEFAULT 0 NOT NULL; 
ALTER TABLE csrimp.issue_type ADD DELETABLE_BY_ADMINISTRATOR NUMBER(1,0) DEFAULT 0 NOT NULL;

  CREATE OR REPLACE FORCE VIEW "CSR"."V$ISSUE" ("APP_SID", "ISSUE_ID", "LABEL", "DESCRIPTION", "SOURCE_LABEL", "IS_VISIBLE", "SOURCE_URL", "REGION_SID", "REGION_NAME", "PARENT_ID", "ISSUE_ESCALATED", "OWNER_ROLE_SID", "OWNER_USER_SID", "FIRST_ISSUE_LOG_ID", "LAST_ISSUE_LOG_ID", "LAST_MODIFIED_DTM", "IS_PUBLIC", "IS_PENDING_ASSIGNMENT", "RAISED_BY_USER_SID", "RAISED_DTM", "RAISED_USER_NAME", "RAISED_FULL_NAME", "RAISED_EMAIL", "RESOLVED_BY_USER_SID", "RESOLVED_DTM", "RESOLVED_USER_NAME", "RESOLVED_FULL_NAME", "RESOLVED_EMAIL", "CLOSED_BY_USER_SID", "CLOSED_DTM", "CLOSED_USER_NAME", "CLOSED_FULL_NAME", "CLOSED_EMAIL", "REJECTED_BY_USER_SID", "REJECTED_DTM", "REJECTED_USER_NAME", "REJECTED_FULL_NAME", "REJECTED_EMAIL", "ASSIGNED_TO_USER_SID", "ASSIGNED_TO_USER_NAME", "ASSIGNED_TO_FULL_NAME", "ASSIGNED_TO_EMAIL", "ASSIGNED_TO_ROLE_SID", "ASSIGNED_TO_ROLE_NAME", "CORRESPONDENT_ID", "CORRESPONDENT_FULL_NAME", "CORRESPONDENT_EMAIL", "CORRESPONDENT_PHONE", "CORRESPONDENT_MORE_INFO_1", "NOW_DTM", "DUE_DTM", "ISSUE_TYPE_ID", "ISSUE_TYPE_LABEL", "REQUIRE_PRIORITY", "ALLOW_CHILDREN", "CAN_BE_PUBLIC", "ISSUE_PRIORITY_ID", "DUE_DATE_OFFSET", "PRIORITY_DESCRIPTION", "PRIORITY_OVERRIDDEN", "FIRST_PRIORITY_SET_DTM", "ISSUE_PENDING_VAL_ID", "ISSUE_SHEET_VALUE_ID", "ISSUE_SURVEY_ANSWER_ID", "ISSUE_NON_COMPLIANCE_ID", "ISSUE_ACTION_ID", "ISSUE_METER_ID", "ISSUE_METER_ALARM_ID", "ISSUE_METER_RAW_DATA_ID", "ISSUE_METER_DATA_SOURCE_ID", "ISSUE_SUPPLIER_ID", "IS_OVERDUE", "IS_OWNER", "IS_ASSIGNED_TO_YOU", "IS_RESOLVED", "IS_CLOSED", "IS_REJECTED", "STATUS", "ALLOW_AUTO_CLOSE", "RESTRICT_USERS_TO_REGION", "CAN_BE_DELETED") AS 
  SELECT i.app_sid, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	       i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
		   i.is_public, i.is_pending_assignment, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
		   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
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
		   ist.restrict_users_to_region,
		   CASE 
			WHEN ((ist.deletable_by_owner = 1 AND i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID')) OR (ist.deletable_by_administrator = 1 AND csr_data_pkg.SQL_CheckCapability('Issue management')  = 1)) THEN 1
			ELSE 0
		   END can_be_deleted
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
	   AND i.deleted = 0
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
	   ));

CREATE SEQUENCE CMS.TAB_COLUMN_LINK_SEQ;
grant select on cms.tab_column_link_seq to csrimp;

DELETE FROM CMS.TAB_COLUMN_LINK;
ALTER TABLE CMS.TAB_COLUMN_LINK DROP CONSTRAINT PK_TAB_COLUMN_LINK;
ALTER TABLE CMS.TAB_COLUMN_LINK ADD TAB_COLUMN_LINK_ID NUMBER(10) NOT NULL;
ALTER TABLE CMS.TAB_COLUMN_LINK ADD CONSTRAINT PK_TAB_COLUMN_LINK PRIMARY KEY (APP_SID, TAB_COLUMN_LINK_ID);
ALTER TABLE CMS.TAB_COLUMN_LINK ADD CONSTRAINT UK_TAB_COLUMN_LINK UNIQUE (APP_SID, COLUMN_SID_1, ITEM_ID_1, COLUMN_SID_2, ITEM_ID_2);


-- #### Risk Assessment Dashboard (Incident Heat-Map Portlet) START ####

INSERT INTO csr.portlet (portlet_id, name, type, default_state, script_path)
VALUES (1038,'Incident Heat Map','Credit360.Portlets.IncidentHeatMap', EMPTY_CLOB(),'/csr/site/portal/portlets/IncidentHeatMap.js');

-- #### Risk Assessment Dashboard (Incident Heat-Map Portlet) END ####

@..\unit_test_pkg

@..\unit_test_body
@..\user_cover_body
@..\csr_user_body

@..\flow_pkg
@..\flow_body

@..\role_pkg
@..\role_body

@..\issue_pkg
@..\issue_body
@..\csrimp\imp_body
@..\schema_body

@..\audit_pkg
@..\audit_body
@..\quick_survey_body

@..\..\..\aspen2\cms\db\col_link_pkg
@..\..\..\aspen2\cms\db\col_link_body
@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body

@update_tail