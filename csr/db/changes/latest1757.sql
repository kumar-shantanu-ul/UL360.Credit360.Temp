-- Please update version.sql too -- this keeps clean builds in sync
define version=1757
@update_header

INSERT INTO postcode.country (country, name, latitude, longitude, area_in_sqkm, continent, currency, ISO3)
VALUES ('ss', 'South Sudan', 4.85, 31.6, 619745, 'AF', 'SSP', 'sdn');
	
@update_tail