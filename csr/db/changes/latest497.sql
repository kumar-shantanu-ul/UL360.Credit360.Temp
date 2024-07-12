-- Please update version.sql too -- this keeps clean builds in sync
define version=497
@update_header

RENAME factor_type_map_id_seq TO factor_type_id_seq;

@update_tail
