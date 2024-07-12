VARIABLE version NUMBER
BEGIN :version := 35; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE gt_pack_item
add CONSTRAINT CHK_WEIGHT_GRAMS CHECK (WEIGHT_GRAMS > 0);

ALTER table gt_trans_pack_type
	ADD (GT_SCORE NUMBER(10, 2));

alter table gt_trans_pack_type 	modify (GT_SCORE not null);

ALTER TABLE gt_profile DROP COLUMN recycled_pack_count_msg;

set define off
@../greentick/basedata/product_info_basedata.sql
@../greentick/basedata/formulation_basedata.sql
@../greentick/basedata/packaging_basedata.sql
@../greentick/basedata/transport_basedata.sql
@../greentick/basedata/supplier_relation_basedata.sql

-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
