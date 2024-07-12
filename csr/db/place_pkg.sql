CREATE OR REPLACE PACKAGE CSR.Place_Pkg
IS

PROCEDURE GetPlaces(
	out_cur OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePlace(
	in_place_id			IN csr.place.place_id%TYPE,
	in_street_addr1		IN csr.place.street_addr1%TYPE,
	in_street_addr2		IN csr.place.street_addr2%TYPE,
	in_town				IN csr.place.town%TYPE,
	in_state			IN csr.place.state%TYPE,
	in_postcode			IN csr.place.postcode%TYPE,
	in_country_code		IN csr.place.country_code%TYPE,
	in_lat				IN csr.place.lat%TYPE,
	in_lng				IN csr.place.lng%TYPE,
	out_place_id		OUT csr.place.place_id%TYPE
);

PROCEDURE DeletePlace(
	in_place_id	IN csr.place.place_id%TYPE
);

PROCEDURE GetPlace(
	in_place_id	IN csr.place.place_id%TYPE,
	out_cur OUT security_pkg.T_OUTPUT_CUR
);

END Place_Pkg;
/