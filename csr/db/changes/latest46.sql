-- Please update version.sql too -- this keeps clean builds in sync
define version=46
@update_header


DROP TYPE T_SHEET_INFO;

CREATE OR REPLACE TYPE T_SHEET_INFO AS 
  OBJECT ( 
	SHEET_ID		NUMBER(10,0),
	DELEGATION_SID		NUMBER(10,0),
	PARENT_DELEGATION_SID	NUMBER(10,0),
	NAME			VARCHAR2(255),
	CAN_SAVE		NUMBER(10,0),
	CAN_SUBMIT		NUMBER(10,0),
	CAN_ACCEPT		NUMBER(10,0),
	CAN_RETURN		NUMBER(10,0),
	CAN_DELEGATE		NUMBER(10,0),
	CAN_VIEW		NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR		NUMBER(10,0),
	LAST_ACTION_ID		NUMBER(10,0),
	START_DTM		DATE,
	END_DTM			DATE,
	INTERVAL		CHAR(1),
	GROUP_BY		VARCHAR2(128),
	PERIOD_FMT		VARCHAR2(255),	
	NOTE			CLOB,
	USER_LEVEL		NUMBER(10,0),
	IS_TOP_LEVEL		NUMBER(10,0)
  );
/


-- VIEW: TAG_GROUP_IR_MEMBER 
--

CREATE VIEW TAG_GROUP_IR_MEMBER AS
SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_tag.region_sid, ind_tag.ind_sid
  FROM tag_group_member tgm, 
  	tag t LEFT OUTER JOIN ind_tag ON ind_tag.tag_id = t.tag_id 
    	LEFT OUTER JOIN region_tag ON region_tag.tag_id = t.tag_id   
 WHERE tgm.tag_id = t.tag_id
;

CREATE UNIQUE INDEX PK_ALT_TAG_GROUP ON TAG_GROUP(CSR_ROOT_SID, LOWER(NAME))
TABLESPACE INDX
;

@update_tail
