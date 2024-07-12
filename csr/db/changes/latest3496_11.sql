-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=11
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
    -- corrections

    DELETE FROM postcode.country
     WHERE country IN ('ct');

    UPDATE postcode.country
       SET name = ''||UNISTR('\00C5')||'land Islands'
     WHERE country = 'ax';

    UPDATE postcode.country
       SET name = 'Saint Barth'||UNISTR('\00E9')||'lemy'
     WHERE country = 'bl';

    UPDATE postcode.country
       SET name = 'C'||UNISTR('\00F4')||'te d''Ivoire'
     WHERE country = 'ci';

    UPDATE postcode.country
       SET name = 'Cura'||UNISTR('\00E7')||'ao'
     WHERE country = 'cw';

    UPDATE postcode.country
       SET name = 'R'||UNISTR('\00E9')||'union'
     WHERE country = 're';

    UPDATE postcode.country
       SET name = 'T'||UNISTR('\00FC')||'rkiye'
     WHERE country = 'tr';

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
