VARIABLE version NUMBER
BEGIN :version := 21; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

-- remove TESP/TISP value cols - just VALUE from now on
ALTER TABLE SUPPLIER.PRODUCT_SALES_VOLUME
RENAME COLUMN VALUE_TISP TO VALUE;

ALTER TABLE SUPPLIER.PRODUCT_SALES_VOLUME DROP COLUMN VALUE_TESP;

-- move audit type to new class

UPDATE csr.audit_type SET audit_type_group_id = 3  WHERE  audit_type_id = 70;


-- make following cols NULLable as one or other to be set
-- COMON NAME or SPECIES AND GENUS
ALTER TABLE SUPPLIER.NP_COMPONENT_DESCRIPTION
MODIFY(COMMON_NAME  NULL);


ALTER TABLE SUPPLIER.NP_COMPONENT_DESCRIPTION
MODIFY(SPECIES  NULL);


ALTER TABLE SUPPLIER.NP_COMPONENT_DESCRIPTION
MODIFY(GENUS  NULL);

-- Update version
UPDATE supplier.version SET db_version = :version;

COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
