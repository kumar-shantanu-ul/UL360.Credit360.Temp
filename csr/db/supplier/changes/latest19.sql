VARIABLE version NUMBER
BEGIN :version := 19; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


CREATE TABLE ALERT_BATCH(
    CSR_ROOT_SID    NUMBER(10, 0)    NOT NULL,
    REMINDER_RUN_AT          TIMESTAMP(6)     NOT NULL,
    CONSTRAINT PK140 PRIMARY KEY (CSR_ROOT_SID)
);

ALTER TABLE ALERT_BATCH ADD CONSTRAINT RefCUSTOMER210 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CSR.CUSTOMER(CSR_ROOT_SID)
;

-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
