-- Please update version.sql too -- this keeps clean builds in sync
define version=3166
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO csr.location (location_id, location_type_id, name, description, longitude, latitude, country, is_approved) VALUES (csr.location_id_seq.nextval, 1, 'JJG', 'SBJA - Humberto Ghizzo Bortoluzzi Regional Airport', -49.0596, -28.6753, 'br', 1);
	INSERT INTO csr.location (location_id, location_type_id, name, description, longitude, latitude, country, is_approved) VALUES (csr.location_id_seq.nextval, 1, 'TXF', 'SNTF - Teixeira de Freitas Airport, Teixeira de Freitas BA, Brazil', -39.66984, -17.523048, 'br', 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
