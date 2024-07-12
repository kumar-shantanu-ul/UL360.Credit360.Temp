VARIABLE version NUMBER
BEGIN :version := 13; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM donations.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

alter table custom_value rename to custom_field;

alter table custom_field add (detailed_note clob, section varchar2(64));


ALTER TABLE DONATION ADD (
    CUSTOM_6                      NUMBER(16, 2),
    CUSTOM_7                      NUMBER(16, 2),
    CUSTOM_8                      NUMBER(16, 2),
    CUSTOM_9                      NUMBER(16, 2),
    CUSTOM_10                     NUMBER(16, 2)
);

alter table scheme add (note_hack clob);

alter table tag_group add (note varchar2(1024), detailed_note clob);
-- 
-- SEQUENCE: CONSTANT_ID_SEQ 
--

CREATE SEQUENCE CONSTANT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- TABLE: BUDGET_CONSTANT 
--

CREATE TABLE BUDGET_CONSTANT(
    BUDGET_ID      NUMBER(10, 0)    NOT NULL,
    CONSTANT_ID    NUMBER(10, 0)    NOT NULL,
    VAL            NUMBER(18, 4)    NOT NULL,
    CONSTRAINT PK81 PRIMARY KEY (BUDGET_ID, CONSTANT_ID)
)
;



-- 
-- TABLE: CONSTANT 
--

CREATE TABLE CONSTANT(
    CONSTANT_ID    NUMBER(10, 0)    NOT NULL,
    LOOKUP_KEY     VARCHAR2(255),
    APP_SID        NUMBER(10, 0),
    CONSTRAINT PK82 PRIMARY KEY (CONSTANT_ID)
)
;



-- 
-- INDEX: UNIQUE_APP_CONSTANT 
--

CREATE UNIQUE INDEX UNIQUE_APP_CONSTANT ON CONSTANT(LOOKUP_KEY, APP_SID)
;


-- 
-- TABLE: BUDGET_CONSTANT 
--

ALTER TABLE BUDGET_CONSTANT ADD CONSTRAINT RefCONSTANT111 
    FOREIGN KEY (CONSTANT_ID)
    REFERENCES CONSTANT(CONSTANT_ID)
;

ALTER TABLE BUDGET_CONSTANT ADD CONSTRAINT RefBUDGET112 
    FOREIGN KEY (BUDGET_ID)
    REFERENCES BUDGET(BUDGET_ID)
;





UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


