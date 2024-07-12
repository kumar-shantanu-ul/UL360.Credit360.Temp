-- Please update version.sql too -- this keeps clean builds in sync
define version=2618
@update_header

DROP INDEX CHAIN.UK_COMP_PARENT_NAME;
CREATE UNIQUE INDEX CHAIN.UK_COMP_PARENT_NAME ON CHAIN.COMPANY (NVL(PARENT_SID, COMPANY_SID), DECODE(DELETED, 0, LOWER(NAME), COMPANY_SID));

@../chain/plugin_pkg
@../chain/plugin_body

@../chain/type_capability_body
@../chain/business_relationship_body

@update_tail
