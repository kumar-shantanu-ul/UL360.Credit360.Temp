-- Please update version.sql too -- this keeps clean builds in sync
define version=64
@update_header


@..\create_views.sql


@update_tail