CREATE OR REPLACE PACKAGE BODY DONATIONS.reports_Pkg
IS

PROCEDURE GetRecipients(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_recipients_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT csr.SqlReport_pkg.checkAccess('donations.reports_pkg.getrecipients') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- get securable object Donations/Recipients
	v_recipients_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getAct, security_pkg.getApp, 'Donations/Recipients');
	
	-- check for list contents on parent obj
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getAct, v_recipients_sid, security_Pkg.PERMISSION_LIST_CONTENTS) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading recipients');
	END IF;	
	
	OPEN out_cur FOR
		SELECT r.RECIPIENT_SID, r.ORG_NAME, r.CONTACT_NAME, r.ADDRESS_1, r.ADDRESS_2, r.ADDRESS_3, r.ADDRESS_4, 
			r.TOWN, r.STATE, r.POSTCODE, r.PHONE, r.PHONE_ALT, r.FAX, c.COUNTRY, r.EMAIL, r.REF, r.LAST_USED_DTM,
			CASE 
				WHEN r.parent_Sid IS NOT NULL THEN rp.org_name||' (id '||rp.recipient_sid||')'
				ELSE NULL
			END parent_organisation,
			(SELECT COUNT(*) FROM donation WHERE recipient_sid = r.recipient_sid) donations_made
		  FROM recipient r
			JOIN postcode.country c ON r.country_code = c.country
			LEFT JOIN recipient rp ON r.PARENT_SID = rp.recipient_sid
		 WHERE r.app_sid = security_pkg.getApp
		 ;
		 
END;

PROCEDURE GetPossibleDupeRecipients(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_recipients_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT csr.SqlReport_pkg.checkAccess('donations.reports_pkg.getpossibleduperecipients') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- get securable object Donations/Recipients
	v_recipients_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getAct, security_pkg.getApp, 'Donations/Recipients');

	-- check for list contents on parent obj
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getAct, v_recipients_sid, security_Pkg.PERMISSION_LIST_CONTENTS) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading recipients');
	END IF;	
	
	OPEN out_cur FOR
		SELECT y.recipient_sid, y.org_name, y.postcode, rank() OVER (PARTITION BY y.postcode ORDER BY recipient_sid, y.postcode, cnsex) "Rank"
		  FROM (
				SELECT dr.recipient_sid, dr.postcode, cnsex, org_name
				  FROM donations.recipient dr, (
					 SELECT SOUNDEX(org_name) cnsex, postcode 
					   FROM donations.recipient 
					  WHERE LENGTH(postcode)>5 
						AND postcode NOT LIKE '**%' 
						AND app_sid = security_pkg.getApp
					  GROUP BY SOUNDEX(org_name), postcode 
					 HAVING COUNT(*) > 1
			  )x
		 WHERE SOUNDEX(dr.org_name) = x.cnsex 
		   AND dr.postcode = x.postcode 
		 ORDER BY dr.postcode
	 )y;
END;


END reports_Pkg;
/
