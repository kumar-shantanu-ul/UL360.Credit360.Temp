-- Please update version.sql too -- this keeps clean builds in sync
define version=2573
@update_header

--compile modified package
@../val_datasource_pkg
@../val_datasource_body

@update_tail
