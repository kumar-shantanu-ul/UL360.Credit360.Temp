-- Please update version.sql too -- this keeps clean builds in sync
define version=77
@update_header

VARIABLE version NUMBER
BEGIN :version := 77; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


ALTER TABLE PENDING_IND ADD (
    DEFAULT_VAL_NUMBER NUMBER(24,10) NULL,
    DEFAULT_VAL_STRING VARCHAR2(255) NULL
);

ALTER TABLE CSR_USER ADD (
    FRIENDLY_NAME VARCHAR2(255) NULL
);

UPDATE CSR_USER 
   SET FRIENDLY_NAME = REGEXP_SUBSTR(FULL_NAME,'[^ ]+', 1, 1);

ALTER TABLE CSR_USER MODIFY FRIENDLY_NAME NOT NULL;

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (9, 'Mail sent when new approval step form created', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="LABEL"/></params>'); 
COMMIT;

update alert_type set params_xml = replace(params_xml, '<param name="FULL_NAME"/>','<param name="FULL_NAME"/><param name="FRIENDLY_NAME"/>');

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
