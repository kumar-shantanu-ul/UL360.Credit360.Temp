-- Please update version.sql too -- this keeps clean builds in sync
define version=2642
@update_header

@..\chain\chain_link_pkg
@..\chain\chain_link_body
@..\chain\questionnaire_body

@update_tail
