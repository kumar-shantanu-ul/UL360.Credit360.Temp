-- Please update version.sql too -- this keeps clean builds in sync
define version=453
@update_header

create index ix_dv_ind_mem_dv_ind on dataview_ind_member (app_sid,dataview_sid,ind_sid) tablespace indx;
create index ix_dv_ind_mem_ind on dataview_ind_member (app_sid,ind_sid) tablespace indx;
create index ix_dv_reg_mem_dv_reg on dataview_region_member (app_sid,dataview_sid,region_sid) tablespace indx;
create index ix_dv_reg_mem_reg on dataview_region_member (app_sid,region_sid) tablespace indx;

@update_tail
