VARIABLE version NUMBER
BEGIN :version := 22; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM supplier.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


ALTER TABLE ALL_COMPANY ADD (
	COMPANY_STATUS_ID	NUMBER(10, 0)	NULL
);

CREATE TABLE COMPANY_STATUS(
    COMPANY_STATUS_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION          VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK85_1 PRIMARY KEY (COMPANY_STATUS_ID)
);

INSERT INTO COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(1, 'Data being entered');
INSERT INTO COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(2, 'Submitted for approval');
INSERT INTO COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(3, 'Approved');

UPDATE ALL_COMPANY SET COMPANY_STATUS_ID = 1;

ALTER TABLE ALL_COMPANY MODIFY 
	COMPANY_STATUS_ID NUMBER(10, 0)	NOT NULL;
	

CREATE OR REPLACE VIEW COMPANY 
	(COMPANY_SID, CSR_ROOT_SID, NAME, ADDRESS_1, ADDRESS_2, ADDRESS_3, ADDRESS_4, TOWN, STATE, 
		POSTCODE, COUNTRY_CODE, PHONE, PHONE_ALT, FAX, INTERNAL_SUPPLIER, ACTIVE, DELETED, COMPANY_STATUS_ID)
AS
SELECT AL.COMPANY_SID, AL.CSR_ROOT_SID, AL.NAME, AL.ADDRESS_1, AL.ADDRESS_2, AL.ADDRESS_3, AL.ADDRESS_4, AL.TOWN, AL.STATE, AL.POSTCODE, 
	AL.COUNTRY_CODE, AL.PHONE, AL.PHONE_ALT, AL.FAX, AL.INTERNAL_SUPPLIER, AL.ACTIVE, AL.DELETED, AL.COMPANY_STATUS_ID
FROM ALL_COMPANY AL
WHERE DELETED = 0;

-----

CREATE TABLE SUPPLIER_ANSWERS(
    CSR_ROOT_SID     NUMBER(10, 0)    NOT NULL,
    COMPANY_SID      NUMBER(10, 0)    NOT NULL,
    CSR_POLICY       NUMBER(1, 0)     NOT NULL,
    ENV_POLICY       NUMBER(1, 0)     NOT NULL,
    ETH_POLICY       NUMBER(1, 0)     NOT NULL,
    BIO_POLICY       NUMBER(1, 0)     NOT NULL,
    WRITTEN_PROCS    NUMBER(1, 0)     NOT NULL,
    NOTES            CLOB,
    CONSTRAINT PK142 PRIMARY KEY (CSR_ROOT_SID, COMPANY_SID)
);

CREATE TABLE SUPPLIER_ANSWERS_WOOD(
    CSR_ROOT_SID       NUMBER(10, 0)    NOT NULL,
    COMPANY_SID        NUMBER(10, 0)    NOT NULL,
    LEGAL_PROCS        NUMBER(1, 0)     NOT NULL,
    LEGAL_PROC_NOTE    CLOB,
    DECLARE_NO_APP     NUMBER(1, 0)     NOT NULL,
    CONSTRAINT PK143 PRIMARY KEY (CSR_ROOT_SID, COMPANY_SID)
);

ALTER TABLE SUPPLIER_ANSWERS ADD CONSTRAINT RefALL_COMPANY215 
    FOREIGN KEY (CSR_ROOT_SID, COMPANY_SID)
    REFERENCES ALL_COMPANY(CSR_ROOT_SID, COMPANY_SID);

ALTER TABLE SUPPLIER_ANSWERS_WOOD ADD CONSTRAINT RefALL_COMPANY216 
    FOREIGN KEY (CSR_ROOT_SID, COMPANY_SID)
    REFERENCES ALL_COMPANY(CSR_ROOT_SID, COMPANY_SID);

INSERT INTO questionnaire (questionnaire_id, class_name, friendly_name, active) VALUES(5, 'supplier', 'Supplier', 1);

-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
