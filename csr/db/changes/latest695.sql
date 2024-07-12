-- Please update version.sql too -- this keeps clean builds in sync
define version=695
@update_header

INSERT INTO csr.location_type (location_type_id, name)
	VALUES (4, 'Land');

INSERT INTO csr.transport (transport_id, name)
	VALUES (3, 'Road');

@update_tail
