-- Please update version.sql too -- this keeps clean builds in sync
define version=106
@update_header

VARIABLE version NUMBER
BEGIN :version := 106; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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
-- TABLE: AUTOCREATE_USER 
--

CREATE TABLE AUTOCREATE_USER(
    GUID             CHAR(36)         NOT NULL,
    REQUESTED_DTM    DATE              DEFAULT SYSDATE NOT NULL,
    USER_NAME        VARCHAR2(255)    NOT NULL,
    CSR_ROOT_SID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK357 PRIMARY KEY (USER_NAME, CSR_ROOT_SID)
)
;


-- 
-- TABLE: AUTOCREATE_USER 
--

ALTER TABLE AUTOCREATE_USER ADD CONSTRAINT RefCUSTOMER646 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;




UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
