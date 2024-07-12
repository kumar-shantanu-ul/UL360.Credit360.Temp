-- Please update version.sql too -- this keeps clean builds in sync
define version=76
@update_header

VARIABLE version NUMBER
BEGIN :version := 76; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/


INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (11, 'Mail sent upon rejection of data', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="LABEL"/></params>'); 
commit;	


ALTER TABLE APPROVAL_STEP_USER ADD (READ_ONLY NUMBER(1) DEFAULT 0 NOT NULL);


ALTER TABLE CUSTOMER ADD (APP_SID NUMBER(10) NULL);

UPDATE CUSTOMER SET APP_SID = (SELECT PARENT_SID_ID FROM SECURITY.SECURABLE_OBJECT WHERE SID_ID = CUSTOMER.CSR_ROOT_SID);

UPDATE CUSTOMER SET APP_SID = 0 WHERE APP_SID IS NULL;

ALTER TABLE CUSTOMER MODIFY APP_SID NOT NULL;

ALTER TABLE AUDIT_LOG ADD (
    PARAM_1 VARCHAR2(2048) NULL,
    PARAM_2 VARCHAR2(2048) NULL,
    PARAM_3 VARCHAR2(2048) NULL
);



UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
