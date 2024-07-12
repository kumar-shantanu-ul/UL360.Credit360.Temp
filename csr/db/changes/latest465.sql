-- Please update version.sql too -- this keeps clean builds in sync
define version=465
@update_header

ALTER TABLE customer_MAP ADD config_path varchar (1024) default '/fp/shared/map/OpenStreetMap.js';

@../map_body

@update_tail
