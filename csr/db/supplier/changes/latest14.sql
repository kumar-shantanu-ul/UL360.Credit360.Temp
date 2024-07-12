VARIABLE version NUMBER
BEGIN :version := 14; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

UPDATE questionnaire SET class_name = 'wood' WHERE questionnaire_id = 1;
UPDATE questionnaire SET class_name = 'naturalProduct' WHERE questionnaire_id = 2;
UPDATE questionnaire SET class_name = 'plantExtracts' WHERE questionnaire_id = 3;
UPDATE questionnaire SET class_name = 'accreditedPackaging' WHERE questionnaire_id = 4;
COMMIT;
 
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
