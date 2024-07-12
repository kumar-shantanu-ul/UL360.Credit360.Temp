VARIABLE version NUMBER
BEGIN :version := 25; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

-- TABLE: DONATION_DOC 
--
CREATE TABLE DONATION_DOC(
    DONATION_ID     NUMBER(10, 0)    NOT NULL,
    DOCUMENT_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK92 PRIMARY KEY (DONATION_ID, DOCUMENT_SID)
)
;

-- 
-- TABLE: DONATION_DOC 
--

ALTER TABLE DONATION_DOC ADD CONSTRAINT RefDONATION124 
    FOREIGN KEY (DONATION_ID)
    REFERENCES DONATION(DONATION_ID)
;

-- support for multiple documents
INSERT INTO DONATION_DOC (donation_Id, document_sid)
	SELECT donation_id, document_sid from donation where document_sid is not null;
	
-- ALTER TABLE DONATION DROP COLUMN DOCUMENT_SID;


UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


