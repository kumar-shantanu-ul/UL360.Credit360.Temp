-- Please update version.sql too -- this keeps clean builds in sync
define version=137
@update_header


CREATE TABLE SHEET_VALUE_FILE(
    SHEET_VALUE_ID     NUMBER(10, 0)    NOT NULL,
    FILE_UPLOAD_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK387 PRIMARY KEY (SHEET_VALUE_ID, FILE_UPLOAD_SID)
);

ALTER TABLE SHEET_VALUE_FILE ADD CONSTRAINT RefFILE_UPLOAD732 
    FOREIGN KEY (FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(FILE_UPLOAD_SID)
;

ALTER TABLE SHEET_VALUE_FILE ADD CONSTRAINT RefSHEET_VALUE733 
    FOREIGN KEY (SHEET_VALUE_ID)
    REFERENCES SHEET_VALUE(SHEET_VALUE_ID)
;

INSERT INTO SHEET_VALUE_FILE
	(SELECT sheet_value_id, file_upload_sid
	   FROM SHEET_VALUE
	  WHERE file_upload_sid IS NOT NULL)
;
COMMIT;

ALTER TABLE SHEET_VALUE 
	DROP COLUMN FILE_UPLOAD_SID
;
	
CREATE OR REPLACE FORCE VIEW SHEET_VALUE_CONVERTED 
	(SHEET_VALUE_ID, SHEET_ID, IND_SID, REGION_SID, VAL_NUMBER, SET_BY_USER_SID, 
		SET_DTM, NOTE, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, IS_INHERITED, 
		STATUS, LAST_SHEET_VALUE_CHANGE_ID, ALERT, FLAG, FACTOR, 
		START_DTM, END_DTM, ACTUAL_VAL_NUMBER) AS 
  SELECT sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
           sv.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number,
           sv.set_by_user_sid, sv.set_dtm, sv.note,
           sv.entry_measure_conversion_id, sv.entry_val_number,
           sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
           sv.alert, sv.flag,
           NVL(mc.conversion_factor, mcp.conversion_factor) factor,
           s.start_dtm, s.end_dtm, sv.val_number actual_val_number
      FROM SHEET_VALUE SV, SHEET S, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
     WHERE SV.SHEET_ID = S.SHEET_ID
       AND SV.entry_measure_conversion_id = mc.measure_conversion_id(+)
       AND MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
       AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
       AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
;

COMMIT;


CREATE TABLE SHEET_VALUE_CHANGE_FILE(
    SHEET_VALUE_CHANGE_ID    NUMBER(10, 0)    NOT NULL,
    FILE_UPLOAD_SID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK390 PRIMARY KEY (SHEET_VALUE_CHANGE_ID, FILE_UPLOAD_SID)
)
;

ALTER TABLE SHEET_VALUE_CHANGE_FILE ADD CONSTRAINT RefFILE_UPLOAD736 
    FOREIGN KEY (FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(FILE_UPLOAD_SID)
;

ALTER TABLE SHEET_VALUE_CHANGE_FILE ADD CONSTRAINT RefSHEET_VALUE_CHANGE737 
    FOREIGN KEY (SHEET_VALUE_CHANGE_ID)
    REFERENCES SHEET_VALUE_CHANGE(SHEET_VALUE_CHANGE_ID)
;

INSERT INTO SHEET_VALUE_CHANGE_FILE
	(SELECT sheet_value_change_id, file_upload_sid
	   FROM SHEET_VALUE_CHANGE
	  WHERE file_upload_sid IS NOT NULL)
;
COMMIT;

ALTER TABLE SHEET_VALUE_CHANGE
	DROP COLUMN FILE_UPLOAD_SID
;

	

CREATE GLOBAL TEMPORARY TABLE GET_VALUE_RESULT
(
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	source_id			NUMBER(10,0),
	ind_sid				NUMBER(10,0),
	region_sid			NUMBER(10,0),
	val_number			NUMBER(24,10),
	changed_dtm			DATE,
	note				CLOB,
	flags				NUMBER (10,0),
	is_leaf				NUMBER(1,0),
	path				VARCHAR2(1024)
) ON COMMIT DELETE ROWS;



CREATE OR REPLACE FORCE VIEW VAL_CONVERTED (VAL_ID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM, VAL_NUMBER, STATUS, ALERT, FLAGS, SOURCE_ID, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, LAST_VAL_CHANGE_ID, NOTE, SOURCE_TYPE_ID, FACTOR) AS 
SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
      v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
      v.status, v.alert, v.flags, v.source_id,
      v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
      v.note, v.source_type_id,
      NVL(mc.conversion_factor, mcp.conversion_factor) factor
 FROM VAL V, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
WHERE MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
  AND V.entry_measure_conversion_id = mc.measure_conversion_id(+)
  AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
  AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);



CREATE TABLE VAL_FILE(
    VAL_ID             NUMBER(10, 0)    NOT NULL,
    FILE_UPLOAD_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK393 PRIMARY KEY (VAL_ID, FILE_UPLOAD_SID)
)
;

ALTER TABLE VAL_FILE ADD CONSTRAINT RefFILE_UPLOAD740 
    FOREIGN KEY (FILE_UPLOAD_SID)
    REFERENCES FILE_UPLOAD(FILE_UPLOAD_SID)
;

ALTER TABLE VAL_FILE ADD CONSTRAINT RefVAL741 
    FOREIGN KEY (VAL_ID)
    REFERENCES VAL(VAL_ID)
;

INSERT INTO VAL_FILE
	(SELECT val_id, file_upload_sid
	   FROM val
	  WHERE file_upload_sid IS NOT NULL)
;
COMMIT;

ALTER TABLE VAL
	DROP COLUMN FILE_UPLOAD_SID
;


@update_tail
