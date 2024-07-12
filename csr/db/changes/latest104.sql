-- Please update version.sql too -- this keeps clean builds in sync
define version=104
@update_header

VARIABLE version NUMBER
BEGIN :version := 104; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

----
PROMPT Add audit log type class table - that defines what group an audit log entry belongs to

CREATE TABLE AUDIT_TYPE_OBJECT_CLASS
(
  AUDIT_TYPE_OBJECT_CLASS_ID  NUMBER(22,10)     NOT NULL,
  NAME                        VARCHAR2(256 BYTE),
  DESCRIPTION                 VARCHAR2(1024 BYTE)
);


CREATE UNIQUE INDEX AUDIT_TYPE_OBJECT_CLASS_PK ON AUDIT_TYPE_OBJECT_CLASS
(AUDIT_TYPE_OBJECT_CLASS_ID);


ALTER TABLE AUDIT_TYPE_OBJECT_CLASS ADD (
  CONSTRAINT AUDIT_TYPE_OBJECT_CLASS_PK
 PRIMARY KEY
 (AUDIT_TYPE_OBJECT_CLASS_ID)
    USING INDEX);


--------

PROMPT Add the standard secured object class

INSERT INTO AUDIT_TYPE_OBJECT_CLASS VALUES(1, 'SECURABLE_OBJECT', 'Securable object');

--------

PROMPT Add a type class onto the audit log type. This can be used to do queries like - get me all entries of class blah for object_SID blah (and sub_object_id blah if needed)

ALTER TABLE CSR.AUDIT_TYPE
ADD (AUDIT_TYPE_OBJECT_CLASS_ID NUMBER(10) DEFAULT 1 NOT NULL);

ALTER TABLE CSR.AUDIT_TYPE
ADD 
FOREIGN KEY
  (AUDIT_TYPE_OBJECT_CLASS_ID)
REFERENCES
  CSR.AUDIT_TYPE_OBJECT_CLASS
  (AUDIT_TYPE_OBJECT_CLASS_ID)
ENABLE
VALIDATE;

-------

PROMPT Add an sub object identifier - this is to ID non secure objects under a secure object (i.e. a non secure product under a company)

ALTER TABLE CSR.AUDIT_LOG
ADD (SUB_OBJECT_ID NUMBER(10));

-----

PROMPT Add index on sub_object_id

CREATE INDEX IDX_AUDIT_LOG_SUB_OBJECT_ID ON AUDIT_LOG(SUB_OBJECT_ID);

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
