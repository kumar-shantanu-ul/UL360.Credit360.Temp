-- Please update version.sql too -- this keeps clean builds in sync
define version=111
@update_header

VARIABLE version NUMBER
BEGIN :version := 111; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

CREATE GLOBAL TEMPORARY TABLE TEMP_LOGGING_VAL
(
  IND_SID           NUMBER(10)                  NOT NULL,
  REGION_SID        NUMBER(10)                  NOT NULL,
  PERIOD_START_DTM  DATE                        NOT NULL,
  PERIOD_END_DTM    DATE                        NOT NULL
)
ON COMMIT DELETE ROWS
NOCACHE;

INSERT INTO CSR.SOURCE_TYPE_ERROR_CODE (
   SOURCE_TYPE_ID, ERROR_CODE, LABEL, 
   DETAIL_URL) 
VALUES (3 , 1, 'Logging aggregation failure', NULL);
     
UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
