define version=53
@update_header

CREATE OR REPLACE VIEW v$country AS
	SELECT country country_code, name
	  FROM postcode.country
	 WHERE latitude IS NOT NULL AND longitude IS NOT NULL
;   

@update_tail

