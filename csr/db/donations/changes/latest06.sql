
CREATE TABLE CURRENCY(
    CURRENCY_CODE    VARCHAR2(4)     NOT NULL,
    SYMBOL           VARCHAR2(4),
    LABEL            VARCHAR2(64)    NOT NULL,
    CONSTRAINT PK51 PRIMARY KEY (CURRENCY_CODE)
);

CREATE TABLE REGION_GROUP_RECIPIENT(
    REGION_GROUP_SID    NUMBER(10, 0)    NOT NULL,
    RECIPIENT_SID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK53 PRIMARY KEY (REGION_GROUP_SID, RECIPIENT_SID)
);



-----------------------------------------------------------------------------
-- The region_grouo currency_code can not be null, default everythng to 'GBP'
-----------------------------------------------------------------------------

ALTER TABLE REGION_GROUP ADD (
	CURRENCY_CODE		VARCHAR2(4)		NULL
);

UPDATE region_group
   SET currency_code = 'GBP';
   
ALTER TABLE REGION_GROUP MODIFY (
	CURRENCY_CODE		VARCHAR2(4)		NOT NULL
);

INSERT INTO currency
	(currency_code, symbol, label)
  VALUES ('GBP', '£', 'British Pound');

-----------------------------------------------------------------------------



ALTER TABLE REGION_GROUP ADD CONSTRAINT RefCURRENCY74 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES CURRENCY(CURRENCY_CODE)
;

ALTER TABLE REGION_GROUP_RECIPIENT ADD CONSTRAINT RefRECIPIENT77 
    FOREIGN KEY (RECIPIENT_SID)
    REFERENCES RECIPIENT(RECIPIENT_SID)
;

ALTER TABLE REGION_GROUP_RECIPIENT ADD CONSTRAINT RefREGION_GROUP78 
    FOREIGN KEY (REGION_GROUP_SID)
    REFERENCES REGION_GROUP(REGION_GROUP_SID)
;

COMMIT;



-----------------------------------------------------------------------------
-- Script to populate the region_group_recipient mapping from existing data
-----------------------------------------------------------------------------

DECLARE
BEGIN
    FOR r in (SELECT recipient_sid FROM recipient)
    LOOP
    	INSERT INTO region_group_recipient
    			(region_group_sid, recipient_sid)
			SELECT DISTINCT region_group_sid, r.recipient_sid
			  FROM region_group where region_group_sid IN (
				SELECT region_group_sid FROM budget WHERE budget_id IN ( 
			    	SELECT budget_id FROM donation WHERE recipient_sid = r.recipient_sid));
    END LOOP;    
END;
/

COMMIT;
