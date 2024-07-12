-- Please update version.sql too -- this keeps clean builds in sync
define version=1028
@update_header

ALTER TABLE CT.BREAKDOWN_TYPE ADD (COMPANY_SID NUMBER(10));

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT COMPANY_BRD_TYPE 
FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

UPDATE ct.breakdown_type bt 
   SET (company_sid) = (
	SELECT UNIQUE company_sid
	  FROM ct.breakdown b
	 WHERE b.app_sid = bt.app_sid
	   AND b.breakdown_type_id = bt.breakdown_type_id
   )
 WHERE bt.is_region = 0;

CREATE UNIQUE INDEX CT.IDX_BRD_TYPE_3 ON CT.BREAKDOWN_TYPE (APP_SID,CASE WHEN IS_REGION = 1  THEN -1 ELSE BREAKDOWN_TYPE_ID END);

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT CC_BRD_TYPE_COMPANY_SID 
    CHECK ((COMPANY_SID IS NULL AND IS_REGION = 1) OR (COMPANY_SID IS NOT NULL AND IS_REGION = 0));

ALTER TABLE CT.CURRENCY RENAME COLUMN SYMBOL TO ACRONYM;

ALTER TABLE CT.CURRENCY ADD (SYMBOL VARCHAR2(3));

BEGIN
	UPDATE CT.CURRENCY SET SYMBOL = '$' WHERE ACRONYM IN ('USD', 'AUD');
	UPDATE CT.CURRENCY SET SYMBOL = ''||UNISTR('\00A3')||'' WHERE ACRONYM IN ('GBP');
	UPDATE CT.CURRENCY SET SYMBOL = ''||UNISTR('\20AC')||'' WHERE ACRONYM IN ('EUR');
	UPDATE CT.CURRENCY SET SYMBOL = ''||UNISTR('\00A5')||'' WHERE ACRONYM IN ('CNY');
	UPDATE CT.CURRENCY SET SYMBOL = ''||UNISTR('\00A5')||'' WHERE ACRONYM IN ('JPY');
END;
/

ALTER TABLE CT.CURRENCY MODIFY SYMBOL NOT NULL;


@..\ct\breakdown_pkg
@..\ct\hotspot_pkg

@..\ct\breakdown_body
@..\ct\hotspot_body
@..\ct\link_body

@update_tail
