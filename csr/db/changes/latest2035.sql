-- Please update version.sql too -- this keeps clean builds in sync
define version=2035
@update_header

-- Plugins and plugin types are shared across sites; they don't need csrimp equivalents.
DROP TABLE csrimp.plugin;
DROP TABLE csrimp.map_plugin;

@@../schema_pkg
@@../schema_body

@@../csrimp/imp_pkg
@@../csrimp/imp_body

@update_tail
