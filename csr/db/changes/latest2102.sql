-- Please update version.sql too -- this keeps clean builds in sync
define version=2102
@update_header

@..\initiative_grid_pkg
@..\initiative_pkg

@..\initiative_grid_body
@..\initiative_body

@update_tail
