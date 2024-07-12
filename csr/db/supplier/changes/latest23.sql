VARIABLE version NUMBER
BEGIN :version := 23; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


ALTER TABLE SUPPLIER_ANSWERS_WOOD ADD (
	declare_no_cities	NUMBER(1, 0)	NULL
);

UPDATE supplier_answers_wood SET declare_no_cities = 0;

ALTER TABLE SUPPLIER_ANSWERS_WOOD MODIFY
	declare_no_cities	NUMBER(1, 0)	NOT NULL
;


-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
