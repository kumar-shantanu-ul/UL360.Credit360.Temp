CREATE OR REPLACE PACKAGE BODY SUPPLIER.contact_pkg
IS

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
	in_postcode			IN  contact.postcode%TYPE,
	in_country_code			IN  contact.country_code%TYPE,
	in_est_spend	 		IN  contact.estimated_annual_spend%TYPE,	
	in_currency_code 		IN  contact.currency_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_contact_id			contact.contact_id%TYPE;
	v_full_name	 			contact.full_name%TYPE DEFAULT '-'; -- These columns are not nullable, but if in_existing_user_sid is provided, we don't use these 
	v_email 				contact.email%TYPE DEFAULT '-'; 	-- values anyways. If it is NOT provided, these defaults will get overriden below
	v_job_title 	 		contact.job_title%TYPE;
	v_phone		 			contact.phone_number%TYPE;
	v_company_name 			contact.company_name%TYPE;
	v_address_1				contact.address_1%TYPE;
	v_address_2				contact.address_2%TYPE;
	v_address_3				contact.address_3%TYPE;
	v_address_4				contact.address_4%TYPE;
	v_town					contact.town%TYPE;
	v_state					contact.state%TYPE;
	v_postcode				contact.postcode%TYPE;
	v_country_code			contact.country_code%TYPE;
	v_est_spend	 			contact.estimated_annual_spend%TYPE;
	v_currency_code 		contact.currency_code%TYPE;
BEGIN

	/*	We don't care if a user gets invited more than once as this 
		will get cleared up once they respond to the invitation request 
		email and say that they already have an account.					*/

	-- verify we can at least read the company that's set in the context
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||company_pkg.GetCompany||'.');
	END IF;

	-- verify that the current user is an authorized user of the company
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, company_pkg.GetCompany) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user for '||company_pkg.GetCompany||'.');
	END IF;
	
	-- If an existing user sid is NOT provided, we'll use the values passed in.
	-- If an existing user sid IS provided, we'll assume (and require by fk constraint) 
	-- 	that an existing company sid has also been provided.
	IF in_existing_user_sid IS NULL THEN
		v_full_name	:= in_full_name;
		v_email := LOWER(TRIM(in_email));
		v_job_title := in_job_title;
		v_phone := in_phone;
		
		-- if an existing company sid is NOT provided, we'll use the values passed in
		IF in_existing_company_sid IS NULL THEN
			v_company_name := in_company_name;
			v_address_1	:= in_address_1;
			v_address_2	:= in_address_2;
			v_address_3	:= in_address_3;
			v_address_4	:= in_address_4;
			v_town := in_town;
			v_state := in_state;
			v_postcode	:= in_postcode;
			v_country_code := in_country_code;
			v_est_spend	:= in_est_spend;
			v_currency_code := in_currency_code;
		END IF;	
	END IF;

	-- insert the core contact data
	INSERT INTO contact (
	    contact_id, owner_company_sid, contact_guid, 
	    full_name, email, job_title, phone_number, 
	    company_name, address_1, address_2, 
		address_3, address_4, town, state, postcode, 
		country_code, estimated_annual_spend, currency_code,
		existing_company_sid, existing_user_sid 
	) VALUES (
	    contact_id_seq.NEXTVAL, company_pkg.GetCompany, security.user_pkg.GenerateACT, 
	    v_full_name, v_email, v_job_title, v_phone,
	    v_company_name, v_address_1, v_address_2, 
		v_address_3, v_address_4, v_town, v_state, v_postcode, 
		v_country_code, v_est_spend, v_currency_code,
		in_existing_company_sid, in_existing_user_sid
	) RETURNING contact_id INTO v_contact_id;
	
	-- get the contact's data for return
	GetContact(v_contact_id, out_cur);
END;

PROCEDURE GetContact(
	in_contact_id			IN  contact.contact_id%TYPE, 
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- verify we can at least read the company that's set in the context
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the company with sid '||company_pkg.GetCompany||'.');
	END IF;
	
	-- verify that the current user is an authorized user of the company
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, company_pkg.GetCompany) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user for '||company_pkg.GetCompany||'.');
	END IF;

	OPEN out_cur FOR
		SELECT contact_id, contact_state_id, owner_company_sid, app_sid, contact_guid, existing_company_sid, existing_user_sid,
		       last_contact_state_update_dtm, registered_to_company_sid, registered_as_user_sid, full_name, email, job_title, phone_number,
		       company_name, address_1, address_2, address_3, address_4, town, state, postcode, country_code, estimated_annual_spend,
		       currency_code
		  FROM v$contact
		 WHERE contact_id = in_contact_id
		   AND app_sid = security_pkg.GetApp
		   AND owner_company_sid = company_pkg.GetCompany;
END;

END contact_pkg;
/



