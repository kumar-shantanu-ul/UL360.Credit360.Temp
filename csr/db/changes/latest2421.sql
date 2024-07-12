-- Please update version.sql too -- this keeps clean builds in sync
define version=2421
@update_header

ALTER TABLE postcode.airport MODIFY pos NULL;


-- New airports for postcode.
INSERT INTO POSTCODE.AIRPORT (CODE, NAME, CITY, LONGITUDE, LATITUDE, COUNTRY)
VALUES('MEU','Monte Dourado','Almeirim',-52.60225,-0.889839,'br');

-- Update incorrect data for airport.
UPDATE postcode.airport
SET latitude = -11.432666,
longitude = -61.47718,
name = 'Capital do Cafe',
city = 'Cacoal',
country = 'br'
WHERE code = 'OAL';


UPDATE postcode.airport
   SET pos = mdsys.sdo_geometry(
				2001,
				8307,
				sdo_point_type(longitude,latitude,null),null,null)
 WHERE pos IS NULL;

@update_tail