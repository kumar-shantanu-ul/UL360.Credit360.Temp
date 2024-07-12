-- Please update version.sql too -- this keeps clean builds in sync
define version=803
@update_header

ALTER TABLE CSR.AXIS ADD AXIS_MEMBER_POPUP VARCHAR2(255) DEFAULT '/csr/site/strategy/explorer/GetPopup.aspx' NOT NULL;

@..\strategy_pkg
@..\strategy_body

@update_tail
