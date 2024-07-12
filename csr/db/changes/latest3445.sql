-- Please update version.sql too -- this keeps clean builds in sync
define version=3445
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

UPDATE csr.energy_rating 
   SET name = 'BBC Effinergie R'||UNISTR('\00E9')||'novation'
 WHERE energy_rating_id = 67
   AND certification_type_id = 1
   AND external_id = 67;

UPDATE csr.energy_rating 
   SET name = 'DPE (Diagnostic de performance '||UNISTR('\00E9')||'nerg'||UNISTR('\00E9')||'tique)'
 WHERE energy_rating_id = 51
   AND certification_type_id = 1
   AND external_id = 51;

UPDATE csr.energy_rating 
   SET name = 'HPE (Haute Performance Energ'||UNISTR('\00E9')||'tique)'
 WHERE energy_rating_id = 72
   AND certification_type_id = 1
   AND external_id = 72;

UPDATE csr.energy_rating 
   SET name = 'THPE (Tr'||UNISTR('\00E8')||'s Haute Performance Energ'||UNISTR('\00E9')||'tique)'
 WHERE energy_rating_id = 76
   AND certification_type_id = 1
   AND external_id = 76;

UPDATE csr.certification_level
   SET name = '30% impovement'
 WHERE certification_id = 1184
   AND position = 0;

UPDATE csr.certification_level
   SET name = '20% impovement'
 WHERE certification_id = 1184
   AND position = 1;

UPDATE csr.certification_level
   SET name = '10% impovement'
 WHERE certification_id = 1184
   AND position = 2;

UPDATE csr.certification_level
   SET name = 'Silver'
 WHERE certification_id = 1222
   AND position = 2;

UPDATE csr.certification_level
   SET name = 'Silver'
 WHERE certification_id = 1223
   AND position = 4;

DELETE FROM csr.certification WHERE certification_id = 1217;
DELETE FROM csr.certification_level WHERE certification_id = 1220;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
