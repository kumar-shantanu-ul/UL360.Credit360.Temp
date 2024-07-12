-- Please update version.sql too -- this keeps clean builds in sync
define version=937
@update_header

INSERT INTO csr.source_type 
	(source_type_id, description)
  VALUES (13, 'Energy Star');

@../csr_data_pkg
@../energy_star_pkg

@../energy_star_customer_body
@../energy_star_body

@update_tail