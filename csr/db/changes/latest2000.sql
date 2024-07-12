-- Please update version.sql too -- this keeps clean builds in sync
define version=2000
@update_header

DROP SEQUENCE CSR.ISSUE_TYPE_RAG_STATUS_ID_SEQ;

CREATE SEQUENCE CSR.ISSUE_RAG_STATUS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;    
    
CREATE TABLE CSR.ISSUE_RAG_STATUS (
    APP_SID             NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RAG_STATUS_ID       NUMBER(10) NOT NULL,
    COLOUR              NUMBER(10) NOT NULL,
    LABEL               VARCHAR2(255) NOT NULL,
    LOOKUP_KEY          VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_ISSUE_RAG_STATUS  PRIMARY KEY (APP_SID, RAG_STATUS_ID)
);

INSERT INTO CSR.ISSUE_RAG_STATUS (app_sid, rag_status_id, colour, label, lookup_key)
    SELECT DISTINCT app_sid, rag_status_id, colour, label, lookup_key
      FROM CSR.ISSUE_TYPE_RAG_STATUS;

DROP INDEX CSR.UK_ISSUE_TYPE_RAG_STATUS_LABEL;
DROP INDEX CSR.UK_ISSUE_TYPE_RAG_STATUS_LKP;

ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS DROP COLUMN COLOUR;
ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS DROP COLUMN LABEL;
ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS DROP COLUMN LOOKUP_KEY;

ALTER TABLE CSR.ISSUE DROP CONSTRAINT FK_ISS_ISS_TYP_RAG_STATUS;
ALTER TABLE CSR.ISSUE DROP CONSTRAINT FK_ISS_ISS_TYP_LAST_RAG_STATUS;

ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS DROP PRIMARY KEY DROP INDEX;

CREATE INDEX CSR.UK_ISSUE_RAG_STATUS_LKP ON CSR.ISSUE_RAG_STATUS(APP_SID, UPPER(LOOKUP_KEY));

ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS ADD CONSTRAINT PK_ISSUE_TYPE_RAG_STATUS  PRIMARY KEY (APP_SID, ISSUE_TYPE_ID, RAG_STATUS_ID);

ALTER TABLE CSR.ISSUE_TYPE_RAG_STATUS ADD CONSTRAINT FK_ISS_TYP_RAG_ST_ISS_RAG_ST 
    FOREIGN KEY (APP_SID, RAG_STATUS_ID)
    REFERENCES CSR.ISSUE_RAG_STATUS(APP_SID, RAG_STATUS_ID);

ALTER TABLE CSR.ISSUE ADD (
    CONSTRAINT FK_ISS_ISS_TYP_RAG_STATUS FOREIGN KEY (APP_SID, ISSUE_TYPE_ID, RAG_STATUS_ID) REFERENCES CSR.ISSUE_TYPE_RAG_STATUS(APP_SID, ISSUE_TYPE_ID, RAG_STATUS_ID),
    CONSTRAINT FK_ISS_ISS_TYP_LAST_RAG_STATUS FOREIGN KEY (APP_SID, ISSUE_TYPE_ID, LAST_RAG_STATUS_ID) REFERENCES CSR.ISSUE_TYPE_RAG_STATUS(APP_SID, ISSUE_TYPE_ID, RAG_STATUS_ID)
);

-- rejig the constraints here 
alter table csr.teamroom_type_tab_group drop constraint FK_TEAMROOM_TYPE_TAB_PLUGIN;
alter table csr.teamroom_type_tab add constraint FK_PLUGIN_TMRM_TYPE_TAB FOREIGN KEY (PLUGIN_ID, PLUGIN_TYPE_ID) REFERENCES CSR.PLUGIN(PLUGIN_ID, PLUGIN_TYPE_ID);
alter table csr.TEAMROOM_TYPE_TAB_GROUP drop constraint FK_TMRM_TYP_TB_GRP_TMRM_TYP;
-- ORA-02298: cannot validate (CSR.FK_TR_TYP_TB_TR_TYP_TB_GRP) - parent keys not found
-- so play safe - the data isn't very important
delete from csr.teamroom_type_tab_group where (APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID) not in (select APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID from csr.teamroom_type_tab);

alter table csr.TEAMROOM_TYPE_TAB_GROUP add constraint FK_TR_TYP_TB_TR_TYP_TB_GRP FOREIGN KEY (APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID) REFERENCES CSR.TEAMROOM_TYPE_TAB(APP_SID, TEAMROOM_TYPE_ID, PLUGIN_ID);

BEGIN
    INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (8, 'Initiative tab');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE csr.plugin_type SET description = 'Initiative tab' WHERE plugin_type_Id = 8;
END;
/

BEGIN
    INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (9, 'Initiative main tab');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE csr.plugin_type SET description = 'Initiative main tab' WHERE plugin_type_Id = 9;
END;
/

