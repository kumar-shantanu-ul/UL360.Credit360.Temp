-- Please update version.sql too -- this keeps clean builds in sync
define version=88
@update_header

VARIABLE version NUMBER
BEGIN :version := 88; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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
-- 
-- SEQUENCE: PCT_OWNERSHIP_CHANGE_ID_SEQ 
--

CREATE SEQUENCE PCT_OWNERSHIP_CHANGE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


-- 
-- TABLE: PCT_OWNERSHIP_CHANGE 
--

CREATE TABLE PCT_OWNERSHIP_CHANGE(
    PCT_OWNERSHIP_CHANGE_ID    NUMBER(10, 0)    NOT NULL,
    ADDED_DTM                  DATE              DEFAULT SYSDATE NOT NULL,
    ADDED_BY_SID               NUMBER(10, 0)    NOT NULL,
    MEASURE_SID                NUMBER(10, 0),
    PCT_OWNERSHIP_APPLIES      NUMBER(1, 0) ,   
    REGION_SID                 NUMBER(10, 0),
    START_DTM                  DATE,
    END_DTM                    DATE,
    PCT                        NUMBER(10, 5),
    STARTED_PROCESSING_DTM     DATE,
    CONSTRAINT PK317 PRIMARY KEY (PCT_OWNERSHIP_CHANGE_ID)
)
;

-- 
-- TABLE: PCT_OWNERSHIP_CHANGE 
--

ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefREGION570 
    FOREIGN KEY (REGION_SID)
    REFERENCES REGION(REGION_SID)
;

ALTER TABLE PCT_OWNERSHIP_CHANGE ADD CONSTRAINT RefMEASURE571 
    FOREIGN KEY (MEASURE_SID)
    REFERENCES MEASURE(MEASURE_SID)
;




UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
