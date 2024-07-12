-- Please update version.sql too -- this keeps clean builds in sync
define version=2599
@update_header

GRANT SELECT ON security.application TO csr WITH GRANT OPTION;

@update_tail
