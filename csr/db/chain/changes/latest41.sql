define version=41
@update_header

-- from branch latest39
CREATE TABLE CMPNT_CMPNT_RELATIONSHIP(
    COMPONENT_ID           NUMBER(10, 0)    NOT NULL,
    PARENT_COMPONENT_ID    NUMBER(10, 0)    NOT NULL,
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    CONSTRAINT PK206 PRIMARY KEY (COMPONENT_ID, PARENT_COMPONENT_ID, APP_SID)
)
;

ALTER TABLE CMPNT_CMPNT_RELATIONSHIP ADD CONSTRAINT RefALL_COMPONENT500 
    FOREIGN KEY (PARENT_COMPONENT_ID, APP_SID)
    REFERENCES ALL_COMPONENT(COMPONENT_ID, APP_SID)
;

ALTER TABLE CMPNT_CMPNT_RELATIONSHIP ADD CONSTRAINT RefALL_COMPONENT501 
    FOREIGN KEY (COMPONENT_ID, APP_SID)
    REFERENCES ALL_COMPONENT(COMPONENT_ID, APP_SID)
;

-- from branch latest40
alter table chain.card add constraint uc_c_jct unique (js_class_type); 


@..\chain_pkg
@..\chain_body

begin
	user_pkg.LogonAdmin;

	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.PRODUCT_CODE_TYPES, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.PRODUCT_CODE_TYPES, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.PRODUCT_CODE_TYPES, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ);

	card_pkg.RegisterCard(
		'Allows product type code labels to be defined.', 
		'Credit360.Chain.Cards.EditProductCodeTypes',
		'/csr/site/chain/cards/editProductCodeTypes.js', 
		'Chain.Cards.EditProductCodeTypes',
		null
	);

	FOR r IN (
		SELECT app_sid
		  FROM customer_options
	) LOOP
		security_pkg.SetACT(security_pkg.GetAct, r.app_sid);
		company_pkg.VerifySOStructure;
	END LOOP;
end;
/

@update_tail
