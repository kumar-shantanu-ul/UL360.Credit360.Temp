-- Please update version.sql too -- this keeps clean builds in sync
define version=838
@update_header

GRANT SELECT ON cms.display_template TO csr;

@update_tail
