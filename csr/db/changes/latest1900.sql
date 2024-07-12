-- Please update version.sql too -- this keeps clean builds in sync
define version=1900
@update_header

DROP TYPE csr.stragg3_type;
DROP FUNCTION csr.stragg3;
DROP PROCEDURE csr.stragg3setSeparator;

@..\str_functions
@..\region_body

@update_tail