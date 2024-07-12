-- Please update version.sql too -- this keeps clean builds in sync
define version=432
@update_header

alter table csr.model_map rename column region_offset to region_type_offset;
alter table csr.model_map modify (region_type_offset null);
alter table csr.model_map modify (region_type_offset default(null));
update csr.model_map set region_type_offset = null;

@../model_pkg
@../model_body

@update_tail
