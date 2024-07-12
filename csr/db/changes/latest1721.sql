-- Please update version too -- this keeps clean builds in sync
define version=1721
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

ALTER TABLE CSR.Sheet ADD Is_Read_Only Number(1) DEFAULT 0;

CREATE OR REPLACE TYPE CSR.T_SHEET_INFO AS 
  OBJECT ( 
    SHEET_ID        		NUMBER(10,0),
    DELEGATION_SID        	NUMBER(10,0),
    PARENT_DELEGATION_SID   NUMBER(10,0),
    NAME            		VARCHAR2(255),
    CAN_SAVE        		NUMBER(10,0),
    CAN_SUBMIT        		NUMBER(10,0),
    CAN_ACCEPT        		NUMBER(10,0),
    CAN_RETURN        		NUMBER(10,0),
    CAN_DELEGATE        	NUMBER(10,0),
    CAN_VIEW        		NUMBER(10,0),
    CAN_OVERRIDE_DELEGATOR  NUMBER(10,0),
    CAN_COPY_FORWARD    	NUMBER(10,0),
    LAST_ACTION_ID        	NUMBER(10,0),
    START_DTM        		DATE,
    END_DTM            		DATE,
    INTERVAL        		VARCHAR2(1),
    GROUP_BY        		VARCHAR2(128),
    PERIOD_FMT        		VARCHAR2(255),    
    NOTE            		CLOB,
    USER_LEVEL        		NUMBER(10,0),
    IS_TOP_LEVEL        	NUMBER(10,0),
    IS_READ_ONLY    		NUMBER(1)
  );
/

@../sheet_pkg 
@../sheet_body
@../delegation_pkg 
@../delegation_body
@../region_body
@../measure_body

@update_tail