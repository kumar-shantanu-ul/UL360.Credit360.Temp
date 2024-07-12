-- Please update version.sql too -- this keeps clean builds in sync
define version=1088
@update_header

DROP INDEX CHAIN.IDX_LOWER_JS_CLASS_TYPE;

CREATE UNIQUE INDEX CHAIN.IDX_LOWER_JS_CLASS_TYPE ON CHAIN.CARD(LOWER(JS_CLASS_TYPE));

@update_tail
