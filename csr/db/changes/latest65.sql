-- Please update version.sql too -- this keeps clean builds in sync
define version=65
@update_header

VARIABLE version NUMBER
BEGIN :version := 65; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE


-- allow nulls in pending_val.approval_step_id
ALTER TABLE PENDING_VAL DROP CONSTRAINT RefAPPROVAL_STEP484 ;
ALTER TABLE PENDING_VAL MODIFY APPROVAL_STEP_ID NULL;
ALTER TABLE PENDING_VAL ADD (NOTE CLOB);

ALTER TABLE PENDING_VAL_VARIANCE DROP COLUMN COMPARED_WITH_END_DTM;
ALTER TABLE PENDING_VAL_VARIANCE ADD (COMPARED_WITH_END_DTM DATE NOT NULL);


-- 
-- SEQUENCE: PENDING_VAL_COMMENT_ID_SEQ 
--

CREATE SEQUENCE PENDING_VAL_COMMENT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE TABLE PENDING_VAL_COMMENT(
    PENDING_VAL_ID            NUMBER(10, 0),
    PENDING_VAL_COMMENT_ID    NUMBER(10, 0)    NOT NULL,
    SET_DTM                   DATE              DEFAULT SYSDATE NOT NULL,
    SET_BY_USER_SID           NUMBER(10, 0)    NOT NULL,
    COMMENT_TEXT                   CLOB,
    CONSTRAINT PK300 PRIMARY KEY (PENDING_VAL_COMMENT_ID)
)
;

ALTER TABLE PENDING_VAL_COMMENT ADD CONSTRAINT RefCSR_USER522 
    FOREIGN KEY (SET_BY_USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;

ALTER TABLE PENDING_VAL_COMMENT ADD CONSTRAINT RefPENDING_VAL523 
    FOREIGN KEY (PENDING_VAL_ID)
    REFERENCES PENDING_VAL(PENDING_VAL_ID)
;


ALTER TABLE PENDING_VAL_LOG ADD CONSTRAINT RefCSR_USER524 
    FOREIGN KEY (SET_BY_USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;




UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT

@update_tail
