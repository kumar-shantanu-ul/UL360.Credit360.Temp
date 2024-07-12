CREATE OR REPLACE PACKAGE BODY DONATIONS.recipient_Pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	DELETE FROM region_group_recipient
		  WHERE recipient_sid IN (
		  	SELECT recipient_sid FROM recipient
		  	 WHERE parent_sid = in_sid_id
		  	    OR recipient_sid = in_sid_id);
	
	-- "on delete set null" will try to set the APP_SID to null
	-- so we have to do this
	UPDATE csr.supplier
	   SET recipient_sid = null
	 WHERE recipient_sid = in_sid_Id;
		  	    
	DELETE FROM recipient
		WHERE parent_sid = in_sid_id
		OR recipient_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS	
BEGIN	 
	NULL;
END;

-- 
-- PROCEDURE: CreateRECIPIENT 
--
PROCEDURE CreateRecipient(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_PKG.T_SID_ID,
	in_parent_sid				IN 	security_PKG.T_SID_ID,
	in_org_name		  			IN	recipient.org_name%TYPE,
	in_contact_name		  		IN	recipient.contact_name%TYPE,
	in_address_1				IN	recipient.address_1%TYPE,
	in_address_2				IN	recipient.address_2%TYPE,
	in_address_3				IN	recipient.address_3%TYPE,
	in_address_4				IN	recipient.address_4%TYPE,
	in_town		  				IN	recipient.town%TYPE,
	in_state					IN	recipient.state%TYPE,
	in_postcode				 	IN	recipient.postcode%TYPE,
	in_country_code				IN	postcode.country.country%TYPE,
	in_phone					IN	recipient.phone%TYPE,
	in_phone_alt				IN	recipient.phone_alt%TYPE,
	in_fax						IN	recipient.fax%TYPE,
	in_email					IN	recipient.email%TYPE,
	in_ref						IN	recipient.ref%TYPE,
	in_account_num				IN	recipient.account_num%TYPE,
	in_bank_name				IN	recipient.bank_name%TYPE,
	in_sort_code				IN	recipient.sort_code%TYPE,
	in_tax_id					IN	recipient.tax_id%TYPE,
	out_recipient_sid  			OUT security_PKG.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Donations/Recipients
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/Recipients');
	
	-- use a null name (possibly they want dupe names?)
	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('DonationsRecipient'), Null, out_recipient_sid);
	
	INSERT INTO recipient
			(recipient_sid, parent_sid, app_sid, org_name, org_name_soundex, 
			 contact_NAME, address_1,
			 address_2, address_3, address_4, town, state,
			 postcode, phone, phone_alt, fax, country_code,
			 email, ref, account_num, bank_name, sort_code, tax_id
			)
	  VALUES (out_recipient_sid, in_parent_sid, in_app_sid, in_org_name, soundex(in_org_name), 
	  	 in_contact_name, in_address_1,
			 in_address_2, in_address_3, in_address_4, in_town, in_state,
			 in_postcode, in_phone, in_phone_alt, in_fax, in_country_code,
			 in_email, in_ref, in_account_num, in_bank_name, in_sort_code, in_tax_id
			);
			
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, in_app_sid, out_recipient_sid,
		'Created "{0}"', in_org_name);
END;


