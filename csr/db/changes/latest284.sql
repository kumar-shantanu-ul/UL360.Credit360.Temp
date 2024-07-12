-- Please update version.sql too -- this keeps clean builds in sync
define version=284
@update_header

INSERT INTO MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 VALUES
   (4, 'Comment Field');

INSERT INTO MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 VALUES
   (5, 'Ignore Formula');


ALTER TABLE model_map DROP column excel_name;

ALTER TABLE model_map ADD is_temp number(1) DEFAULT (0);

CREATE TABLE MODEL_VALIDATION(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MODEL_SID          NUMBER(10, 0)    NOT NULL,
    SHEET_NAME         VARCHAR2(255)    NOT NULL,
    CELL_NAME          VARCHAR2(20)     NOT NULL,
    DISPLAY_SEQ        NUMBER(10, 0)    NOT NULL,
    VALIDATION_TEXT    VARCHAR2(50)     NOT NULL,
    CONSTRAINT PK565 PRIMARY KEY (APP_SID, MODEL_SID, SHEET_NAME, CELL_NAME, DISPLAY_SEQ)
)
;

ALTER TABLE MODEL_VALIDATION ADD CONSTRAINT RefMODEL_MAP1093 
    FOREIGN KEY (APP_SID, MODEL_SID, SHEET_NAME, CELL_NAME)
    REFERENCES MODEL_MAP(APP_SID, MODEL_SID, SHEET_NAME, CELL_NAME)
;

@update_tail