-- was missing from the script that added the column
ALTER TABLE CSR.INITIATIVE ADD CONSTRAINT FK_DOC_LIB_INITIATIVE 
    FOREIGN KEY (APP_SID, DOC_LIBRARY_SID)
    REFERENCES CSR.DOC_LIBRARY(APP_SID, DOC_LIBRARY_SID);

CREATE TABLE CSR.INITIATIVE_PROJECT_TAB(
    APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID    NUMBER(10, 0)    NOT NULL,
    PLUGIN_ID      NUMBER(10, 0)    NOT NULL,
    PLUGIN_TYPE_ID NUMBER(10, 0)    NOT NULL,
    POS            NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    TAB_LABEL      VARCHAR2(255)    NOT NULL,
    CONSTRAINT CHK_INIT_PROJ_TAB_PLUGIN_TYPE CHECK (PLUGIN_TYPE_ID IN (8,9)),
    CONSTRAINT PK_INIT_PROJECT_TAB PRIMARY KEY (APP_SID, PROJECT_SID, PLUGIN_ID)
);

CREATE TABLE CSR.INITIATIVE_PROJECT_TAB_GROUP(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID     NUMBER(10, 0)    NOT NULL,
    PLUGIN_ID       NUMBER(10, 0)    NOT NULL,
    GROUP_SID       NUMBER(10, 0)    NOT NULL,
    IS_READ_ONLY    NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_INIT_PRJ_TAB_GRP_RO CHECK (IS_READ_ONLY IN (0,1)),
    CONSTRAINT PK_INIT_PROJECT_TAB_GROUP PRIMARY KEY (APP_SID, PROJECT_SID, PLUGIN_ID, GROUP_SID)
);

CREATE TABLE CSR.INITIATIVE_USER_MSG(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INITIATIVE_SID    NUMBER(10, 0)    NOT NULL,
    USER_MSG_ID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_INITIATIVE_USER_MSG PRIMARY KEY (APP_SID, INITIATIVE_SID, USER_MSG_ID)
);

ALTER TABLE CSR.INITIATIVE_PROJECT_TAB ADD CONSTRAINT FK_INIT_PRJ_INIT_PRJ_TAB 
    FOREIGN KEY (APP_SID, PROJECT_SID)
    REFERENCES CSR.INITIATIVE_PROJECT(APP_SID, PROJECT_SID);

ALTER TABLE CSR.INITIATIVE_PROJECT_TAB ADD CONSTRAINT FK_PLUGIN_INIT_PRJ_TAB 
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID);

ALTER TABLE CSR.INITIATIVE_PROJECT_TAB_GROUP ADD CONSTRAINT FK_INIT_PRJ_TB_INIT_PRJ_TB_GRP 
    FOREIGN KEY (APP_SID, PROJECT_SID, PLUGIN_ID)
    REFERENCES CSR.INITIATIVE_PROJECT_TAB(APP_SID, PROJECT_SID, PLUGIN_ID);

ALTER TABLE CSR.INITIATIVE_USER_MSG ADD CONSTRAINT FK_INIT_INIT_USER_MSG 
    FOREIGN KEY (APP_SID, INITIATIVE_SID)
    REFERENCES CSR.INITIATIVE(APP_SID, INITIATIVE_SID);

ALTER TABLE CSR.INITIATIVE_USER_MSG ADD CONSTRAINT FK_USER_MSG_INIT_USER_MSG 
    FOREIGN KEY (APP_SID, USER_MSG_ID)
    REFERENCES CSR.USER_MSG(APP_SID, USER_MSG_ID);

    
CREATE TABLE CSR.RECENT_TEAMROOM(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TEAMROOM_SID         NUMBER(10, 0)    NOT NULL,
    USER_SID             NUMBER(10, 0)    NOT NULL,
    LAST_ACCESSED_DTM    DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_RECENT_TEAMROOM PRIMARY KEY (APP_SID, TEAMROOM_SID, USER_SID)
);

ALTER TABLE CSR.RECENT_TEAMROOM ADD CONSTRAINT FK_TEAMROOM_RCT_TEAMROOM 
    FOREIGN KEY (APP_SID, TEAMROOM_SID)
    REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID) ON DELETE CASCADE;


-- TODO: RESOURCE BUSY
ALTER TABLE CSR.RECENT_TEAMROOM ADD CONSTRAINT FK_USER_RECENT_TEAMRM 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID) ON DELETE CASCADE;


-- move initiative plugins over to new table - bit crap but should be good enough since we've got barely
-- any data in here.
INSERT INTO CSR.INITIATIVE_PROJECT_TAB(app_sid, project_sid, plugin_id, plugin_type_id, pos, tab_label)
    SELECT distinct ip.app_sid, ip.project_sid, ttt.plugin_id, ttt.plugin_type_Id, ttt.pos, ttt.tab_label 
      FROM csr.teamroom_type_tab ttt
      JOIN csr.initiative_project ip ON ttt.app_sid = ip.app_sid
     WHERE ttt.plugin_type_id IN (8,9);

