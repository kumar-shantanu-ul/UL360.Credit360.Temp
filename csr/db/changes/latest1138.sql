-- Please update version.sql too -- this keeps clean builds in sync
define version=1138
@update_header

GRANT SELECT, DELETE ON cms.flow_tab_column_cons TO csr;
GRANT SELECT, UPDATE ON cms.tab TO csr;

@../flow_body

@update_tail
