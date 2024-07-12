-- Please update version.sql too -- this keeps clean builds in sync
define version=799
@update_header


CREATE TABLE CSR.XML_REQUEST_CACHE(
    URL              VARCHAR2(4000)    NOT NULL,
    REQUEST_HASH     RAW(20)           NOT NULL,
    RESPONSE         BLOB              NOT NULL,
    FETCHED_DTM      DATE              DEFAULT SYSDATE NOT NULL,
    LAST_USED_DTM    DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_XML_REQUEST_CACHE PRIMARY KEY (URL, REQUEST_HASH)
);

@..\logistics_pkg
@..\logistics_body

@update_tail
