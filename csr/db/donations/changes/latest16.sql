VARIABLE version NUMBER
BEGIN :version := 16; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


-- 
-- SEQUENCE: FILTER_ID_SEQ 
--

CREATE SEQUENCE FILTER_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


-- 
-- TABLE: FILTER 
--

CREATE TABLE FILTER(
    FILTER_ID        NUMBER(10, 0)     NOT NULL,
    APP_SID          NUMBER(10, 0)     NOT NULL,
    CSR_USER_SID     NUMBER(10, 0)     NOT NULL,
    IS_SHARED        NUMBER(1, 0)       DEFAULT 0 NOT NULL,
    NAME             VARCHAR2(255)     NOT NULL,
    DESCRIPTION      VARCHAR2(2048),
    LAST_USED_DTM    DATE               DEFAULT SYSDATE NOT NULL,
    FILTER_XML       SYS.XMLType,
    COLUMN_XML       SYS.XMLType,
    CONSTRAINT PK86 PRIMARY KEY (FILTER_ID)
)
;

alter table csr.customer add constraint PK_CUSTOMER_APP_SID UNIQUE (APP_SID);

-- 
-- TABLE: FILTER 
--

ALTER TABLE FILTER ADD CONSTRAINT RefCSR_USER116 
    FOREIGN KEY (CSR_USER_SID)
    REFERENCES CSR.CSR_USER(CSR_USER_SID)
;

ALTER TABLE FILTER ADD CONSTRAINT RefCUSTOMER118 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;



UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


