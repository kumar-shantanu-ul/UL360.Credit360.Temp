-- Please update version.sql too -- this keeps clean builds in sync
define version=2389
@update_header

DROP TABLE csr.geo_map_region_description;

@../geo_map_pkg
@../geo_map_body

@update_tail
