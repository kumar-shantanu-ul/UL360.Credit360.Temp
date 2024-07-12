-- Please update version.sql too -- this keeps clean builds in sync
define version=1622
@update_header

ALTER TABLE CSR.FEED_TYPE
 ADD (IS_CHAIN  NUMBER(1)                           DEFAULT 0                     NOT NULL);

 ALTER TABLE CSR.FEED_TYPE ADD CONSTRAINT CC_FEED_TYPE_IS_CHAIN
    CHECK (IS_CHAIN IN (1,0));

INSERT INTO CSR.feed_type (feed_type_id, feed_type, is_chain) VALUES (3, 'Supply Chain (push via HTTPS)', 1);
  
ALTER TABLE CSR.FEED DROP CONSTRAINT CHK_FEED_TYPE;

ALTER TABLE CSR.FEED
ADD (RESPONSE_XSL_DOC CLOB);

ALTER TABLE CSR.FEED ADD (
  CONSTRAINT CHK_FEED_TYPE
 CHECK ((URL IS NULL AND
						 PROTOCOL IS NULL AND
						 INTERVAL IS NULL AND
						 USERNAME IS NULL AND
						 HOST_KEY IS NULL AND
						 FEED_TYPE_ID IN (1,3)
						) OR (
						 URL IS NOT NULL AND
						 PROTOCOL IS NOT NULL AND
						 INTERVAL IS NOT NULL AND
						 USERNAME IS NOT NULL AND
						 HOST_KEY IS NOT NULL AND
						 FEED_TYPE_ID NOT IN (1, 3))));

ALTER TABLE CSR.ALERT_MAIL
ADD (TO_COMPANY_SID NUMBER(10));

-- added to cross schema contraints
ALTER TABLE CSR.ALERT_MAIL ADD CONSTRAINT REFALERT_MAIL_CHAIN_COMPANY 
    FOREIGN KEY (APP_SID, TO_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

@..\..\..\postcode\db\geo_region_pkg
@..\..\..\postcode\db\geo_region_body
@..\alert_pkg
@..\alert_body
@..\feed_pkg
@..\feed_body
@..\chain\purchased_component_body
						 
@update_tail
