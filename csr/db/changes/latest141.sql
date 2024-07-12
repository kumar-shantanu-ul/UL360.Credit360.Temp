-- Please update version.sql too -- this keeps clean builds in sync
define version=141
@update_header

alter table SEARCH_TAG cache;
alter table TEMP_LOGGING_VAL cache;

@update_tail
