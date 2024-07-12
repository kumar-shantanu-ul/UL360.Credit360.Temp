define rap5_version=3
@update_header

ALTER TABLE UNINVITED_SUPPLIER ADD(CREATED_AS_COMPANY_SID NUMBER(10, 0));

/********************************************************
	Put package in here rather than referencing as it is
	Likely we will move the methods to another package
	rather than a package just for uninvited suppliers
********************************************************/


CREATE OR REPLACE PACKAGE  uninvited_pkg
IS

PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_id	IN	NUMBER,
	in_created_as_company_sid	IN	NUMBER
);

END uninvited_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.uninvited_pkg
IS

PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN

	-- TODO: Is this the appropriate permission level? Would anyone need to search uninvited suppliers
	--       if they weren't then going to invite them?
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for uninvited suppliers');
	END IF;
	
	-- Find all IDs that match the search criteria
	SELECT T_NUMERIC_ROW(uninvited_supplier_id, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT ui.uninvited_supplier_id
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (LOWER(ui.name) LIKE v_search)
		   AND ui.created_as_company_sid IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page in the order specified
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT ui.*, ctry.name as country_name,
				   row_number() OVER (ORDER BY 
						CASE
							WHEN in_sort_by='name' AND in_sort_dir = 'DESC' THEN LOWER(ui.name)
							WHEN in_sort_by='countryName' AND in_sort_dir = 'DESC' THEN LOWER(ctry.name)
						END DESC,
						CASE
							WHEN in_sort_by='name' AND in_sort_dir = 'ASC' THEN LOWER(ui.name)
							WHEN in_sort_by='countryName' AND in_sort_dir = 'ASC' THEN LOWER(ctry.name)
						END ASC 
				   ) rn
			  FROM uninvited_supplier ui
			  JOIN TABLE(v_results) r ON ui.uninvited_supplier_id = r.item
			  JOIN postcode.country ctry on ctry.country = ui.country_code
			 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY rn
		  ) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1;

END;

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_id	IN	NUMBER,
	in_created_as_company_sid	IN	NUMBER
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied applying company_sid to uninvited supplier');
	END IF;
	
	UPDATE uninvited_supplier
	   SET created_as_company_sid = in_created_as_company_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND uninvited_supplier_id = in_uninvited_supplier_id;
	
	--TODO: Should we do some error checking here before attempting to migrate?
	
	--TODO: Actual migration of tasks
END;

END uninvited_pkg;
/

BEGIN
		user_pkg.LogonAdmin;
		
		card_pkg.RegisterCardGroup(18, 'Invite the Uninvited Wizard', 'Used to add a contact and invite a company that exists but hasn''t yet been invited');
		
		card_pkg.RegisterCard(
			'Add user card that allows you to add a new user to a company.', 
			'Credit360.Chain.Cards.CreateUser',
			'/csr/site/chain/cards/createUser.js', 
			'Chain.Cards.CreateUser'
		);
END;
/

grant execute on chain.uninvited_pkg to web_user;

commit;

@update_tail