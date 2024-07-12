-- Please update version.sql too -- this keeps clean builds in sync
define version=1663
@update_header

INSERT INTO CSR.feed_type (feed_type_id, feed_type, is_chain) VALUES (4, 'Logging Forms (push via HTTPS)', 0);
  
ALTER TABLE CSR.FEED DROP CONSTRAINT CHK_FEED_TYPE;

ALTER TABLE CSR.FEED ADD (
  CONSTRAINT CHK_FEED_TYPE
 CHECK ((URL IS NULL AND
						 PROTOCOL IS NULL AND
						 INTERVAL IS NULL AND
						 USERNAME IS NULL AND
						 HOST_KEY IS NULL AND
						 FEED_TYPE_ID IN (1,3,4)
						) OR (
						 URL IS NOT NULL AND
						 PROTOCOL IS NOT NULL AND
						 INTERVAL IS NOT NULL AND
						 USERNAME IS NOT NULL AND
						 HOST_KEY IS NOT NULL AND
						 FEED_TYPE_ID NOT IN (1,3,4))));

@update_tail
