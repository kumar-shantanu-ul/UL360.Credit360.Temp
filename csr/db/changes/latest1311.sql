-- Please update version.sql too -- this keeps clean builds in sync
define version=1311
@update_header

CREATE TABLE csr.xxx_feed_interval (
	feed_sid			number(10),
	interval			number(7, 2)
);

INSERT INTO csr.xxx_feed_interval (feed_sid, interval)
	SELECT feed_sid, interval
	  FROM csr.feed
	 WHERE interval is not null;
	 
COMMIT;
	 
ALTER TABLE csr.feed DROP CONSTRAINT CHK_FEED_TYPE;
ALTER TABLE csr.feed DROP COLUMN INTERVAL;

ALTER TABLE csr.feed ADD (
	INTERVAL		VARCHAR2(2),
	INTERVAL_OFFSET	NUMBER(10, 0) DEFAULT 0 NOT NULL
);

UPDATE csr.feed
   SET interval = 'q'
 WHERE feed_type_id = 2;
 
ALTER TABLE csr.feed ADD CONSTRAINT
	CHK_FEED_TYPE CHECK	((URL IS NULL AND 
						 PROTOCOL IS NULL AND 
						 INTERVAL IS NULL AND 
						 USERNAME IS NULL AND 
						 HOST_KEY IS NULL AND 
						 FEED_TYPE_ID = 1
						) OR (
						 URL IS NOT NULL AND 
						 PROTOCOL IS NOT NULL AND 
						 INTERVAL IS NOT NULL AND 
						 USERNAME IS NOT NULL AND 
						 HOST_KEY IS NOT NULL AND 
						 FEED_TYPE_ID != 1)) ENABLE;

@..\feed_body

@update_tail
