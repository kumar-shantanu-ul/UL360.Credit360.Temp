-- Please update version.sql too -- this keeps clean builds in sync
define version=3385
define minor_version=1
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
	UPDATE csr.certification SET name = 'Milj'||UNISTR('\00F6')||'byggnad/Existing Buildings' WHERE certification_id = 113;
	UPDATE csr.certification SET name = 'Milj'||UNISTR('\00F6')||'byggnad/New Buildings' WHERE certification_id = 114;
	UPDATE csr.certification SET name = 'NF Habitat/HQE R'||UNISTR('\00E9')||'novation' WHERE certification_id = 122;
	UPDATE csr.certification SET name = 'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires en Exploitation' WHERE certification_id = 123;
	UPDATE csr.certification SET name =  'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires - Neuf ou R'||UNISTR('\00E9')||'novation' WHERE certification_id = 124;
	UPDATE csr.certification SET name =  'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Design '|| chr(38) ||' Construction' WHERE certification_id = 140;
	UPDATE csr.certification SET name =  'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Operational' WHERE certification_id = 141;
	UPDATE csr.energy_rating SET name =  'BBC Effinergie R'||UNISTR('\00E9')||'novation' WHERE energy_rating_id = 4;
	UPDATE csr.energy_rating SET name = 'DPE (Diagnostic de performance '||UNISTR('\00E9')||'nerg'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 10;
	UPDATE csr.energy_rating SET name =  'HPE (Haute Performance Energ'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 59;
	UPDATE csr.energy_rating SET name = 'THPE (Tr'||UNISTR('\00E8')||'s Haute Performance Energ'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 81;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