INSERT INTO CSR.INITIATIVE_PROJECT_TAB_GROUP (app_sid, project_sid, plugin_id, group_sid)
    SELECT DISTINCT ipt.app_sid, ipt.project_sid, ipt.plugin_id, tttg.group_sid
      FROM CSR.INITIATIVE_PROJECT_TAB ipt
      JOIN csr.teamroom_type_tab ttt 
        ON ipt.app_sid = ttt.app_sid
       AND ipt.plugin_id = ttt.plugin_id
      JOIN csr.teamroom_type_tab_group tttg 
        ON ttt.teamroom_type_Id = tttg.teamroom_type_Id 
       AND ttt.plugin_id = tttg.plugin_id; 

DELETE FROM csr.teamroom_type_tab_group
	 WHERE plugin_id IN (
		SELECT plugin_id FROM csr.teamroom_type_tab WHERE plugin_type_id IN (8,9)
 );
       
DELETE FROM csr.teamroom_type_tab
 WHERE plugin_type_id IN (8,9);
       

ALTER TABLE CSR.TEAMROOM_TYPE_TAB DROP CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE;
ALTER TABLE CSR.TEAMROOM_TYPE_TAB ADD CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE CHECK (PLUGIN_TYPE_ID IN (5,6,7));


DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN   
    v_list := t_tabs(  
        'INITIATIVE_PROJECT_TAB',
        'INITIATIVE_PROJECT_TAB_GROUP',
        'INITIATIVE_USER_MSG',
        'ISSUE_RAG_STATUS',
        'RECENT_TEAMROOM'
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



-- missing from clean-build
BEGIN
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (1,'Logistics.Modes.AirportJobProcessor');
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (2,'Logistics.Modes.AirCountryJobProcessor');
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (3,'Logistics.Modes.RoadJobProcessor');
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (4,'Logistics.Modes.SeaJobProcessor');
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (5,'Logistics.Modes.BargeJobProcessor');
    INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (6,'Logistics.Modes.RailJobProcessor');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/


BEGIN
    -- was missing from clean build
    INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can see routed flow transitions', 0);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        null;
END;
/

-- was missing at some point so just apply anyway
alter table csr.TEAMROOM_ISSUE modify app_sid default SYS_CONTEXT('SECURITY','APP');

CREATE OR REPLACE VIEW csr.V$issue_type_rag_status AS  
    SELECT itrs.app_sid, itrs.issue_type_id, itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
      FROM issue_type_rag_status itrs 
      JOIN issue_rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid;

CREATE OR REPLACE VIEW csr.v$issue AS
    SELECT i.app_sid, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
           i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
           i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
           resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
           closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
           rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
           assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
           assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
           sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
           CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
           issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
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
           ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner
      FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
           (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs
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
       AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+)
       AND i.deleted = 0
       AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
        -- filter out issues from deleted audits
        SELECT inc.issue_non_compliance_id
          FROM issue_non_compliance inc
          JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
         WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
       ));


DROP TABLE csrimp.ISSUE_TYPE_RAG_STATUS PURGE;

CREATE TABLE CSRIMP.ISSUE_RAG_STATUS(
    CSRIMP_SESSION_ID   NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    RAG_STATUS_ID       NUMBER(10, 0)    NOT NULL,
    COLOUR              NUMBER(10, 0)    NOT NULL,
    LABEL               VARCHAR2(255)    NOT NULL,
    LOOKUP_KEY          VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_ISSUE_RAG_STATUS PRIMARY KEY (CSRIMP_SESSION_ID, RAG_STATUS_ID),    
    CONSTRAINT FK_ISSUE_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ISSUE_TYPE_RAG_STATUS(
    CSRIMP_SESSION_ID   NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    ISSUE_TYPE_ID       NUMBER(10, 0)    NOT NULL,
    RAG_STATUS_ID       NUMBER(10, 0)    NOT NULL,
    POS                 NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_ISSUE_TYPE_RAG_STATUS PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_TYPE_ID, RAG_STATUS_ID),    
    CONSTRAINT FK_ISSUE_TYPE_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);  

DROP TABLE csrimp.map_issue_type_rag_status PURGE;

CREATE TABLE csrimp.map_issue_rag_status (
    CSRIMP_SESSION_ID           NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_rag_status_id           NUMBER(10) NOT NULL,
    new_rag_status_id           NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_issue_rag_status PRIMARY KEY (old_rag_status_id) USING INDEX,
    CONSTRAINT uk_map_issue_rag_status UNIQUE (new_rag_status_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);


grant select on csr.issue_rag_status_id_seq to csrimp;
grant insert on csr.issue_rag_status to csrimp;

@..\csr_data_pkg
@..\issue_pkg
@..\schema_pkg
@..\teamroom_pkg

@..\issue_body
@..\schema_body
@..\teamroom_body
@..\initiative_body
@..\csrimp\imp_body

@update_tail