PROCEDURE AmendRecipient(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_recipient_sid			IN	security_PKG.T_SID_ID,
	in_parent_sid				IN 	security_PKG.T_SID_ID,
	in_org_name					IN	recipient.org_name%TYPE,
	in_contact_name				IN	recipient.contact_name%TYPE,
	in_address_1				IN	recipient.address_1%TYPE,
	in_address_2	 			IN	recipient.address_2%TYPE,
	in_address_3	 			IN	recipient.address_3%TYPE,
	in_address_4	 			IN	recipient.address_4%TYPE,
	in_town						IN	recipient.town%TYPE,
	in_state		  			IN	recipient.state%TYPE,
	in_postcode	  				IN	recipient.postcode%TYPE,
	in_country_code				IN	postcode.country.country%TYPE,
	in_phone		  			IN	recipient.phone%TYPE,
	in_phone_alt				IN	recipient.phone_alt%TYPE,
	in_fax		 				IN	recipient.fax%TYPE,
	in_email					IN	recipient.email%TYPE,
	in_ref						IN	recipient.ref%TYPE,
	in_account_num				IN	recipient.account_num%TYPE,
	in_bank_name				IN	recipient.bank_name%TYPE,
	in_sort_code				IN	recipient.sort_code%TYPE,
	in_tax_id					IN	recipient.tax_id%TYPE
)
AS
	CURSOR c IS
		SELECT app_sid, org_name, contact_name, address_1, address_2, address_3, address_4, town, state, 
			postcode, country_code, phone, phone_alt, fax, email, ref, account_num, sort_code, bank_name, tax_id
		 FROM recipient
		WHERE recipient_sid = in_recipient_sid;		
	r c%ROWTYPE; 
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_recipient_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
		
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN 
		-- should never happen
		RETURN; 
	END IF;
	
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Org Name', r.org_name, in_org_name);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Contact Name', r.contact_name, in_contact_name);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Address 1', r.address_1, in_address_1);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Address 2', r.address_2, in_address_2);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Address 3', r.address_3, in_address_3);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Address 4', r.address_4, in_address_4);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Town', r.town, in_town);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'State', r.state, in_state);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Postcode', r.postcode, in_postcode);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Country Code', r.country_code, in_country_code);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Phone', r.phone, in_phone);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Phone Alt', r.phone_alt, in_phone_alt);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Fax', r.fax, in_fax);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Email', r.email, in_email);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Ref', r.ref, in_ref);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Account Num', r.account_num, in_account_num);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Sort Code', r.sort_code, in_sort_code);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Bank Name', r.bank_name, in_bank_name);
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_RECIPIENT, r.app_sid, in_recipient_sid,
		'Tax ID', r.tax_id, in_tax_id);

	
	UPDATE recipient
	 SET parent_sid = in_parent_sid,
	 	 contact_name = in_contact_name,
	 	 org_name = in_org_name,
	 	 org_name_soundex = soundex(in_org_name),
		 address_1 = in_address_1,
		 address_2 = in_address_2,
		 address_3 = in_address_3,
		 address_4 = in_address_4,
		 town = in_town,
		 state = in_state,
		 postcode = in_postcode,
		 phone = in_phone,
		 phone_alt = in_phone_alt,
		 fax = in_fax,
		 country_code = in_country_code,
		 email = in_email,
		 REF = in_ref,
		 account_num = in_account_num,
		 bank_name = in_bank_name,
		 sort_code = in_sort_code,
		 tax_id = in_tax_id
	 WHERE recipient_sid = in_recipient_sid;
END;


FUNCTION GetOrgName(
	in_recipient_sid		IN security_pkg.T_SID_ID
) RETURN recipient.org_name%TYPE
AS
	v_org_name				recipient.org_name%TYPE;
BEGIN
	IF in_recipient_sid IS NULL THEN
		RETURN NULL;
	END IF;

	SELECT org_name
	  INTO v_org_name
	  FROM recipient
	 WHERE recipient_sid = in_recipient_sid;
	 RETURN v_org_name;
END;


