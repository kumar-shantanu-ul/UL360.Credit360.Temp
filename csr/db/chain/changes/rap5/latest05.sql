define rap5_version=5
@update_header

-- Just in case anyone missed this from latest03 when I acceidentally left it commented out.
DECLARE
	v_col_count	INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO v_col_count
	  FROM user_tab_cols
	 WHERE column_name='CREATED_AS_COMPANY_SID'
	   AND table_name='UNINVITED_SUPPLIER';
	
	IF v_col_count = 0 THEN
		EXECUTE IMMEDIATE('ALTER TABLE UNINVITED_SUPPLIER ADD(CREATED_AS_COMPANY_SID NUMBER(10, 0))');
	END IF;
END;
/

DELETE FROM UNINVITED_SUPPLIER;

ALTER TABLE UNINVITED_SUPPLIER RENAME COLUMN UNINVITED_SUPPLIER_ID TO UNINVITED_SUPPLIER_SID;
ALTER TABLE PURCHASED_COMPONENT RENAME COLUMN UNINVITED_SUPPLIER_ID TO UNINVITED_SUPPLIER_SID;

PROMPT >> Creating v$purchased_component
CREATE OR REPLACE VIEW v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, pc.purchaser_company_sid, 
			pc.uninvited_supplier_sid, pc.supplier_product_id
	  FROM purchased_component pc, component cmp
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
;

PROMPT >> Creating v$purchased_component_supplier
CREATE OR REPLACE VIEW v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_sid, 
			NULL supplier_name, NULL supplier_country_code, NULL supplier_country_name
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_supplier_type_id = 0 -- SUPPLIER_NOT_SET
	--
	 UNION
	--
	--EXISTING_SUPPLIER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 1 -- EXISTING_SUPPLIER
	   AND pc.supplier_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--EXISTING_PURCHASER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.purchaser_company_sid supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 2 -- EXISTING_PURCHASER
	   AND pc.purchaser_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--UNINVITED_SUPPLIER (basic data, uninvited supplier data bound)
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			NULL supplier_company_sid, us.uninvited_supplier_sid, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
	   AND us.country_code = coun.country_code
;





@../../chain_pkg;
@../../purchased_component_pkg;
@../../uninvited_pkg;
@../../company_body;
@../../uninvited_body;
@../../purchased_component_body;


grant execute on uninvited_pkg to security;
	
BEGIN	
	user_pkg.LogonAdmin();
	
	card_pkg.RegisterCard(
		'Chain.Cards.AddComponentSupplier extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addSupplier.js', 
		'Chain.Cards.ComponentBuilder.AddSupplier',
		T_STRING_LIST('default', 'createnew')
	);	
	
	card_pkg.RegisterCard(
		'Chain.Cards.CreateCompany extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.CreateCompany',
		'/csr/site/chain/cards/componentBuilder/createSupplier.js', 
		'Chain.Cards.ComponentBuilder.CreateSupplier'
	);	
END;
/

DECLARE
	v_class_id				security_pkg.T_CLASS_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_chain_users_sid		security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
	
	-- it needs to be applied to all companies in the application - as a rule of thumb, anything SO related is "global"
	FOR c IN (
		SELECT app_sid, company_sid, rownum as rn
		  FROM company 
		 ORDER BY app_sid
		
		
	) LOOP

		-- if the app_sid is changing or if first row just to be sure...
		IF c.app_sid <> NVL(SYS_CONTEXT('SECURITY', 'APP'), 0) OR c.rn=1 THEN
			-- log us on (here's yet another method to log someone on - have a look at cvs\security\db\oracle\user_pkg.sql for even more!)
			user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 86400, c.app_sid, v_act_id);
			
			-- we know that it doesn't exist because we're creating it here 
			class_pkg.CreateClass(security_pkg.getACT, null, 'Chain Uninvited Supplier', 'chain.uninvited_pkg', null, v_class_id);
			
			v_chain_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, c.app_sid, 'Groups/'||chain_pkg.CHAIN_USER_GROUP);
		END IF;
		
		securableobject_pkg.CreateSO(v_act_id, c.company_sid, security_pkg.SO_CONTAINER, chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
		
		acl_pkg.AddACE(
			v_act_id, 
			acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
			security_pkg.ACL_INDEX_LAST, 
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_chain_users_sid, 
			security_pkg.PERMISSION_STANDARD_ALL
		);

	END LOOP;
END;
/

@update_tail



