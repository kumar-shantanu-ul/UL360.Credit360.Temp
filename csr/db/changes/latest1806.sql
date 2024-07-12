-- Please update version too -- this keeps clean builds in sync
define version=1806
@update_header

INSERT INTO postcode 

--FB 33229 import error
-- Kosovo appears twice - add UK

-- FB 33491 has been raised to mnge emissions factors and merge the companies

UPDATE postcode.country SET name = 'Kosovo (Republic of)' WHERE country = 'ko';

CREATE UNIQUE INDEX POSTCODE.UK_COUNTRY_NAME ON POSTCODE.COUNTRY(LOWER(TRIM(NAME)))
;



@update_tail