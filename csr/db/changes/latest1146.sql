-- Please update version.sql too -- this keeps clean builds in sync
define version=1146
@update_header

@../ct/business_travel_pkg.sql
@../ct/business_travel_body.sql

@update_tail
