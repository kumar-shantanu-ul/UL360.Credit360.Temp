-- Please update version.sql too -- this keeps clean builds in sync
define version=199
@update_header

create index ix_pending_reg_parent_reg on pending_region(parent_region_id);
create index ix_pend_val_pend_reg on pending_val(pending_region_id);
create index ix_pend_ind_map_ind  on pending_ind(maps_to_ind_sid);

@update_tail

