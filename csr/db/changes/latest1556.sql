-- Please update version.sql too -- this keeps clean builds in sync
define version=1556
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage text question carts', 0);

@..\section_body

@update_tail