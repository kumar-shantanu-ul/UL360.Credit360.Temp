-- Please update version.sql too -- this keeps clean builds in sync
define version=2193
@update_header

BEGIN
	INSERT INTO csr.capability (name, allow_by_default)
		VALUES ('Remap Energy Star property', 0);
END;
/

@../energy_star_body
@../property_body

@update_tail
