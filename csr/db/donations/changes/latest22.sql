VARIABLE version NUMBER
BEGIN :version := 22; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE DONATION ADD (
	CUSTOM_21                      NUMBER(16, 2),
	CUSTOM_22                      NUMBER(16, 2),
	CUSTOM_23                      NUMBER(16, 2),
	CUSTOM_24                      NUMBER(16, 2),
	CUSTOM_25                      NUMBER(16, 2),
	CUSTOM_26                      NUMBER(16, 2),
	CUSTOM_27                      NUMBER(16, 2),
	CUSTOM_28                      NUMBER(16, 2),
	CUSTOM_29                      NUMBER(16, 2),
	CUSTOM_30                     NUMBER(16, 2),
	CUSTOM_31                     NUMBER(16, 2),
	CUSTOM_32                     NUMBER(16, 2),
	CUSTOM_33                     NUMBER(16, 2),
	CUSTOM_34                     NUMBER(16, 2),
	CUSTOM_35                     NUMBER(16, 2),
	CUSTOM_36                     NUMBER(16, 2),
	CUSTOM_37                     NUMBER(16, 2),
	CUSTOM_38                     NUMBER(16, 2),
	CUSTOM_39                     NUMBER(16, 2),
	CUSTOM_40                     NUMBER(16, 2)
);

UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


