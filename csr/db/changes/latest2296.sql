-- Please update version.sql too -- this keeps clean builds in sync
define version=2296
@update_header

ALTER TABLE chain.component MODIFY component_notes VARCHAR2(4000);

@update_tail