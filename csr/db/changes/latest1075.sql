-- Please update version.sql too -- this keeps clean builds in sync
define version=1075	
@update_header

-- 
-- INDEX: CHAIN.IDX_LOWER_JS_CLASS_TYPE 
--

CREATE INDEX CHAIN.IDX_LOWER_JS_CLASS_TYPE ON CHAIN.CARD(LOWER(JS_CLASS_TYPE))
;

@..\chain\card_body

@update_tail
