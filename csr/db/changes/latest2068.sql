-- Please update version.sql too -- this keeps clean builds in sync
define version=2068
@update_header


CREATE SEQUENCE CSR.FLOW_STATE_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE TABLE CSR.FLOW_STATE_ALERT(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID                  NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ALERT_ID       NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID             NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_ALERT_HELPER         VARCHAR2(256),
    DESCRIPTION               VARCHAR2(500)    NOT NULL,
    DELETED                   NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    RECURRENCE_PATTERN        SYS.XMLType      NOT NULL,
    CONSTRAINT CK_FLOW_TRANS_ALERT_DELETED_1 CHECK (deleted in (0,1)),
    CONSTRAINT PK_FLOW_STATE_ALERT PRIMARY KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
);

CREATE TABLE CSR.FLOW_STATE_ALERT_ROLE(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID               NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID               NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_STATE_ALERT_ROLE PRIMARY KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID, ROLE_SID)
);

CREATE TABLE CSR.FLOW_STATE_ALERT_USER(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID               NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    USER_SID               NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_STATE_ALERT_USER PRIMARY KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID, USER_SID)
);

CREATE TABLE CSR.FLOW_STATE_ALERT_RUN(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID               NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    USER_SID               NUMBER(10, 0)    NOT NULL,
    LAST_FIRE_DATE         DATE,
    NEXT_FIRE_DATE         DATE             NOT NULL,
    CONSTRAINT PK_FLOW_STATE_ALERT_RUN PRIMARY KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID, USER_SID)
);


ALTER TABLE CSR.FLOW_STATE_ALERT ADD CONSTRAINT FK_FLALTHLP_FLSTALT 
    FOREIGN KEY (APP_SID, FLOW_ALERT_HELPER)
    REFERENCES CSR.FLOW_ALERT_HELPER(APP_SID, FLOW_ALERT_HELPER)
;

