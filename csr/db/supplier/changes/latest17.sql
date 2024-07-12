VARIABLE version NUMBER
BEGIN :version := 17; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

INSERT INTO CSR.audit_type_group (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES(2, 'Supplier module product');
INSERT INTO CSR.audit_type_group (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES(3, 'Supplier module questionnaire');

INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (50, 'Product created', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (51, 'Product details updated', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (52, 'Product supplier changed', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (53, 'Product data approver changed', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (54, 'Product data provider changed', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (55, 'Product deleted', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (56, 'Product tag changed', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (57, 'Product volume changed', 2);

INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (60, 'Supplier created', 1);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (61, 'Supplier details updated', 1);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (62, 'Assigned user to company', 1);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (63, 'Unassigned user from company', 1);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (64, 'Supplier deleted', 1);

INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (70, 'Product status change', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (71, 'Questionaire saved', 3);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (72, 'Questionaire status change', 3);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (73, 'Questionaire linked', 2);
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (74, 'Questionaire unlinked', 2);

COMMIT;
/

PROMPT > granting dodgy privileges...
PROMPT ====================================================
connect csr/csr@&&1;
grant select, references on audit_log to supplier;
COMMIT;
/

connect supplier/supplier@&&1;
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
