-- Please update version.sql too -- this keeps clean builds in sync
define version=723
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage Logistics', 0);

@update_tail
