CREATE OR REPLACE PACKAGE BODY CSR.Place_Pkg
IS

PROCEDURE GetPlaces(
	out_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
				place_id,
				street_addr1,
				street_addr2,
				town,
				state,
				postcode,
				country_code,
				lat,
				lng
			FROM place
			WHERE app_sid = security_pkg.GetApp;
END;

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
)
AS
BEGIN
	IF in_place_id > 0 THEN
		BEGIN
			UPDATE place 
				SET street_addr1 = in_street_addr1,
					street_addr2 = in_street_addr2,
					town = in_town,
					state = in_state,
					postcode = in_postcode,
					country_code = in_country_code,
					lat = in_lat,
					lng = in_lng
				WHERE place_id = in_place_id 
				  AND app_sid = security_pkg.GETAPP;
				
			out_place_id := in_place_id;
		END;
	ELSE
		BEGIN
			INSERT INTO place (app_sid, place_id, street_addr1, street_addr2, town, state, postcode, country_code, lat, lng)
				VALUES (security_pkg.GetApp, place_id_seq.NEXTVAL, in_street_addr1, in_street_addr2, in_town, in_state, in_postcode, in_country_code, in_lat, in_lng)
			RETURNING place_id INTO out_place_id;
		END;
	END IF;
	
END;

PROCEDURE DeletePlace(
	in_place_id	IN csr.place.place_id%TYPE
)
AS
BEGIN
	DELETE FROM place
		WHERE app_sid = security_pkg.GetApp
		  AND place_id = in_place_id;
END;

PROCEDURE GetPlace(
	in_place_id	IN csr.place.place_id%TYPE,
	out_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
				place_id,
				street_addr1,
				street_addr2,
				town,
				state,
				postcode,
				country_code,
				lat,
				lng
			FROM place
			WHERE app_sid = security_pkg.GetApp
			  AND place_id = in_place_id;
END;

END;
/