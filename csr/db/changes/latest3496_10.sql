-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=10
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
    UPDATE postcode.country
       SET iso3 = LOWER(iso3);

    DELETE FROM postcode.country
     WHERE country IN ('bu','cp','cs','dd','dg','dy','fq','fx','hv','jt','nt','nh','nq','pc','pu','pz','rh','su','ta','tp','vd','wk','yd','yu','zr');

    UPDATE postcode.country
       SET name = 'Africa', iso3 = 'afr'
     WHERE country = 'ac';

    UPDATE postcode.country
       SET name = 'Anguilla', iso3 = 'aia'
     WHERE country = 'ai';

    UPDATE postcode.country
       SET name = 'Middle East', iso3 = 'mde'
     WHERE country = 'mi';

    UPDATE postcode.country
       SET name = 'Slovakia', iso3 = 'svk'
     WHERE country = 'sk';


	--non standard countries
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('aa', 'Asia', 'asi', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ab', 'Africa', 'afr', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ap', 'Asia/Pacific Region', 'apc', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ay', 'Asia Oceania', 'aso', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ea', 'Non-OECD Europe and Eurasia', 'eua', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ep', 'European Union', 'euu', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('eu', 'Europe', 'eur', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('hc', 'China (including Hong Kong)', 'chk', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('lm', 'Latin America', 'lta', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('mi', 'Middle East', 'mde', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('nm', 'North America', 'nra', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('oa', 'Other Asia', 'oas', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('of', 'Other Africa', 'oaf', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ol', 'Other Latin America', 'ola', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
