-- Please update version.sql too -- this keeps clean builds in sync
define version=884
@update_header

CREATE SEQUENCE CSR.FEED_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.FEED_TYPE(
    FEED_TYPE_ID  NUMBER(2,0) NOT NULL,
    FEED_TYPE VARCHAR(512) NOT NULL,
    CONSTRAINT PK_FEED_TYPE PRIMARY KEY (FEED_TYPE_ID)
);

INSERT INTO CSR.feed_type (feed_type_id, feed_type) VALUES (csr.feed_type_id_seq.nextval, 'Default (push via HTTPS)');
INSERT INTO CSR.feed_type (feed_type_id, feed_type) VALUES (csr.feed_type_id_seq.nextval, 'Interval (processed automatically at a given interval)');

ALTER TABLE CSR.FEED ADD (
    FEED_TYPE_ID NUMBER(2,0) DEFAULT 1 NOT NULL,
    URL VARCHAR(2048),
    USERNAME VARCHAR(2048),
    PROTOCOL VARCHAR(2048),
    HOST_KEY VARCHAR(2048),
    INTERVAL NUMBER(7,4),
    LAST_GOOD_ATTEMPT_DTM DATE,
    LAST_ATTEMPT_DTM DATE,
    CONSTRAINT CHK_FEED_TYPE CHECK (
      (URL IS NULL AND FEED_TYPE_ID=1)
      OR
      (URL IS NOT NULL AND PROTOCOL IS NOT NULL AND INTERVAL IS NOT NULL AND USERNAME IS NOT NULL AND HOST_KEY IS NOT NULL AND FEED_TYPE_ID<>1)
    ),
    CONSTRAINT FK_FEED_FEED_TYPE FOREIGN KEY (FEED_TYPE_ID) REFERENCES CSR.FEED_TYPE(FEED_TYPE_ID)
);

@..\feed_pkg
@..\feed_body

@update_tail