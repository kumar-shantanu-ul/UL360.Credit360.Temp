-- Please update version.sql too -- this keeps clean builds in sync
define version=2120
@update_header

GRANT INSERT, UPDATE ON actions.customer_options TO csr;
GRANT INSERT, UPDATE ON actions.ind_template TO csr;
GRANT SELECT ON actions.ind_template_id_seq TO csr;
COMMIT;

@update_tail
