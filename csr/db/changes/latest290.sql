-- Please update version.sql too -- this keeps clean builds in sync
define version=290
@update_header

set define off;

CREATE INDEX 	idx_pend_val_step ON pending_val (
	app_sid, approval_step_id,	pending_ind_id,	pending_region_id, pending_period_id
) TABLESPACE INDX;

@..\pending_pkg
@..\pending_body

@update_tail
