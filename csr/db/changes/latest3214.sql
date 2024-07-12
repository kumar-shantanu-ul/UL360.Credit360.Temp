define version=3214
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE CSR.USER_PROFILE_STAGED_RECORD_LOG (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRIMARY_KEY						VARCHAR2(128) NOT NULL,
	LAST_INSTANCE_STEP_ID			NUMBER(10),
	ACTION_DTM						DATE,
	ACTION_USER_SID					NUMBER(10),
	ACTION_DESCRIPTION				VARCHAR(256)
)
;


ALTER TABLE csr.axis DROP CONSTRAINT FK_AXIS_REL_AXIS_LEFT DROP INDEX;
ALTER TABLE csr.axis DROP CONSTRAINT FK_AXIS_REL_AXIS_RIGHT DROP INDEX;
DROP TABLE csr.related_axis_member;
DROP TABLE csr.related_axis;
DROP TABLE csr.selected_axis_task;

BEGIN
	-- Drop broken client reference (but by name so we get an error if used elsewhere)
	FOR r IN (
		SELECT owner, table_name, constraint_name
		  FROM dba_constraints
		 WHERE owner='MIGROSPILOT'
		   AND constraint_name IN ('FK_AXIS_MEM_REL_MEM', 'FK_AXIS_MEM_PRI_MEM')
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

DROP TABLE csr.axis_member;
DROP TABLE csr.axis;
DROP SEQUENCE CSR.AXIS_ID_SEQ;
DROP SEQUENCE CSR.AXIS_MEMBER_ID_SEQ;
ALTER TABLE chain.filter_field ADD (row_or_col NUMBER(1));






CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version, qss.submitted_by_user_sid,
		   qss.geo_latitude, qss.geo_longitude, qss.geo_h_accuracy, qss.geo_altitude, qss.geo_v_accuracy
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.app_sid = qss.app_sid
	   AND qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;
CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other, ff.comparator, ff.row_or_col
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;
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
		fv.filter_type, fv.null_filter, fv.colour, ff.comparator, ff.row_or_col
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN chain.filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;




DELETE FROM csr.capability WHERE NAME = 'Configure strategy dashboard';
DELETE FROM csr.capability WHERE NAME = 'View strategy dashboard';
DROP PACKAGE csr.strategy_pkg;
DECLARE
	PROCEDURE EnablePortletForCustomer(
		in_portlet_id	IN csr.portlet.portlet_id%TYPE
	)
	AS
		v_customer_portlet_sid		security.security_pkg.T_SID_ID;
		v_portlets_sid				security.security_pkg.T_SID_ID;
		v_type						csr.portlet.type%TYPE;
	BEGIN
		SELECT type
		  INTO v_type
		  FROM csr.portlet
		 WHERE portlet_id = in_portlet_id;
		
		BEGIN
			v_customer_portlet_sid := security.securableobject_pkg.GetSIDFromPath(
					SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					'Portlets/' || v_type);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		
			BEGIN
				v_portlets_sid := security.securableobject_pkg.GetSIDFromPath(
						SYS_CONTEXT('SECURITY','ACT'),
						SYS_CONTEXT('SECURITY','APP'),
						'Portlets');
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
					v_portlets_sid,
					security.class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
		END;
		IF v_customer_portlet_sid IS NOT NULL THEN
			BEGIN
				INSERT INTO csr.customer_portlet
					(portlet_id, customer_portlet_sid, app_sid)
				VALUES
					(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN NULL;
			END;
		END IF;
	END;
BEGIN
	security.user_pkg.LogonAdmin;
	FOR s IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.LogonAdmin(s.host);
		FOR p IN (
			SELECT portlet_id
			  FROM csr.portlet
			 WHERE type IN (
				'Credit360.Portlets.PeriodPicker2'
			) AND portlet_Id NOT IN (SELECT portlet_id FROM csr.customer_portlet)
		) LOOP
			EnablePortletForCustomer(p.portlet_id);
		END LOOP;
		security.user_pkg.LogonAdmin;
	END LOOP;
END;
/
DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.users', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/






@..\user_profile_pkg
@..\region_report_pkg
@..\indicator_pkg
@..\chain\filter_pkg


@..\user_profile_body
@..\quick_survey_report_body
@..\chain\activity_body
@..\..\..\aspen2\cms\db\web_publication_body
@..\csr_app_body
@..\actions\task_body
@..\actions\initiative_body
@..\enable_body
@..\region_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\region_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\indicator_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\region_tree_body
@..\schema_body



@update_tail
