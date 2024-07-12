-- Please update version.sql too -- this keeps clean builds in sync
define version=1600
@update_header

ALTER TABLE CSRIMP.SECTION_ROUTED_FLOW_STATE ADD REJECT_FS_TRANSITION_ID    	NUMBER(10, 0);

@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail