-- Please update version.sql too -- this keeps clean builds in sync
define version=1779
@update_header

ALTER TABLE chain.card_group_card ADD INIT_PARAM VARCHAR2(1000) DEFAULT NULL;

@../chain/card_pkg
@../chain/card_body

@update_tail