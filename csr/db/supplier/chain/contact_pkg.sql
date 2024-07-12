CREATE OR REPLACE PACKAGE SUPPLIER.contact_pkg
IS

SUBTYPE T_CONTACT_STATE	IS 			CONTACT.CONTACT_STATE_ID%TYPE;
CONTACT_NORMAL						CONSTANT T_CONTACT_STATE := 0;
CONTACT_REMOVED_BY_SUPPLIER			CONSTANT T_CONTACT_STATE := 1;
CONTACT_REMOVED_BY_REJECTION		CONSTANT T_CONTACT_STATE := 2;
CONTACT_REGISTERED					CONSTANT T_CONTACT_STATE := 3;

PROCEDURE AddContact(
	in_existing_company_sid	IN  contact.existing_company_sid%TYPE,
	in_existing_user_sid	IN  contact.existing_user_sid%TYPE,
	in_full_name	 		IN	contact.full_name%TYPE,
	in_email 				IN	contact.email%TYPE,	
	in_job_title 	 		IN	contact.job_title%TYPE,	
	in_phone		 		IN	contact.phone_number%TYPE,	
	in_company_name 		IN  contact.company_name%TYPE,
	in_address_1			IN  contact.address_1%TYPE,
	in_address_2			IN  contact.address_2%TYPE,
	in_address_3			IN  contact.address_3%TYPE,
	in_address_4			IN  contact.address_4%TYPE,
	in_town					IN  contact.town%TYPE,
	in_state				IN  contact.state%TYPE,
	in_postcode				IN  contact.postcode%TYPE,
	in_country_code			IN  contact.country_code%TYPE,
	in_est_spend	 		IN  contact.estimated_annual_spend%TYPE,	
	in_currency_code 		IN  contact.currency_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetContact(
	in_contact_id			IN  contact.contact_id%TYPE, 
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

END contact_pkg;
/