ALTER TABLE CSR.FLOW_STATE_ALERT ADD CONSTRAINT FK_FLALTTYP_FLSTALT 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.FLOW_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT ADD CONSTRAINT FK_FLOW_FLOWSTATEALERT 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT ADD CONSTRAINT FK_FLST_FLSTALT 
    FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_SID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE ADD CONSTRAINT FK_FLSTALT_FLSTALTRL 
    FOREIGN KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
    REFERENCES CSR.FLOW_STATE_ALERT(APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_ROLE ADD CONSTRAINT FK_RL_FLSTALTRL 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_USER ADD CONSTRAINT FK_FLSTALT_FLSTALTUSR 
    FOREIGN KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
    REFERENCES CSR.FLOW_STATE_ALERT(APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_USER ADD CONSTRAINT FK_USR_FLSTALTUSR 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_RUN ADD CONSTRAINT FK_FLSTALT_FLSTALTRUN 
    FOREIGN KEY (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
    REFERENCES CSR.FLOW_STATE_ALERT(APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID)
;

ALTER TABLE CSR.FLOW_STATE_ALERT_RUN ADD CONSTRAINT FK_USER_FLSTALTRUN 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;


CREATE INDEX CSR.IX_FLALTHLP_FLSTALT ON CSR.FLOW_STATE_ALERT (APP_SID, FLOW_ALERT_HELPER);
CREATE INDEX CSR.IX_FLALTTYP_FLSTALT ON CSR.FLOW_STATE_ALERT (APP_SID, CUSTOMER_ALERT_TYPE_ID);
CREATE INDEX CSR.IX_FLOW_FLOWSTATEALERT ON CSR.FLOW_STATE_ALERT (APP_SID, FLOW_SID);
CREATE INDEX CSR.IX_FLST_FLSTALT ON CSR.FLOW_STATE_ALERT (APP_SID, FLOW_STATE_ID, FLOW_SID);
CREATE INDEX CSR.IX_FLSTALT_FLSTALTRL ON CSR.FLOW_STATE_ALERT_ROLE (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID);
CREATE INDEX CSR.IX_RL_FLSTALTRL ON CSR.FLOW_STATE_ALERT_ROLE (APP_SID, ROLE_SID);
CREATE INDEX CSR.IX_FLSTALT_FLSTALTUSR ON CSR.FLOW_STATE_ALERT_USER (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID);
CREATE INDEX CSR.IX_USR_FLSTALTUSR ON CSR.FLOW_STATE_ALERT_USER (APP_SID, USER_SID);
CREATE INDEX CSR.IX_FLSTALT_FLSTALTRUN ON CSR.FLOW_STATE_ALERT_RUN (APP_SID, FLOW_SID, FLOW_STATE_ALERT_ID);
CREATE INDEX CSR.IX_USER_FLSTALTRUN ON CSR.FLOW_STATE_ALERT_RUN (APP_SID, USER_SID);


CREATE OR REPLACE VIEW CSR.v$flow_state_alert_user AS
    SELECT a.flow_sid, a.flow_state_alert_id, au.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_user au ON au.flow_sid = a.flow_sid AND au.flow_state_alert_id = a.flow_state_alert_id
    UNION
    SELECT a.flow_sid, a.flow_state_alert_id, rrm.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_role ar ON ar.flow_sid = a.flow_sid AND ar.flow_state_alert_id = a.flow_state_alert_id
      JOIN region_role_member rrm ON rrm.role_sid = ar.role_sid AND rrm.region_sid = rrm.inherited_from_sid
;

-- Selects all initiative/user associations, either by role or initiatvie user gorup
CREATE OR REPLACE VIEW csr.v$initiative_user AS
    SELECT app_sid, user_sid, initiative_sid, region_sid, flow_state_id, 
        flow_state_label, flow_state_lookup_key, flow_state_colour, active,
        MAX(is_editable) is_editable, MAX(generate_alerts) generate_alerts
    FROM (
        SELECT rrm.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(fsr.is_editable) is_editable,
            1 generate_alerts,
            rg.active
            FROM region_role_member rrm
            JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
            JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
            JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
            JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
            JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
            JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
            JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
         GROUP BY rrm.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            r.role_sid, r.name,
            rg.active
        UNION
        SELECT iu.user_sid, 
            i.app_sid, i.initiative_sid,
            ir.region_sid, 
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(igfs.is_editable) is_editable,
            MAX(igfs.generate_alerts) generate_alerts,
            rg.active
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
         GROUP BY iu.user_sid, 
            i.app_sid, i.initiative_sid, ir.region_sid, 
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            rg.active
    ) GROUP BY app_sid, user_sid, initiative_sid, region_sid, flow_state_id, 
        flow_state_label, flow_state_lookup_key, flow_state_colour, active;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FLOW_STATE_ALERT_RUN
(
    APP_SID                         NUMBER(10)  DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_SID                        NUMBER(10)  NOT NULL,
    FLOW_STATE_ALERT_ID             NUMBER(10)  NOT NULL,
    USER_SID                        NUMBER(10)  NOT NULL,
    THIS_FIRE_DATE                  DATE        NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE INDEX CSR.IX_TMPFLSTALTRUN_FLST ON CSR.TEMP_FLOW_STATE_ALERT_RUN (app_sid, flow_sid, flow_state_alert_id);
CREATE INDEX CSR.IX_TMPFLSTALTRUN_FLSTUSR ON CSR.TEMP_FLOW_STATE_ALERT_RUN (app_sid, flow_sid, flow_state_alert_id, user_sid);


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
        'FLOW_STATE_ALERT',
        'FLOW_STATE_ALERT_ROLE',
        'FLOW_STATE_ALERT_RUN',
        'FLOW_STATE_ALERT_USER'
);
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin
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

@../flow_pkg
@../initiative_alert_pkg

@../flow_body
@../initiative_alert_body

@update_tail
