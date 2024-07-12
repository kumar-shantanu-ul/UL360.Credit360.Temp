-- Please update version.sql too -- this keeps clean builds in sync
define version=1699
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

BEGIN

-- Already have 'European Union'
DELETE FROM postcode.country WHERE country='en' AND name='European Union - 27';

-- New countries for new Emission Factors
INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3)
VALUES ('ay','Asia Oceania',0,0,0,'AS',null,'aso');
INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, iso3)
VALUES ('ko','Kosovo',42.4,21.1,10908,'EU','EUR','kos');

COMMIT;
END;
/

@update_tail