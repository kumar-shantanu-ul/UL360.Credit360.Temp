-- Please update version.sql too -- this keeps clean builds in sync
define version=172
@update_header
		 
create index ix_app_region on region(app_sid, region_sid) tablespace indx;
create index ix_app_region_parent on region(app_sid, parent_sid) tablespace indx;

@update_tail
