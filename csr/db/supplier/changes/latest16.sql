VARIABLE version NUMBER
BEGIN :version := 16; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(1000, 'Supplier user assigned to product', '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="PRODUCT_STATUS"/><param name="DUE_DATE"/><param name="DATA_PROVIDER"/><param name="DATA_APPROVER"/><param name="NEW_STATUS"/><param name="ASSIGNEMNT_TYPE"/></params>');
INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(1001, 'Supplier product activation state changed', '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="PRODUCT_STATUS"/><param name="DUE_DATE"/><param name="DATA_PROVIDER"/><param name="DATA_APPROVER"/><param name="ACTIVATION_TYPE"/></params>');
INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(1002, 'Supplier product approval status changed', '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="PRODUCT_STATUS"/><param name="DUE_DATE"/><param name="DATA_PROVIDER"/><param name="DATA_APPROVER"/><param name="STATUS"/><param name="COMMENT"/></params>');
INSERT INTO csr.alert_type (alert_type_id, description, params_xml) VALUES(1003, 'Supplier work reminder', '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PROVIDING_LIST"/><param name="PROVIDING_N"/><param name="APPROVING_LIST"/><param name="APPROVING_N"/></params>');
COMMIT;
 
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
