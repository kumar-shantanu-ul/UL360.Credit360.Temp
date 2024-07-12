define version=3302
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.AGGREGATE_IND_GROUP_AUDIT_LOG (
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    AGGREGATE_IND_GROUP_ID    NUMBER(10, 0)     NOT NULL,
    CHANGE_DTM                DATE              NOT NULL,
    CHANGE_DESCRIPTION        VARCHAR2(4000)    NOT NULL,
    CHANGED_BY_USER_SID       NUMBER(10, 0)     NOT NULL
);
CREATE INDEX CSR.IX_AGG_IND_GRP_LOG ON CSR.AGGREGATE_IND_GROUP_AUDIT_LOG(APP_SID, AGGREGATE_IND_GROUP_ID)
;
CREATE TABLE CSRIMP.AGGREGATE_IND_GROUP_AUDIT_LOG (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    AGGREGATE_IND_GROUP_ID			NUMBER(10, 0)     NOT NULL,
    CHANGE_DTM						DATE              NOT NULL,
    CHANGE_DESCRIPTION				VARCHAR2(4000)    NOT NULL,
    CHANGED_BY_USER_SID				NUMBER(10, 0)     NOT NULL,
    CONSTRAINT FK_AGGR_IND_GROUP_AUDIT_LOG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


ALTER TABLE csr.aggregate_ind_group
ADD LOOKUP_KEY VARCHAR2(255);
CREATE UNIQUE INDEX CSR.UK_AGGR_IND_GROUP_LOOKUP_KEY ON CSR.AGGREGATE_IND_GROUP(APP_SID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(AGGREGATE_IND_GROUP_ID)))
;
ALTER TABLE CSR.AGGREGATE_IND_GROUP_AUDIT_LOG ADD CONSTRAINT FK_AGG_IND_GRP_USER
    FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE csrimp.aggregate_ind_group
ADD LOOKUP_KEY VARCHAR2(255);
create index csr.ix_aggregate_ind_changed_by_us on csr.aggregate_ind_group_audit_log (app_sid, changed_by_user_sid);
ALTER TABLE cms.form_response_answer_file
ADD (
	remote_file_id VARCHAR2(255),
	file_name VARCHAR2(255) NOT NULL,
	mime_type VARCHAR2(255) NOT NULL
);


grant insert on csr.aggregate_ind_group_audit_log to csrimp;
grant select,insert,update,delete on csrimp.aggregate_ind_group_audit_log to tool_user;








INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name)
VALUES (15, 54 /* chain.filter_pkg.FILTER_TYPE_QS_RESPONSE */, 23 /* chain.filter_pkg.FILTER_TYPE_COMPANIES */, 'company');
DECLARE
	v_pos					NUMBER;
	v_card_id				chain.card.card_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';
	FOR r IN (
		SELECT cus.host
		  FROM (
			SELECT app_sid
			  FROM chain.card_group_card
			 WHERE card_group_id = 54
			 GROUP BY app_sid
			) cg
		  LEFT JOIN (
			SELECT app_sid
			  FROM chain.card_group_card
			 WHERE card_group_id = 54 AND card_id = v_card_id
		  ) c ON c.app_sid = cg.app_sid
		  JOIN security.securable_object so ON so.parent_sid_id = cg.app_sid AND so.name = 'Audits'
		  JOIN csr.customer cus ON cus.app_sid = cg.app_sid
		  JOIN security.website w ON lower(w.website_name) = lower(cus.host)
		 WHERE c.app_sid IS NULL
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		SELECT MAX(position) + 1
		  INTO v_pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 54
		   AND app_sid = security.security_pkg.GetApp;
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (security.security_pkg.GetApp, 54, v_card_id, v_pos);
		security.user_pkg.Logoff(security.security_pkg.GetAct);
	END LOOP;
END;
/






@..\aggregate_ind_pkg
@..\schema_pkg
@..\indicator_pkg
@..\region_pkg
@..\..\..\aspen2\cms\db\form_response_import_pkg


@..\aggregate_ind_body
@..\schema_body
@..\indicator_body
@..\csr_app_body
@..\csrimp\imp_body
@..\quick_survey_report_body
@..\audit_body
@..\delegation_body
@..\enable_body
@..\region_body
@..\sheet_body
@..\..\..\aspen2\cms\db\form_response_import_body



@update_tail
