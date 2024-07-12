-- Please update version.sql too -- this keeps clean builds in sync
define version=2388
@update_header

ALTER TABLE csr.geo_map DROP CONSTRAINT FK_GEO_TILESET_MAP;
ALTER TABLE csr.geo_map DROP (geo_tileset_id);
DROP TABLE csr.geo_tileset;

@../geo_map_pkg
@../geo_map_body

@update_tail
