VARIABLE version NUMBER
BEGIN :version := 7; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

INSERT INTO part_type (part_type_id, class_name, package) values (3, 'NP_PART_DESCRIPTION', 'natural_product_pkg');
INSERT INTO part_type (part_type_id, class_name, package) values (4, 'NP_COMPONENT_DESCRIPTION', 'natural_product_pkg');
INSERT INTO part_type (part_type_id, class_name, package) values (5, 'NP_PART_EVIDENCE_DESCRIPTION', 'natural_product_pkg');
COMMIT;


-- Yes yes, this will lose the data in ENV_HARVEST_SAFEGUARD_DESC, but there is NO DATA at the moment
ALTER TABLE NP_COMPONENT_DESCRIPTION
  DROP COLUMN ENV_HARVEST_SAFEGUARD_DESC;

ALTER TABLE NP_COMPONENT_DESCRIPTION
  ADD ENV_HARVEST_SAFEGUARD_DESC  CLOB  NOT NULL;

UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
