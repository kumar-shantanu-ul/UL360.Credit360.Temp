-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.dataview_zone rename column dataview_zone_id to pos;
alter table csr.dataview_zone drop primary key drop index;
alter table csr.dataview_zone add constraint pk_dataview_zone primary key (app_sid, dataview_sid, pos);
drop sequence csr.dataview_zone_id_seq;

alter table csrimp.dataview_zone rename column dataview_zone_id to pos;
alter table csrimp.dataview_zone drop primary key drop index;
alter table csrimp.dataview_zone add constraint pk_dataview_zone primary key (csrimp_session_id, dataview_sid, pos);
drop table csrimp.map_dataview_zone;

alter table csr.dataview_trend rename column dataview_trend_id to pos;
alter table csr.dataview_trend drop primary key drop index;
alter table csr.dataview_trend add constraint pk_dataview_trend primary key (app_sid, dataview_sid, pos);
drop sequence csr.dataview_trend_id_seq;

alter table csrimp.dataview_trend rename column dataview_trend_id to pos;
alter table csrimp.dataview_trend drop primary key drop index;
alter table csrimp.dataview_trend add constraint pk_dataview_trend primary key (csrimp_session_id, dataview_sid, pos);

alter table csr.dataview drop column use_pending;
alter table csrimp.dataview drop column use_pending;
alter table csr.dataview_history drop column use_pending;
alter table csrimp.dataview_history drop column use_pending;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_body
@../dataview_pkg
@../dataview_body
@../snapshot_body
@../csrimp/imp_body

@update_tail
