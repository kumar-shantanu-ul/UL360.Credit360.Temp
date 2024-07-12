-- Please update version.sql too -- this keeps clean builds in sync
define version=786
@update_header

update csr.location set latitude = null, longitude = null where
        (-90 > latitude OR latitude > 90)
        OR
        (-180 > longitude OR longitude > 180);

ALTER TABLE csr.location
	ADD CONSTRAINT LATLNG CHECK ((latitude IS NULL or (-90 <= latitude AND latitude <= 90))
		AND
		(longitude IS NULL or (-180 <= longitude AND longitude <= 180)));

@update_tail
