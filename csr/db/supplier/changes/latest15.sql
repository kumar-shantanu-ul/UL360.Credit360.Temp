VARIABLE version NUMBER
BEGIN :version := 15; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


UPDATE tag SET explanation = 'Contains wood (excluding packaging)' WHERE tag = 'containsWood';
UPDATE tag SET explanation = 'Contains pulp or fluff made from wood (excluding packaging)' WHERE tag = 'containsPulp';
UPDATE tag SET explanation = 'Contains paper (excluding packaging)' WHERE tag = 'containsPaper';
UPDATE tag SET explanation = 'Contains natural materials or ingredients (except wood, pulp or paper)' WHERE tag = 'containsNaturalProducts';
 
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
