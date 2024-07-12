-- Please update version.sql too -- this keeps clean builds in sync
define version=2474
@update_header

-- this constraint was created with js_include at some point -- fix it where needed
ALTER TABLE CSRIMP.CHAIN_CARD DROP CONSTRAINT UC_CHAIN_CARD_JS DROP INDEX;
ALTER TABLE CSRIMP.CHAIN_CARD ADD CONSTRAINT UC_CHAIN_CARD_JS UNIQUE (CSRIMP_SESSION_ID, JS_CLASS_TYPE);

@update_tail
