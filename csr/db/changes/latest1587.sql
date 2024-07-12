-- Please update version.sql too -- this keeps clean builds in sync
define version=1587
@update_header


ALTER TABLE CSR.FLOW_ITEM DROP CONSTRAINT FK_FLOW_ITEM_FL_ST_TRANS;

ALTER TABLE CSR.FLOW_ITEM ADD CONSTRAINT FK_FLOW_ITEM_FL_ST_TRANS 
    FOREIGN KEY (APP_SID, LAST_FLOW_STATE_TRANSITION_ID)
    REFERENCES CSR.FLOW_STATE_TRANSITION(APP_SID, FLOW_STATE_TRANSITION_ID)   DEFERRABLE INITIALLY DEFERRED
;


ALTER TABLE CSR.IND_SET_IND ADD (
    POS           NUMBER(10, 0)    DEFAULT 0 NOT NULL
);
 
ALTER TABLE CSR.REGION_SET_REGION ADD (
    POS           NUMBER(10, 0)    DEFAULT 0 NOT NULL
);

CREATE OR REPLACE TYPE CSR.T_HIERARCHY_ROW AS 
  OBJECT (
  SID_ID      NUMBER(10,0),
  LVL       NUMBER(10,0),
  ROOT_SID_ID   NUMBER(10,0),
  MAX_LVL     NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE CSR.T_HIERARCHY AS 
  TABLE OF CSR.T_HIERARCHY_ROW;
/


@..\region_pkg
@..\region_set_pkg
@..\indicator_set_pkg
@..\sheet_pkg
@..\delegation_pkg

@..\region_body
@..\region_set_body
@..\indicator_set_body
@..\sheet_body
@..\delegation_body


@update_tail