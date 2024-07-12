VARIABLE version NUMBER
BEGIN :version := 18; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE SUPPLIER.TAG_GROUP
ADD (DESCRIPTION VARCHAR2(1024 BYTE));

UPDATE SUPPLIER.TAG_GROUP SET description = 'Product Category', multi_select = 1 WHERE name = 'product_category';
UPDATE SUPPLIER.TAG_GROUP SET description = 'Sale Type' WHERE name = 'sale_type';
UPDATE SUPPLIER.TAG_GROUP SET description = 'Merchant Type' WHERE name = 'merchant_type';

ALTER TABLE SUPPLIER.TAG_GROUP
MODIFY(DESCRIPTION  NOT NULL);

-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;


PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
