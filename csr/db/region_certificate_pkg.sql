CREATE OR REPLACE PACKAGE csr.region_certificate_pkg AS

PROCEDURE SaveCertification (
	in_certification_id				IN	certification.certification_id%TYPE,
	in_name							IN	certification.name%TYPE,
	in_external_id					IN	certification.external_id%TYPE,
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE
);

PROCEDURE SaveCertificationLevel (
	in_certification_id				IN	certification.certification_id%TYPE,
	in_name							IN	certification.name%TYPE,
	in_pos							IN	certification.external_id%TYPE
);

PROCEDURE SaveEnergyRating (
	in_energy_rating_id				IN	energy_rating.energy_rating_id%TYPE,
	in_name							IN	energy_rating.name%TYPE,
	in_external_id					IN	energy_rating.external_id%TYPE,
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE
);

-- certs
PROCEDURE GetCertificatesByTypeLookup(
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificatesByTypeId(
	in_type_id						IN	certification_type.certification_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificatesByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDeletedCertificatesByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificatesForRegionSid(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDeletedCertificatesForRegionSid(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificateLevels(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificateLevelsByCertificationId(
	in_certification_id						IN	certification_level.certification_id%TYPE,
	out_cur									OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddCertificateForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
);

PROCEDURE UpdateCertificateForRegion(
	in_region_certificate_id		IN	region_certificate.region_certificate_id%TYPE,
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
);

PROCEDURE AdminUpsertCertificateForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
);

PROCEDURE SetExternalCertificateId(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_external_certification_id	IN  certification.external_id%TYPE,
	in_certification_level_name		IN  certification_level.name%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_external_certificate_id		IN  region_certificate.external_certificate_id%TYPE
);

PROCEDURE DeleteCertificateForRegion(
	in_region_certificate_id		IN	region_certificate.region_certificate_id%TYPE
);

PROCEDURE AdminDeleteCertificatesForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_region_certificate_id		IN  region_certificate.region_certificate_id%TYPE
);

PROCEDURE AdminCleanupDeletedCertificatesForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE
);

-- energy ratings 
PROCEDURE GetEnergyRatingsByTypeLookup(
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEnergyRatingsByTypeId(
	in_type_id						IN	certification_type.certification_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEnergyRatingsForRegionSid(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEnergyRatingsByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
);

PROCEDURE UpdateEnergyRatingForRegion(
	in_region_energy_rating_id		IN	region_energy_rating.region_energy_rating_id%TYPE,
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
);

PROCEDURE DeleteEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_region_energy_rating_id		IN  region_energy_rating.region_energy_rating_id%TYPE
);

PROCEDURE AdminUpsertEnergyRatingForRegion(
	in_region_energy_rating_id		IN	region_energy_rating.region_energy_rating_id%TYPE,
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
);

PROCEDURE AdminDeleteEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_region_energy_rating_id		IN  region_energy_rating.region_energy_rating_id%TYPE
);

END;
/
