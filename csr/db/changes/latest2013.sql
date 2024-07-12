define version=2013
@update_header

CREATE TABLE CSR.FLOW_ALERT_CLASS(
    FLOW_ALERT_CLASS    VARCHAR2(256)    NOT NULL,
    LABEL               VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_FLOW_ALERT_CLASS PRIMARY KEY (FLOW_ALERT_CLASS)
);

CREATE TABLE CSR.CUSTOMER_FLOW_ALERT_CLASS(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_ALERT_CLASS    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_CUSTOMER_FLOW_ALERT_CLASS PRIMARY KEY (APP_SID, FLOW_ALERT_CLASS)
);

CREATE TABLE CSR.FLOW_ALERT_HELPER(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_ALERT_HELPER    VARCHAR2(256)     NOT NULL,
    LABEL                VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_FLOW_ALERT_HELPER PRIMARY KEY (APP_SID, FLOW_ALERT_HELPER)
);


ALTER TABLE CSR.FLOW ADD (
    FLOW_ALERT_CLASS    VARCHAR2(256)
);

ALTER TABLE CSR.FLOW_ALERT_TYPE ADD (
	LOOKUP_KEY			VARCHAR2(256)
);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT ADD (
	FLOW_ALERT_HELPER           VARCHAR2(256),
	FLOW_SID                    NUMBER(10, 0)
);

ALTER TABLE CSR.INITIATIVE_GROUP_FLOW_STATE ADD (
  GENERATE_ALERTS             NUMBER(1, 0)  DEFAULT 0 NOT NULL,
  CHECK (GENERATE_ALERTS IN (0, 1))
);

ALTER TABLE CSR.DEFAULT_INITIATIVE_USER_STATE ADD (
  GENERATE_ALERTS             NUMBER(1, 0)  DEFAULT 0 NOT NULL,
  CHECK (GENERATE_ALERTS IN (0, 1))
);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT ADD CONSTRAINT FK_TRANS_FLALERT_HELPER 
    FOREIGN KEY (APP_SID,FLOW_ALERT_HELPER)
    REFERENCES CSR.FLOW_ALERT_HELPER(APP_SID,FLOW_ALERT_HELPER)
;

ALTER TABLE CSR.CUSTOMER_FLOW_ALERT_CLASS ADD CONSTRAINT FK_CUSTOMER_CUSTFLALCLS 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.CUSTOMER_FLOW_ALERT_CLASS ADD CONSTRAINT FK_FLALCLS_CUSTFLALCLS 
    FOREIGN KEY (FLOW_ALERT_CLASS)
    REFERENCES CSR.FLOW_ALERT_CLASS(FLOW_ALERT_CLASS)
;

ALTER TABLE CSR.FLOW ADD CONSTRAINT FK_CUSTFLALCLS_FLOW 
    FOREIGN KEY (APP_SID, FLOW_ALERT_CLASS)
    REFERENCES CSR.CUSTOMER_FLOW_ALERT_CLASS(APP_SID, FLOW_ALERT_CLASS)
;

CREATE INDEX CSR.IX_TRANS_FLALERT_HELPER ON CSR.FLOW_TRANSITION_ALERT(APP_SID, FLOW_ALERT_HELPER);
CREATE INDEX CSR.IX_CUSTOMER_CUSTFLALCLS ON CSR.CUSTOMER_FLOW_ALERT_CLASS(APP_SID);
CREATE INDEX CSR.IX_FLALCLS_CUSTFLALCLS ON CSR.CUSTOMER_FLOW_ALERT_CLASS(FLOW_ALERT_CLASS);
CREATE INDEX CSR.IX_CUSTFLALCLS_FLOW ON CSR.FLOW(APP_SID, FLOW_ALERT_CLASS);


-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);
    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'CUSTOMER_FLOW_ALERT_CLASS',
        'FLOW_ALERT_HELPER'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin
                    
                    -- verify that the table has an app_sid column (dev helper)
                    select count(*) 
                      into v_found
                      from all_tab_columns 
                     where owner = 'CSR' 
                       and table_name = UPPER(v_list(i))
                       and column_name = 'APP_SID';
                    
                    if v_found = 0 then
                        raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
                    end if;
                    
                    if v_i = 1 then
                        v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    else
                        v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
                    end if;
                    dbms_output.put_line('doing '||v_name);
                    dbms_rls.add_policy(
                        object_schema   => 'CSR',
                        object_name     => v_list(i),
                        policy_name     => v_name,
                        function_schema => 'CSR',
                        policy_function => 'appSidCheck',
                        statement_types => 'select, insert, update, delete',
                        update_check    => true,
                        policy_type     => dbms_rls.context_sensitive );
                    -- dbms_output.put_line('done  '||v_name);
                    exit;
                exception
                    when policy_already_exists then
                        v_i := v_i + 1;
                    WHEN FEATURE_NOT_ENABLED THEN
                        DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
                        exit;
                end;
            end loop;
        end;
    end loop;
end;
/

CREATE OR REPLACE VIEW CSR.v$flow_item_alert AS
    SELECT fia.flow_item_alert_id, ftu.region_sid, ftu.user_sid, fta.flow_state_transition_id,
           fta.flow_transition_alert_id, fta.customer_alert_type_id, 
           flsf.flow_state_id from_state_id, flsf.label from_state_label,
           flst.flow_state_id to_state_id, flst.label to_state_label, 
           fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid,
           cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
           NVL(cut.csr_user_sid, fsl.set_by_user_sid) to_user_sid, cut.full_name to_full_name,
           cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
           fia.processed_dtm, fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
           fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper
      FROM flow_item_alert fia 
      JOIN flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
      JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
      JOIN flow_item fi ON fia.flow_item_id = fi.flow_item_id AND fia.app_sid = fi.app_sid
      JOIN flow_transition_alert fta 
        ON fia.flow_transition_alert_id = fta.flow_transition_alert_id 
       AND fia.app_sid = fta.app_sid            
       AND fta.deleted = 0
      JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
      JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
      JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid           
      LEFT JOIN (SELECT DISTINCT ftar.app_sid, ftar.flow_transition_alert_id, rrm.region_sid, rrm.user_sid
                   FROM flow_transition_alert_role ftar, region_role_member rrm
                  WHERE ftar.app_sid = rrm.app_sid AND ftar.role_sid = rrm.role_sid) ftu
        ON fta.to_initiator = 0 -- optionally, alerts can be to the person who initiated the transition (only)
       AND fta.flow_transition_alert_id = ftu.flow_transition_alert_id 
       AND fta.app_sid = ftu.app_sid
      LEFT JOIN csr_user cut ON ftu.user_sid = cut.csr_user_sid AND ftu.app_sid = cut.app_sid;

CREATE OR REPLACE VIEW csr.v$open_flow_item_alert AS        
    SELECT *
      FROM csr.v$flow_item_alert
     WHERE processed_dtm IS NULL;

BEGIN
    INSERT INTO csr.flow_alert_class (flow_alert_class, label) VALUES ('cms', 'CMS');
    INSERT INTO csr.flow_alert_class (flow_alert_class, label) VALUES ('initiatives', 'Initiatives');
END;
/

@../flow_pkg
@../flow_body
@../initiative_body
@../initiative_alert_pkg
@../initiative_alert_body


grant execute on csr.initiative_alert_pkg to web_user;

@update_tail
