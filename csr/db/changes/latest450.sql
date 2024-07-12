-- Please update version.sql too -- this keeps clean builds in sync
define version=450
@update_header

ALTER TABLE RSS_CACHE ADD (
    LAST_ERROR      VARCHAR2(2040),
    ERROR_COUNT     NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

@update_tail
