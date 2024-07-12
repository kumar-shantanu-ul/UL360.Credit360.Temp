-- Please update version.sql too -- this keeps clean builds in sync
define version=80
@update_header

VARIABLE version NUMBER
BEGIN :version := 80; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (12, 'Mail sent when sub-delegation takes place', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="FROM_FULL_NAME"/><param name="LABEL"/></params>'); 
COMMIT;

alter table measure add (
    PCT_OWNERSHIP_APPLIES    NUMBER(1, 0)       DEFAULT 0 NOT NULL
);


-- 
-- TABLE: PCT_OWNERSHIP 
--

CREATE TABLE PCT_OWNERSHIP(
    REGION_SID    NUMBER(10, 0)    NOT NULL,
    START_DTM     DATE             NOT NULL,
    END_DTM       DATE,
    PCT           NUMBER(10, 5)    NOT NULL,
    CONSTRAINT PK315 PRIMARY KEY (REGION_SID, START_DTM)
)
;


-- 
-- TABLE: PCT_OWNERSHIP 
--

ALTER TABLE PCT_OWNERSHIP ADD CONSTRAINT RefREGION564 
    FOREIGN KEY (REGION_SID)
    REFERENCES REGION(REGION_SID)
;

-- copy values over to entry_val_number
update val set entry_val_number = val_number where entry_measure_conversion_id is null and entry_val_number is null;

update sheet_value set entry_val_number = val_number where entry_measure_conversion_id is null and entry_val_number is null;

alter table region drop column pct_ownership;

begin
INSERT INTO SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR ) VALUES (12, 'Merged with modifications', 'R'); 
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 1, 1, 1, 0, 0, 1, 1);
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 3, 0, 0, 0, 0, 0, 0);
end;
/


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
