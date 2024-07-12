-- Please update version.sql too -- this keeps clean builds in sync
define version=128
@update_header

VARIABLE version NUMBER
BEGIN :version := 128; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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
	
	SELECT db_version INTO v_version FROM security.version;
	IF v_version < 10 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A *** SECURITY *** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/
-- 
-- TABLE: CUSTOMER_ALERT_TYPE 
--

CREATE TABLE CUSTOMER_ALERT_TYPE(
    CSR_ROOT_SID     NUMBER(10, 0)    NOT NULL,
    ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK356 PRIMARY KEY (CSR_ROOT_SID, ALERT_TYPE_ID)
)
;

insert into customer_alert_type (csr_root_sid, alert_type_id)
	select c.csr_root_sid, a.alert_type_id
	  from alert_type a, customer c;

-- 
-- TABLE: ALERT_TEMPLATE 
--

ALTER TABLE ALERT_TEMPLATE ADD CONSTRAINT RefCUSTOMER_ALERT_TYPE645 
    FOREIGN KEY (CSR_ROOT_SID, ALERT_TYPE_ID)
    REFERENCES CUSTOMER_ALERT_TYPE(CSR_ROOT_SID, ALERT_TYPE_ID)
;


-- 
-- TABLE: CUSTOMER_ALERT_TYPE 
--

ALTER TABLE CUSTOMER_ALERT_TYPE ADD CONSTRAINT RefALERT_TYPE647 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES ALERT_TYPE(ALERT_TYPE_ID)
;

ALTER TABLE CUSTOMER_ALERT_TYPE ADD CONSTRAINT RefCUSTOMER648 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;





UPDATE version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
 

@update_tail