FUNCTION GetChildCount(
	in_recipent_sid		IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_child_count		NUMBER(10);
BEGIN
	SELECT COUNT(0)
	  INTO v_child_count
	  FROM recipient
	 WHERE parent_sid = in_recipent_sid;
	 
	 RETURN v_child_count;
END;


FUNCTION ConcatTagIds(
	in_recipient_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(2);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM RECIPIENT_TAG WHERE RECIPIENT_SID = in_recipient_sid)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;

/* search */

PROCEDURE Search (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_phrase			IN	varchar2,
	in_max				IN	number,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_phrase		varchar2(255);
	v_filter		NUMBER(1); --csr.customer.filter_recipient_regiongp%TYPE;
BEGIN
	
	-- filter results based on region group?
	SELECT recipient_region_group
	  INTO v_filter
	  FROM customer_filter_flag
	 WHERE app_sid = in_app_sid;

	-- Do the search
	v_phrase := LOWER(in_phrase);
	IF v_filter > 0 THEN
		OPEN out_cur FOR
			SELECT * FROM (
				SELECT r.recipient_sid, r.parent_sid, r.org_name, r.contact_name, r.address_1, r.address_2, r.address_3, r.address_4, 
	                   r.org_name_soundex, r.town, r.state, r.postcode, r.phone, r.fax, r.email, r.last_used_dtm, r.country_code, r.ref, rownum rn,
	                   GetOrgName(r.parent_sid) parent_org_name, GetChildCount(r.recipient_sid) child_count, ct.name country_name, ConcatTagIds(r.recipient_sid) tag_ids,
	                   r.account_num, r.bank_name, r.sort_code, r.tax_id
			      FROM recipient r, region_group_recipient rgr, postcode.country ct
			     WHERE r.app_sid = in_app_sid
				   AND r.recipient_sid = rgr.recipient_sid
				   AND r.country_code = ct.country
				   AND (rgr.region_group_sid = in_region_group_sid OR in_region_Group_Sid IS NULL)
			       AND (LOWER(r.org_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(r.contact_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(r.postcode) LIKE '%'||v_phrase||'%' 
			        OR LOWER(r.ref) LIKE '%'||v_phrase||'%' 
			        OR LOWER(r.tax_id) LIKE '%'||v_phrase||'%' 
			        --OR r.org_name_soundex = SOUNDEX(v_phrase)
			        OR UPPER(REPLACE(postcode, ' ', '')) = UPPER(REPLACE(v_phrase, ' ', ''))
			        OR LOWER(PRIOR r.org_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(PRIOR r.contact_name) LIKE '%'||v_phrase||'%'
			        OR LOWER(PRIOR r.postcode) LIKE '%'||v_phrase||'%' 
			        OR LOWER(PRIOR r.ref) LIKE '%'||v_phrase||'%' 
			        OR LOWER(PRIOR r.tax_id) LIKE '%'||v_phrase||'%' 
			        --OR PRIOR r.org_name_soundex = SOUNDEX(v_phrase)
			        OR UPPER(REPLACE(PRIOR postcode, ' ', '')) = UPPER(REPLACE(v_phrase, ' ', ''))
			        )
			              START WITH r.parent_sid IS NULL      
			          CONNECT BY PRIOR r.recipient_sid = r.parent_sid
			          ORDER SIBLINGS BY LOWER(org_name)
			) WHERE rn < in_max;
	ELSE
		OPEN out_cur FOR
			SELECT * FROM (
				SELECT recipient_sid, parent_sid, org_name, contact_name, address_1, address_2, address_3, address_4, 
	                   org_name_soundex, town, state, postcode, phone, fax, email, last_used_dtm, recipient.country_code, ref, rownum rn,
	                   GetOrgName(parent_sid) parent_org_name, GetChildCount(recipient_sid) child_count, ct.name country_name, ConcatTagIds(recipient_sid) tag_ids,
	                   account_num, bank_name, sort_code, tax_id
			      FROM recipient, postcode.country ct
			     WHERE app_sid = in_app_sid
				   AND recipient.country_code = ct.country
			       AND (LOWER(org_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(contact_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(postcode) LIKE '%'||v_phrase||'%' 
			        OR LOWER(ref) LIKE '%'||v_phrase||'%' 
			        OR LOWER(tax_id) LIKE '%'||v_phrase||'%' 
			        --OR org_name_soundex = SOUNDEX(v_phrase)	
			        OR UPPER(REPLACE(postcode, ' ', '')) = UPPER(REPLACE(v_phrase, ' ', ''))
			        OR LOWER(PRIOR org_name) LIKE '%'||v_phrase||'%' 
			        OR LOWER(PRIOR contact_name) LIKE '%'||v_phrase||'%'
			        OR LOWER(PRIOR postcode) LIKE '%'||v_phrase||'%'
			        OR LOWER(PRIOR ref) LIKE '%'||v_phrase||'%' 
			        OR LOWER(PRIOR tax_id) LIKE '%'||v_phrase||'%' 
			        --OR PRIOR org_name_soundex = SOUNDEX(v_phrase)
			        OR UPPER(REPLACE(PRIOR postcode, ' ', '')) = UPPER(REPLACE(v_phrase, ' ', ''))
			        )
			              START WITH parent_sid IS NULL
			          CONNECT BY PRIOR recipient_sid = parent_sid
			          ORDER SIBLINGS BY LOWER(org_name)
			) WHERE rn < in_max;
	END IF;
END;



PROCEDURE GetRecipient(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- what permissions?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_recipient_sid, security_Pkg.PERMISSION_READ) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing recipient');
	END IF;

	OPEN out_cur FOR
		SELECT r.recipient_sid, r.parent_sid, r.org_name, r.contact_name, r.address_1, r.address_2, r.address_3, r.address_4,
			 	 r.town, r.state, r.postcode, r.phone, r.fax, r.email, r.last_used_dtm, r.country_code, r.ref, c.name,
			     r.account_num, r.bank_name, r.sort_code, r.tax_id
		  FROM recipient r
			JOIN postcode.country c ON r.country_code = c.country
		 WHERE recipient_sid = in_recipient_sid;
END;

PROCEDURE GetRecipientByName(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_org_name					IN  recipient.org_name%TYPE,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
)
AS
	v_recipient_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT recipient_sid
		  INTO v_recipient_sid
		  FROM recipient
		 WHERE org_name = in_org_name;
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(scheme_pkg.ERR_DUPLICATE_NAMES, 'Mutliple recipients of this name found');
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Recipient not found');
	END;
	
	GetRecipient(in_act_id, v_recipient_sid, out_cur);
END;

PROCEDURE GetRecipientsForApp(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- what permissions?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing application');
	END IF;

	OPEN out_cur FOR
		SELECT recipient_sid, parent_sid, org_name, contact_name, address_1, address_2, address_3, address_4,
			 	 town, state, postcode, phone, fax, email, last_used_dtm, country_code, ref,
			 	 account_num, bank_name, sort_code, tax_id
		  FROM recipient
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetChildRecipients(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- what permissions?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_Pkg.PERMISSION_READ) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing application');
	END IF;
	
	IF in_parent_sid IS NULL THEN
		OPEN out_cur FOR
			SELECT recipient_sid, parent_sid, org_name, contact_name, address_1, address_2, address_3, address_4,
				 	 town, state, postcode, phone, fax, email, last_used_dtm, country_code, ref,
				 	 account_num, bank_name, sort_code
			  FROM recipient
			 WHERE parent_sid IS NULL;
	ELSE
		OPEN out_cur FOR
			SELECT recipient_sid, parent_sid, org_name, contact_name, address_1, address_2, address_3, address_4,
				 	 town, state, postcode, phone, fax, email, last_used_dtm, country_code, ref,
				 	 account_num, bank_name, sort_code
			  FROM recipient
			 WHERE parent_sid = in_parent_sid;
	END IF;
END;

PROCEDURE AddRecipientRegionGroup(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID
)
AS
	v_count				NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_recipient_sid, security_Pkg.PERMISSION_WRITE) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to recipient');
	END IF;	
	
	-- Check for existing relationship
	SELECT COUNT(0)
	  INTO v_count
	  FROM region_group_recipient
	 WHERE recipient_sid = in_recipient_sid
	   AND region_group_sid = in_region_group_sid;
	 
	 -- Already present
	 IF v_count > 0 THEN
	 	RETURN;
	 END IF;
	 
	 -- Ok, insert the relationship
	 INSERT INTO region_group_recipient
	 	(region_group_sid, recipient_sid)
	   VALUES (in_region_group_sid, in_recipient_sid);
END;


PROCEDURE SetPostIt(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_postit_id		IN	csr.postit.postit_id%TYPE,
	out_postit_id		OUT csr.postit.postit_id%TYPE
)
AS
BEGIN
	csr.postit_pkg.Save(in_postit_id, null, 'message', in_recipient_sid, out_postit_id);
	
	BEGIN
		INSERT INTO recipient_postit (recipient_sid, postit_id)
			VALUES (in_recipient_sid, out_postit_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;

PROCEDURE GetPostIts(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_recipient_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    OPEN out_cur FOR
		SELECT iap.recipient_sid, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid, 
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM recipient_postit iap
			JOIN csr.v$postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
		 WHERE recipient_sid = in_recipient_sid
		 ORDER BY created_dtm;

	OPEN out_cur_files FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, pf.sha1, pf.uploaded_dtm
		  FROM recipient_postit iap
			JOIN csr.postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
			JOIN csr.postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE recipient_sid = in_recipient_sid;
END;

PROCEDURE FindRef(
	in_ref				IN	varchar2,
	in_country_code		IN	postcode.country.country%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: check UK / other country lists...
	
	-- no security needed -- this is public information
	OPEN out_cur FOR 
		SELECT title, charity_number, activities, contact_name, address, website, telephone, 
			date_registered, date_removed, accounts_date, spending, income, company_number, 
			openlylocal_url, twitter_account_name, facebook_account_name, youtube_account_name, 
			created_at, updated_at
		  FROM uk_charity
		 WHERE charity_number = in_ref;
END;

PROCEDURE FilterRef(
	in_filter			IN	varchar2,
	in_country_code		IN	postcode.country.country%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: check UK / other country lists...
	
	-- no security needed -- this is public information
	OPEN out_cur FOR 
		SELECT title, charity_number, address, telephone
		  FROM uk_charity
		 WHERE charity_number like in_filter||'%'
		   OR UPPER(title) like upper('%'||in_filter||'%');
END;


END recipient_Pkg;
/
