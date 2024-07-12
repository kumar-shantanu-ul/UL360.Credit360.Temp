-- Please update version.sql too -- this keeps clean builds in sync
define version=1818
@update_header

CREATE TABLE CMS.PIVOT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PIVOT_SID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    PIVOT_JSON CLOB NOT NULL,
    PRIMARY KEY (APP_SID, PIVOT_SID)
);

ALTER TABLE CMS.PIVOT ADD CONSTRAINT FK_TAB_PIVOT 
    FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID,TAB_SID);

DECLARE
	v_act_id	security.security_pkg.T_ACT_ID;
	v_sid_id	security.security_pkg.T_SID_ID;
	v_reg_users	security.security_pkg.T_SID_ID;
	v_class_id	security.security_pkg.T_CLASS_ID;
BEGIN
	security.user_pkg.LogOnAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act_id);

	BEGIN
		security.class_pkg.CreateClass(v_act_id, NULL, 'CMSPivotTable', 'cms.pivot_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		  JOIN security.website w
		    ON c.host = w.website_name) LOOP
		BEGIN
			security.user_pkg.LogOnAdmin(r.host);
			security.SecurableObject_pkg.CreateSO(security.security_pkg.GetAct, r.app_sid, security.security_pkg.SO_CONTAINER, 'Pivot tables', v_sid_id);
			-- grant RegisteredUsers READ on pivot tables
			v_reg_users := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, r.app_sid, 'Groups/RegisteredUsers');
			security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_sid_id), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.LogOnAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act_id);
	
END;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'PIVOT'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					
					--dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CMS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CMS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						exit; -- don't do anything on dups - most likely the sprint team are re-running the script
				end;
			end loop;
		end;
	end loop;
end;
/


CREATE OR REPLACE PACKAGE CMS.pivot_pkg AS
	PROCEDURE Dummy;
END;
/


CREATE OR REPLACE PACKAGE BODY CMS.pivot_pkg AS
	PROCEDURE Dummy
	AS
	BEGIN
		NULL;
	END;
END;
/

grant execute on CMS.pivot_pkg to web_user;
grant execute on CMS.pivot_pkg to security;

-- FB33379 Changes START

ALTER TABLE cms.tab
ADD region_col_sid NUMBER(10);

ALTER TABLE cms.tab
ADD CONSTRAINT FK_TAB_REGION_COL_SID FOREIGN KEY (app_sid, region_col_sid) REFERENCES cms.tab_column(app_sid, column_sid);

CREATE INDEX cms.ix_tab_region_col ON cms.tab (app_sid, region_col_sid);

begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_name, policy_name from all_policies where object_owner='CSR' and object_name='ISSUE_TYPE') loop
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

ALTER TABLE csr.issue_type
ADD restrict_users_to_region NUMBER(1) DEFAULT 0;

ALTER TABLE csr.issue_type
MODIFY restrict_users_to_region NOT NULL;

ALTER TABLE csrimp.issue_type
ADD restrict_users_to_region NUMBER(1);

UPDATE csrimp.issue_type SET restrict_users_to_region = 0;

begin
		dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ISSUE_TYPE',
		policy_name     => 'ISSUE_TYPE_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );				    
end;
/

ALTER TABLE csrimp.issue_type
MODIFY restrict_users_to_region NOT NULL;

CREATE OR REPLACE VIEW csr.v$issue AS
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
		   ist.restrict_users_to_region
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

-- FB33379 Changes END

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\pivot_pkg
@..\csrimp\imp_pkg
@..\issue_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\pivot_body
@..\csr_data_body
@..\csrimp\imp_body
@..\issue_body
@..\schema_body

@update_tail