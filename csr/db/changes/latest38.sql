-- Please update version.sql too -- this keeps clean builds in sync
define version=38
@update_header

ALTER TABLE SHEET_ACTION ADD (colour CHAR(1));

ALTER TABLE DELEGATION
	ADD (SCHEDULE_XML CLOB NULL);
	

-- update eidting_url to include separator
UPDATE delegation
	SET editing_url = 
		(	CASE 
	        	WHEN SUBSTR(editing_url, LENGTH(editing_url),1) IN ('&','?') THEN editing_url
	            WHEN INSTR(editing_url,'?') > 0 THEN editing_url||'&'
	            ELSE editing_url||'?'
	        END);

-- we're going to remove the schedule table	
UPDATE DELEGATION d
   SET SCHEDULE_XML = (select info_xml from schedule s where s.schedule_id = d.submission_schedule_id);

COMMIT;

ALTER TABLE DELEGATION
	DROP CONSTRAINT REFSCHEDULE148;
   
ALTER TABLE DELEGATION
	DROP COLUMN SUBMISSION_SCHEDULE_ID;
	
DROP TABLE SCHEDULE PURGE;


-- synch up with clean schema build
ALTER TABLE CSR_USER
ADD (SEND_ALERTS  NUMBER(1) DEFAULT 1
NOT NULL);

ALTER TABLE CUSTOMER
MODIFY(HOST  NOT NULL);

ALTER TABLE CUSTOMER
MODIFY(SYSTEM_MAIL_ADDRESS  NOT NULL);

ALTER TABLE CUSTOMER
MODIFY(AGGREGATE_ACTIVE  NOT NULL);

ALTER TABLE FEED DROP COLUMN SUPPORT_DETAILS;

ALTER TABLE SOURCE_TYPE
ADD (AUDIT_URL  VARCHAR2(128 BYTE));

ALTER TABLE SOURCE_TYPE DROP COLUMN ERROR_URL;

ALTER TABLE ALERT
MODIFY(CSR_ROOT_SID  NULL);

ALTER TABLE IND_WINDOW
MODIFY(COMPARISON_OFFSET  NOT NULL);

ALTER TABLE IMP_MEASURE
MODIFY(IMP_IND_ID  NOT NULL);

ALTER TABLE SOURCE_TYPE_ERROR_CODE
ADD CONSTRAINT REFSOURCE_TYPE255
FOREIGN KEY (SOURCE_TYPE_ID)
REFERENCES SOURCE_TYPE (SOURCE_TYPE_ID);

ALTER TABLE ALERT
ADD CONSTRAINT REFCUSTOMER307
FOREIGN KEY (CSR_ROOT_SID)
REFERENCES CUSTOMER (CSR_ROOT_SID);

ALTER TABLE ALERT_TEMPLATE
ADD CONSTRAINT REFCUSTOMER308
FOREIGN KEY (CSR_ROOT_SID)
REFERENCES CUSTOMER (CSR_ROOT_SID);

ALTER TABLE APP_LANGUAGE
ADD CONSTRAINT REFCUSTOMER309
FOREIGN KEY (CSR_ROOT_SID)
REFERENCES CUSTOMER (CSR_ROOT_SID);

ALTER TABLE ERROR_LOG
ADD CONSTRAINT REFCUSTOMER319
FOREIGN KEY (CSR_ROOT_SID)
REFERENCES CUSTOMER (CSR_ROOT_SID);

ALTER TABLE IND_DATA_SOURCE_TYPE
ADD CONSTRAINT REFIND279
FOREIGN KEY (IND_SID)
REFERENCES IND (IND_SID);

ALTER TABLE IND_DATA_SOURCE_TYPE
ADD CONSTRAINT REFDATA_SOURCE_TYPE278
FOREIGN KEY (DATA_SOURCE_TYPE_ID)
REFERENCES DATA_SOURCE_TYPE (DATA_SOURCE_TYPE_ID);

--ALTER TABLE VAL DROP COLUMN BASE;


-- create guids for everyone 
ALTER TABLE CSR_USER ADD (GUID CHAR(36) NULL);

DECLARE
	v_act	security_pkg.T_ACT_ID;
BEGIN
	FOR r IN (SELECT ROWID rid FROM CSR_USER)
	LOOP
    	v_act := user_pkg.GenerateACT;
		UPDATE CSR_USER SET guid = v_act WHERE ROWID = r.rid;
	END LOOP;
END;
/
commit;

ALTER TABLE CSR_USER MODIFY GUID NOT NULL;

@update_tail
