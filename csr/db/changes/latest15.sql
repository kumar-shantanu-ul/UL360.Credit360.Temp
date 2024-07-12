-- Please update version.sql too -- this keeps clean builds in sync
define version=15
@update_header

/* RUN ON LIVE ON 24 FEB 2006 */
/* BY RICHARD */

-- tighten up sheet_action_permissions so if not delegator/delegee, you can do nothing
update sheet_action_permission set can_view = 0 where user_level = 3;
COMMIT;

-- new override delegator permission
DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	new_class_id:=class_pkg.GetClassId('CSRDelegation');
	class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_OVERRIDE_DELEGATOR, 'Override delegator');
	class_PKG.createmapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_CHANGE_PERMISSIONS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_OVERRIDE_DELEGATOR);
END;
/
COMMIT;


-- add source_id and source_type_id columns (or rename where appropriate)
alter table val add (SOURCE_TYPE_ID NUMBER(10) null);
alter table val_change add (STATUS NUMBER(10) DEFAULT 0);
ALTER TABLE VAL RENAME COLUMN IMP_VAL_ID TO SOURCE_ID;
ALTER TABLE VAL_CHANGE ADD (SOURCE_ID NUMBER(10) null);
ALTER TABLE VAL_CHANGE RENAME COLUMN CHANGE_TYPE_ID TO SOURCE_TYPE_ID;

alter table val_change drop constraint REFCHANGE_TYPE35;

-- update source_type_id and source_id
DECLARE
BEGIN
	UPDATE VAL SET SOURCE_TYPE_ID = 2 WHERE source_id IS NOT NULL;
	UPDATE VAL SET SOURCE_TYPE_ID = 5 WHERE BASE = 1;
	UPDATE VAL SET SOURCE_TYPE_ID = 0 WHERE SOURCE_TYPE_ID IS NULL;
	UPDATE VAL_CHANGE SET SOURCE_TYPE_ID = 0;
	FOR r IN (select val_id, source_id, source_type_id from val_source)
	LOOP
		update val set source_id = r.source_id, source_type_id = r.source_type_id where val_id=r.val_id;
	END LOOP;
END;
/
COMMIT;

-- add extra entry to SOURCE_TYPE (0)
INSERT INTO SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (0, 'Manually entered');
commit;

-- remove nullability so we can add our constraint
ALTER TABLE val
MODIFY(source_Type_id NOT NULL);
ALTER TABLE val_change
MODIFY(source_Type_id NOT NULL);
-- add source_type_id constraints
ALTER TABLE VAL ADD CONSTRAINT RefSOURCE_TYPE205 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID);
ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefSOURCE_TYPE206 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID);



-- helper package stuff
ALTER TABLE SOURCE_TYPE ADD (HELPER_PKG varchar2(64) null);

BEGIN
	UPDATE SOURCE_TYPE SET HELPER_PKG='delegation_pkg' WHERE SOURCE_TYPE_ID = 1;
	UPDATE SOURCE_TYPE SET HELPER_PKG='imp_pkg' WHERE SOURCE_TYPE_ID = 2;
END;
/
COMMIT;



DROP TYPE T_CHANGES_TABLE;

CREATE OR REPLACE TYPE T_CHANGES_ROW AS 
  OBJECT ( 
	CHANGE_TYPE	NUMBER(10,0),
	FROM_VALUE	NUMBER(20,6),
	TO_VALUE	NUMBER(20,6),
	SHEET_VALUE_ID	NUMBER(10,0),
	DESCRIPTION	VARCHAR2(1024)
	
  );
/

CREATE OR REPLACE TYPE T_CHANGES_TABLE AS 
  TABLE OF T_CHANGES_ROW;
/

UPDATE SHEET_ACTION_PERMISSION SET CAN_ACCEPT = 1 WHERE SHEET_ACTION_ID = 6 AND USER_LEVEL = 1;
COMMIT;

	
-- 
-- TABLE: VAL_EXCLUSION 
--
DROP TABLE VAL_EXCLUSION;

CREATE TABLE VAL_EXCLUSION(
    CALC_IND_SID           NUMBER(10, 0)    NOT NULL,
    REGION_SID             NUMBER(10, 0)    NOT NULL,
    PERIOD_START_DTM       DATE             NOT NULL,
    PERIOD_END_DTM         DATE             NOT NULL,
    NORMALISING_IND_SID    NUMBER(10, 0)    NOT NULL,
    OVERRIDE_VALUE         NUMBER(20, 6)    NOT NULL,
    IS_BASE                NUMBER(10, 0)     DEFAULT 0,
    CONSTRAINT PK132 PRIMARY KEY (CALC_IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM, NORMALISING_IND_SID)
);

-- 
-- TABLE: VAL_EXCLUSION 
--

ALTER TABLE VAL_EXCLUSION ADD CONSTRAINT RefIND213 
    FOREIGN KEY (NORMALISING_IND_SID)
    REFERENCES IND(IND_SID)
;

ALTER TABLE VAL_EXCLUSION ADD CONSTRAINT RefREGION214 
    FOREIGN KEY (REGION_SID)
    REFERENCES REGION(REGION_SID)
;

ALTER TABLE VAL_EXCLUSION ADD CONSTRAINT RefIND215 
    FOREIGN KEY (CALC_IND_SID)
    REFERENCES IND(IND_SID)
;



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
	CAN_PROV_MERGE		NUMBER(10,0),
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



-- drop stuff we don't need any more (can always get it back from recycle bin)
DROP TABLE VAL_SOURCE;
DROP TABLE CHANGE_TYPE;

@update_tail
