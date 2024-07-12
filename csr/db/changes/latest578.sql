-- Please update version.sql too -- this keeps clean builds in sync
define version=578
@update_header

create global temporary table temp_pending_region (
	app_sid number(10),
	pending_region_id number(10),
	maps_to_region_sid number(10)
) on commit delete rows;

@../pending_body

@update_tail
