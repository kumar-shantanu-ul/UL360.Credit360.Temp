-- Please update version.sql too -- this keeps clean builds in sync
define version=1654
@update_header

CREATE TABLE CSR.ROUTE_STEP_VOTE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ROUTE_STEP_ID         NUMBER(10, 0)    NOT NULL,
    USER_SID              NUMBER(10, 0)    NOT NULL,
    VOTE_DTM              DATE             DEFAULT SYSDATE NOT NULL,
    VOTE_DIRECTION        NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    DEST_ROUTE_STEP_ID    NUMBER(10, 0),
    DEST_FLOW_STATE_ID    NUMBER(10, 0),
    CONSTRAINT CHK_ROUTE_STEP_VOTE_DIR CHECK (VOTE_DIRECTION IN (-1, 1)),
    CONSTRAINT PK_ROUTE_STEP_APPROVED PRIMARY KEY (APP_SID, ROUTE_STEP_ID, USER_SID)
);


ALTER TABLE CSR.ROUTE_STEP_VOTE ADD CONSTRAINT FK_FL_STATE_RT_STP_VOTE 
    FOREIGN KEY (APP_SID, DEST_FLOW_STATE_ID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID);

ALTER TABLE CSR.ROUTE_STEP_VOTE ADD CONSTRAINT FK_RT_STEP_RT_STEP_APPR 
    FOREIGN KEY (APP_SID, ROUTE_STEP_ID)
    REFERENCES CSR.ROUTE_STEP(APP_SID, ROUTE_STEP_ID);

ALTER TABLE CSR.ROUTE_STEP_VOTE ADD CONSTRAINT FK_RT_STEP_RT_STEP_VOTE 
    FOREIGN KEY (APP_SID, DEST_ROUTE_STEP_ID)
    REFERENCES CSR.ROUTE_STEP(APP_SID, ROUTE_STEP_ID);

ALTER TABLE CSR.ROUTE_STEP_VOTE ADD CONSTRAINT FK_USR_RT_STEP_VOTE 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);


/* text */
CREATE OR REPLACE VIEW csr.v$my_section AS
    SELECT s.section_sid, firm.current_state_id, MAX(firm.is_editable) is_editable, 'F' source
      FROM csr.v$flow_item_role_member firm
        JOIN csr.section s ON firm.flow_item_id = s.flow_item_id AND firm.app_sid = s.app_sid
        JOIN csr.section_module sm
            ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
            AND firm.region_sid = sm.region_sid AND firm.app_sid = sm.app_sid
     WHERE NOT EXISTS (
        -- exclude if sections are currently in a workflow state that is routed
        SELECT null FROM csr.section_routed_flow_state WHERE flow_state_id = firm.current_state_id
     )
     GROUP BY s.section_sid, firm.current_state_id
    UNION ALL
    -- everything where the section is currently in a workflow state that is routed, and the user is in the currently route_step
    SELECT s.section_sid, fi.current_state_id, 1 is_editable, 'R' source
      FROM csr.section s
        JOIN csr.flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
        JOIN csr.route r ON fi.current_state_id = r.flow_state_id AND fi.app_sid = r.app_sid
        JOIN csr.route_step rs
            ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
            AND s.current_route_step_id = rs.route_step_id AND s.app_sid = rs.app_sid
        JOIN csr.route_step_user rsu
            ON rs.route_step_id = rsu.route_step_id
            AND rs.app_sid = rsu.app_sid
            AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
      WHERE s.current_route_step_id NOT IN (
        SELECT route_step_id FROM route_step_vote WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
      );


declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
    v_name varchar2(255);
begin   
    v_list := t_tabs(
        'INCIDENT_TYPE',
        'ROUTE_STEP_VOTE'
    );
    for i in 1 .. v_list.count loop
		begin               
			v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
			
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
				NULL;
		end;
    end loop;
end;
/


@..\section_pkg
@..\section_body
							 
@update_tail


