-- Please update version.sql too -- this keeps clean builds in sync
define version=492
@update_header

alter table ind add (do_temporal_aggregation number(1) default 0 not null);
alter table ind add constraint ck_ind_do_temporal_aggregation check (do_temporal_aggregation in (0,1));

@..\calc_pkg
@..\calc_body
@..\dataview_body
@..\datasource_body
@..\range_body
@..\pending_datasource_body
@..\schema_body
@..\delegation_body
@..\indicator_body
@..\pending_body

@update_tail
