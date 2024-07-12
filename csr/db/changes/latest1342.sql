-- Please update version.sql too -- this keeps clean builds in sync
define version=1342
@update_header

alter table csrimp.flow_state_transition modify button_icon_path null;

@update_tail
