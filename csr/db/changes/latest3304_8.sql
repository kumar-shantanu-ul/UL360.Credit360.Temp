-- Please update version.sql too -- this keeps clean builds in sync
define version=3304
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP TABLE csr.enhesa_account;

ALTER TABLE csr.enhesa_options ADD (
	username	VARCHAR2(1024),
	password	VARCHAR2(1024)
);

ALTER TABLE csrimp.enhesa_options ADD (
	username	VARCHAR2(1024),
	password	VARCHAR2(1024)
);
  
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.enhesa_options SET username = 'ulehss', password = 'PwWn4Mx7kj1HmyIJQhAcYv3ONQWEhSjhZM4erjf1hKXKm8uks08pW2hC2uVVplYh' WHERE client_id = '632';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Ingrammicro', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '784';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Biogen', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '712';
UPDATE csr.enhesa_options SET username = 'UL.Integration.Centrica', password = 'ujXU9pDN7sfCjw3ieCTBBss2qtr0tcPiUxX7TmS36SK4MJ97iXlS133cYZwRsSwG' WHERE client_id = '674';

INSERT INTO csr.module_param (module_id, param_name, pos)
VALUES (80, 'ENHESA Username', 1);
INSERT INTO csr.module_param (module_id, param_name, pos)
VALUES (80, 'ENHESA Password', 2);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../enable_pkg

@../compliance_body
@../enable_body
@../schema_body
@../csrimp/imp_body

@update_tail
