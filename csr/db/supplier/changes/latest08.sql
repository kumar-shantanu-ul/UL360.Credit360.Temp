VARIABLE version NUMBER
BEGIN :version := 8; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

INSERT INTO QUESTIONNAIRE_STATUS (
   QUESTIONNAIRE_STATUS_ID, STATUS) 
VALUES (0 , 'Not Requested');

ALTER TABLE SUPPLIER.QUESTIONNAIRE
ADD (active NUMBER DEFAULT 1);

COMMIT;

UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
