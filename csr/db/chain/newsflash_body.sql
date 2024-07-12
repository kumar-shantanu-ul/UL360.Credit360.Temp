CREATE OR REPLACE PACKAGE BODY CHAIN.newsflash_pkg
IS

FUNCTION HasCapability
(
	in_capability chain_pkg.T_CAPABILITY
)
RETURN BOOLEAN AS
BEGIN
	RETURN capability_pkg.CheckCapability(company_pkg.GetCompany, in_capability);
END;

PROCEDURE EnsureCapability
(
	in_capability chain_pkg.T_CAPABILITY
)
AS
BEGIN
	IF NOT HasCapability(in_capability) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Capability ''' || in_capability || ''' has not been granted to user ' || security_pkg.GetSID());
	END IF;
END;

PROCEDURE GetNewsflashSummarySP
(
	out_sp OUT customer_options.newsflash_summary_sp%TYPE
)
AS
BEGIN
	SELECT newsflash_summary_sp INTO out_sp
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetApp();
	 
	 IF out_sp IS NULL THEN
		out_sp := 'chain.newsflash_pkg.GetNewsSummary';
	 END IF;
END;

PROCEDURE AddNewsflash
(
	in_content newsflash.content%TYPE,
	out_newsflash_id OUT newsflash.newsflash_id%TYPE
)
AS
BEGIN
	EnsureCapability(chain_pkg.SEND_NEWSFLASH);

	-- Not released automatically. Use RestrictNewsflash(), ExpireNewsflash() and then ReleaseNewsflash().

	INSERT INTO newsflash (newsflash_id, content, released_dtm) VALUES (newsflash_id_seq.nextval, in_content, NULL) RETURNING newsflash_id INTO out_newsflash_id;
END;

PROCEDURE RestrictNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_for_suppliers NUMBER DEFAULT 0, -- For companies that are a (direct) supplier of the company that sent the message.
	in_for_users NUMBER DEFAULT 0 -- For users that have the chain_pkg.RECEIVE_USER_TARGETED_NEWS capability.
)
AS
BEGIN
	INSERT INTO newsflash_company (newsflash_id, for_suppliers, for_users) VALUES (in_newsflash_id, in_for_suppliers, in_for_users);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE newsflash_company SET for_suppliers = in_for_suppliers, for_users = in_for_users
		 WHERE newsflash_id = in_newsflash_id;
END;

PROCEDURE ExpireNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_expiry_dtm DATE DEFAULT SYSDATE
)
AS
BEGIN
	UPDATE newsflash SET expired_dtm = in_expiry_dtm WHERE newsflash_id = in_newsflash_id;
END;

PROCEDURE ReleaseNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_release_dtm DATE DEFAULT SYSDATE
)
AS
BEGIN
	UPDATE newsflash SET released_dtm = CASE WHEN in_release_dtm < created_dtm THEN created_dtm ELSE in_release_dtm END WHERE newsflash_id = in_newsflash_id;
	-- If the newsflash is re-released, then ensure it is shown even if the old version has been hidden from specific users.
	UPDATE newsflash_user_settings SET hidden = 0 WHERE newsflash_id = in_newsflash_id;
END;

FUNCTION ChainNewsSummary RETURN CHAIN.T_NEWSFLASH_TABLE
AS
	v_cur    			SYS_REFCURSOR;
	v_table  			CHAIN.T_NEWSFLASH_TABLE := CHAIN.T_NEWSFLASH_TABLE();
	v_newsflash_id 		NUMBER(10);
	v_released_dtm 		DATE;
	v_content 			CLOB;
	v_for_users 		NUMBER(1);
	v_for_suppliers 	NUMBER(1);
BEGIN
	GetNewsSummary(v_cur);
	LOOP
		--the T_NEWSFLASH_ROW type fields are not defined as newsflash.column%TYPE, so I need to break the fetched rec to vars
		FETCH v_cur INTO v_newsflash_id, v_released_dtm, v_content, v_for_users, v_for_suppliers;
		EXIT WHEN v_cur%NOTFOUND;
		v_table.extend;
		v_table(v_table.count) := CHAIN.T_NEWSFLASH_ROW(v_newsflash_id, v_released_dtm, v_content, v_for_users, v_for_suppliers);
	END LOOP;
	CLOSE v_cur;
	RETURN v_table;
END;

PROCEDURE GetNewsSummary
(
	out_news_summary_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_newsflash NUMBER;
BEGIN
	IF HasCapability(chain_pkg.RECEIVE_USER_TARGETED_NEWS) THEN
		v_user_newsflash := 1;
	ELSE
		v_user_newsflash := 0;
	END IF;
	
	OPEN out_news_summary_cur FOR
		SELECT n.newsflash_id, n.released_dtm, n.content, nc.for_users, nc.for_suppliers
		  FROM newsflash n
		  LEFT JOIN newsflash_company nc ON nc.app_sid = n.app_sid AND nc.newsflash_id = n.newsflash_id
		  LEFT JOIN newsflash_user_settings nus ON nus.app_sid = n.app_sid AND nus.newsflash_id = n.newsflash_id AND nus.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE n.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND n.content IS NOT NULL
		   AND NVL(nus.hidden, 0) = 0
		   AND n.released_dtm <= SYSDATE
		   AND NVL(n.expired_dtm, SYSDATE + 1) > SYSDATE
		   AND (nc.newsflash_id IS NULL -- Messages for all companies.
				OR ( -- For this company.
					nc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				AND nc.for_users = 1
				AND v_user_newsflash = 1
				)
			    OR ( -- For companies that are a supplier of the company that sent the message.
					nc.for_suppliers = 1
				AND EXISTS (SELECT * FROM v$supplier_relationship WHERE purchaser_company_sid = nc.company_sid AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
				)
			   )
		 ORDER BY n.released_dtm DESC;
END;

PROCEDURE HideNewsflashFromUser
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_user_sid newsflash_user_settings.user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
BEGIN
	INSERT INTO newsflash_user_settings (newsflash_id, user_sid, hidden) VALUES (in_newsflash_id, in_user_sid, 1);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE newsflash_user_settings SET hidden = 1
		 WHERE newsflash_id = in_newsflash_id
		   AND user_sid = in_user_sid;
END;

END newsflash_pkg;
/
