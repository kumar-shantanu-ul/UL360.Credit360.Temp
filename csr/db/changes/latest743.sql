-- Please update version.sql too -- this keeps clean builds in sync
define version=743
@update_header



-- fix up FLOW_STATE_TRANSITION_ROLE 
ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE DROP PRIMARY KEY DROP INDEX;

ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE ADD (FROM_STATE_ID NUMBER(10) NULL);

UPDATE csr.FLOW_STATE_TRANSITION_ROLE 
  SET FROM_STATE_ID = (
	SELECT FROM_STATE_ID 
	  FROM csr.FLOW_STATE_TRANSITION
	 WHERE FLOW_STATE_TRANSITION_ID = FLOW_STATE_TRANSITION_ROLE.FLOW_STATE_TRANSITION_ID
  );

ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE MODIFY FROM_STATE_ID NOT NULL;

ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT PK_FLOW_STATE_TRANS_ROLE PRIMARY KEY (APP_SID, FLOW_STATE_TRANSITION_ID, FROM_STATE_ID, ROLE_SID);

ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE DROP CONSTRAINT FK_ROLE_FLOW_ST_TR_ROLE;



-- now create flow_state_role
CREATE TABLE csr.FLOW_STATE_ROLE(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_ID    	NUMBER(10, 0)    NOT NULL,
    ROLE_SID            NUMBER(10, 0)    NOT NULL,
    IS_EDITABLE			NUMBER(1)		 DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_FLOW_STATE_ROLE_EDIT CHECK (IS_EDITABLE IN (0,1)),
    CONSTRAINT PK_FLOW_STATE_ROLE PRIMARY KEY (APP_SID, FLOW_STATE_ID, ROLE_SID)
);

INSERT INTO FLOW_STATE_ROLE (app_sid, flow_State_id, role_sid)
	SELECT DISTINCT app_sid, from_state_id, role_sid FROM flow_state_transition_role;
	
ALTER TABLE csr.FLOW_STATE_ROLE ADD CONSTRAINT FK_FLOW_STATE_FLOW_STATE_ROLE
    FOREIGN KEY (APP_SID, FLOW_STATE_ID)
    REFERENCES csr.FLOW_STATE(APP_SID, FLOW_STATE_ID)
;


ALTER TABLE csr.FLOW_STATE_ROLE ADD CONSTRAINT FK_ROLE_FLOW_STATE_ROLE 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID);

ALTER TABLE csr.FLOW_STATE_TRANSITION_ROLE ADD CONSTRAINT FK_FL_ST_ROLE_FL_ST_TR_ROLE 
    FOREIGN KEY (APP_SID, FROM_STATE_ID, ROLE_SID)
    REFERENCES csr.FLOW_STATE_ROLE(APP_SID, FLOW_STATE_ID, ROLE_SID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

DROP TYPE csr.T_FLOW_STATE_TABLE;

CREATE OR REPLACE TYPE csr.T_FLOW_STATE_ROW AS
	OBJECT (	
		POS					NUMBER(10), 
		ID					NUMBER(10), 
		LABEL				VARCHAR2(255), 
		LOOKUP_KEY			VARCHAR2(255),
		ROLE_SIDS			VARCHAR2(2000),
		ATTRIBUTES_XML		XMLType
	);
/

CREATE OR REPLACE TYPE csr.T_FLOW_STATE_TABLE AS
  TABLE OF csr.T_FLOW_STATE_ROW;
/


CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_Id, fs.flow_state_id current_state_id, fs.label current_state_label,
        fi.survey_response_id, fi.dashboard_instance_id  -- UPDATE THIS WHEN WE ADD MORE COLUMNS FOR JOINS TO WORKFLOW DETAIL TABLES
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid 
    ;   

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;
 
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANSITION AS
    SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb, 
		fs.flow_state_id from_state_id, fs.label from_state_label,
        tfs.flow_state_id to_state_id, tfs.label to_state_label, fst.ask_for_comment, fst.pos transition_pos,
        fi.survey_response_id, fi.dashboard_instance_id -- UPDATE THIS WHEN WE ADD MORE COLUMNS FOR JOINS TO WORKFLOW DETAIL TABLES
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
        JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
        JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid            
     WHERE tfs.is_deleted = 0
        ;

CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANS_ROLE_MEMBER AS
    SELECT fit.*, r.role_sid, r.name role_name, rrm.region_sid
      FROM V$FLOW_ITEM_TRANSITION fit
        JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
        JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;

@..\flow_pkg
@..\approval_dashboard_pkg

@..\flow_body
@..\approval_dashboard_body



INSERT INTO csr.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'My dashboards', 'Credit360.Portlets.MyApprovalDashboards', 
'/csr/site/portal/Portlets/MyApprovalDashboards.js');


@update_tail
