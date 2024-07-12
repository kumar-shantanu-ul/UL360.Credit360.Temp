-- Please update version.sql too -- this keeps clean builds in sync
define version=7
@update_header

alter table delegation drop column regions_are_children;

@../imp_body.sql

@update_tail
