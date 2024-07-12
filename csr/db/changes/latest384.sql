-- Please update version.sql too -- this keeps clean builds in sync
define version=384
@update_header

alter table issue_scheduled_task drop primary key drop index;
alter table issue_scheduled_task add constraint pk_issue_scheduled_task primary key (app_sid, issue_scheduled_task_id)
using index tablespace indx;

@..\rls

@update_tail
