VARIABLE version NUMBER
BEGIN :version := 20; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE ALERT_BATCH 
	RENAME COLUMN REMINDER_RUN_AT TO RUN_TIME;

ALTER TABLE ALERT_BATCH ADD (
	DAY_OF_WEEK		NUMBER(10)	NULL,
	DAY_OF_MONTH	NUMBER(10)	NULL
);

UPDATE csr.alert_type SET params_xml = 
	'<params>' ||
		'<param name="FULL_NAME"/>' ||
		'<param name="FRIENDLY_NAME"/>' ||
		'<param name="EMAIL"/>' ||
		'<param name="USER_NAME"/>' ||
		'<param name="PROVIDING_LIST"/>' ||
		'<param name="PROVIDING_N"/>' ||
		'<param name="PROVIDING_CR_N"/>' ||
		'<param name="APPROVING_LIST"/>' ||
		'<param name="APPROVING_N"/>' ||
		'<param name="APPROVING_CR_N"/>' ||
	'</params>'
 WHERE alert_type_id = 1003;

-- Update version
UPDATE supplier.version SET db_version = :version;

COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
