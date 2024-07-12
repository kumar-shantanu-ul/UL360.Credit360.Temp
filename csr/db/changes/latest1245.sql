-- Please update version.sql too -- this keeps clean builds in sync
define version=1245
@update_header

@../measure_body
@../energy_star_body

@update_tail
