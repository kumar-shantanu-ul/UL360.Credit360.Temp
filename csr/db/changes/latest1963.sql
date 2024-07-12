-- Please update version.sql too -- this keeps clean builds in sync
define version=1963
@update_header

--todo: add to manual_schema_changes
--use COUNTRIES_HELPER_SP to override how chain companies are populated
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD COUNTRIES_HELPER_SP VARCHAR2(100);

@../chain/flow_form_pkg

@../chain/helper_body
@../chain/flow_form_body
	
@update_tail