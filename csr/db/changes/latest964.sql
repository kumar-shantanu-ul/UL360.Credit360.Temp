-- Please update version.sql too -- this keeps clean builds in sync
define version=964
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit personal details', 1);

COMMIT;
@update_tail