whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

CREATE OR REPLACE VIEW v$company_component AS
SELECT component_id, cmp.app_sid, c.company_sid, c.name company_name, cmp.created_by_sid, cu.full_name created_by, cmp.created_dtm, cmp.description, cmp.component_code,
	   component_type_id, cmp.deleted
      FROM component cmp, v$company c, csr.csr_user cu
     WHERE cmp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
       AND cmp.company_sid = c.company_sid
       AND cmp.app_sid = c.app_sid
       AND cmp.created_by_sid = cu.csr_user_sid
       AND cmp.app_sid = cu.app_sid
;

CREATE OR REPLACE VIEW v$component AS
	SELECT app_sid, component_id, company_sid, created_by_sid, created_dtm, description, component_type_id, component_code
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

ALTER TABLE PRODUCT ADD (
	PRODUCT_BUILDER_COMPONENT_ID    NUMBER(10, 0)
);

UPDATE PRODUCT SET PRODUCT_BUILDER_COMPONENT_ID = ROOT_COMPONENT_ID;

ALTER TABLE PRODUCT MODIFY PRODUCT_BUILDER_COMPONENT_ID NOT NULL;

ALTER TABLE PRODUCT ADD CONSTRAINT RefCOMPONENT539 
    FOREIGN KEY (APP_SID, PRODUCT_BUILDER_COMPONENT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;

CREATE OR REPLACE VIEW v$company_product AS
	SELECT product_id, p.app_sid, p.company_sid, c.name company_name, p.created_by_sid, cu.full_name created_by, p.created_dtm, p.description, p.active, 
			code_label1, code1, code_label2, code2, code_label3, code3, need_review, p.deleted, 
			p.root_component_id, p.product_builder_component_id
		  FROM product p, product_code_type pct, v$company c, csr.csr_user cu
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = pct.company_sid
		   AND p.app_sid = pct.app_sid
		   AND p.company_sid = c.company_sid
		   AND p.app_sid = c.app_sid
		   AND p.created_by_sid = cu.csr_user_sid
		   AND p.app_sid = cu.app_sid
;

CREATE OR REPLACE VIEW v$product AS
	SELECT product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, root_component_id, product_builder_component_id
	  FROM v$company_product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

@packages

BEGIN
	user_pkg.LogonAdmin;
	
	card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.ProgressionTestingCard',
		T_STRING_LIST('trigger1', 'trigger2')
	);

	/*** SEARCH COMPANIES ***/
	card_pkg.RegisterCard(
		'Search for companies.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchCompanies.js', 
		'Chain.Cards.SearchCompanies'
	);

	/*** COMPONENT BUILDER - ADD MORE CHILDREN ***/
	card_pkg.RegisterCard(
		'Lists the child components of the current component and gives the option to add more', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addMoreChildren.js', 
		'Chain.Cards.ComponentBuilder.AddMoreChildren',
		T_STRING_LIST('yes', 'no')
	);
	
	/*** COMPONENT BUILDER - COMPONENT SOURCE ***/
	card_pkg.RegisterCard(
		'Asks where a component comes from', 
		'Credit360.Chain.Cards.ComponentSource',
		'/csr/site/chain/cards/componentBuilder/componentSource.js', 
		'Chain.Cards.ComponentBuilder.ComponentSource'
		-- intentional deletion of all progression steps
	);

	/*** COMPONENT BUILDER - IS PURCHASED ***/
	card_pkg.RegisterCard(
		'Determines if the product is re-sold or manufactured', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/isPurchased.js', 
		'Chain.Cards.ComponentBuilder.IsPurchased'
	);

	/*** COMPONENT BUILDER - ADD SUPPLER ***/
	card_pkg.RegisterCard(
		'Chain.Cards.AddCompany extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/componentBuilder/addSupplier.js', 
		'Chain.Cards.ComponentBuilder.AddSupplier'
	);	

	/*** COMPONENT BUILDER - ADD MORE CHILDREN ***/
	card_pkg.RegisterCard(
		'Lists the child components of the current component and gives the option to add more', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addMoreChildren.js', 
		'Chain.Cards.ComponentBuilder.AddMoreChildren',
		T_STRING_LIST('yes', 'no', 'finished')
	);

	/*** COMPONENT BUILDER - NOT SURE ***/
	card_pkg.RegisterCard(
		'Not sure', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/notSure.js', 
		'Chain.Cards.ComponentBuilder.NotSure'
	);

	/*** COMPONENT BUILDER - END POINT ***/
	card_pkg.RegisterCard(
		'A friendly message thanking you for using the Component Builder wizard', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/endPoint.js', 
		'Chain.Cards.ComponentBuilder.EndPoint'
	);

	/*** ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Add component card that prompts you to search for an existing component or enter the basic details for a new one. This card does not handle the actual search.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addComponent.js', 
		'Chain.Cards.AddComponent',
		T_STRING_LIST('search', 'new')
	);

	/*** EDIT COMPONENT ***/
	card_pkg.RegisterCard(
		'Edit a component''s details.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/editComponent.js', 
		'Chain.Cards.EditComponent'
	);
	
	/*** SEARCH COMPONENT ***/
	card_pkg.RegisterCard(
		'Search for an existing component.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponents.js', 
		'Chain.Cards.SearchComponents'
	);

	/*** COMPONENT BUILDER - ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Chain.Cards.AddComponent extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addComponent.js', 
		'Chain.Cards.ComponentBuilder.AddComponent',
		T_STRING_LIST('search', 'new', 'newpurchased')
	);
	
	/*** COMPONENT BUILDER - SEARCH COMPONENT ***/
	card_pkg.RegisterCard(
		'Chain.Cards.SearchComponents extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/searchComponents.js', 
		'Chain.Cards.ComponentBuilder.SearchComponents'
	);
	
	-- From RA scripts

	/*** COMPONENT BUILDER - WOOD ***/
	card_pkg.RegisterCard(
		'This is a place holder for handling raw materials (wood)', 
		'Credit360.Chain.Cards.Empty',
		'/rainforestalliance/site/cards/componentBuilderWood.js', 
		'Rainforestalliance.Cards.ComponentBuilder.Wood'
	);

	card_pkg.RegisterCard(
		'Wood Source',
		'Clients.RainforestAlliance.Cards.WoodSource',
		'/rainforestalliance/cards/woodSource.js',
		'Rainforest.Cards.WoodSource'
	);
	
	card_pkg.RegisterCard(
		'Wood Origin',
		'Clients.RainforestAlliance.Cards.WoodOrigin',
		'/rainforestalliance/cards/woodOrigin.js',
		'Rainforest.Cards.WoodOrigin'
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodAccreditation',
		'/rainforestalliance/cards/woodAccreditation.js',
		'Rainforest.Cards.WoodAccreditation',
		T_STRING_LIST('helpmeworkitout', 'skipworkingitout')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.Sourcing',
		'/rainforestalliance/cards/WoodWizard/sourcing.js',
		'Rainforest.Cards.WoodWizard.Sourcing',
		T_STRING_LIST('virgin', 'waste')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.VirginFscCertified',
		'/rainforestalliance/cards/WoodWizard/virginFscCertified.js',
		'Rainforest.Cards.WoodWizard.VirginFscCertified',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.OtherForestCertification',
		'/rainforestalliance/cards/WoodWizard/otherForestCertification.js',
		'Rainforest.Cards.WoodWizard.OtherForestCertification',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.ProgressingTowardsFsc',
		'/rainforestalliance/cards/WoodWizard/progressingTowardsFsc.js',
		'Rainforest.Cards.WoodWizard.ProgressingTowardsFsc',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.NonControversialNotEligible',
		'/rainforestalliance/cards/WoodWizard/nonControversialNotEligible.js',
		'Rainforest.Cards.WoodWizard.NonControversialNotEligible',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.NonControversialWelfare',
		'/rainforestalliance/cards/WoodWizard/nonControversialWelfare.js',
		'Rainforest.Cards.WoodWizard.NonControversialWelfare',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.NonControversialProtected',
		'/rainforestalliance/cards/WoodWizard/nonControversialProtected.js',
		'Rainforest.Cards.WoodWizard.NonControversialProtected',
		T_STRING_LIST('incomplete', 'complete')
	);

	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.LegalOriginCertified',
		'/rainforestalliance/cards/WoodWizard/legalOriginCertified.js',
		'Rainforest.Cards.WoodWizard.LegalOriginCertified',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.LegalOriginUncertified',
		'/rainforestalliance/cards/WoodWizard/legalOriginUncertified.js',
		'Rainforest.Cards.WoodWizard.LegalOriginUncertified',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.KnownSource',
		'/rainforestalliance/cards/WoodWizard/knownSource.js',
		'Rainforest.Cards.WoodWizard.KnownSource'
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.WastePostConsumer',
		'/rainforestalliance/cards/WoodWizard/wastePostConsumer.js',
		'Rainforest.Cards.WoodWizard.WastePostConsumer',
		T_STRING_LIST('incomplete', 'complete')
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.WastePreConsumer',
		'/rainforestalliance/cards/WoodWizard/wastePreConsumer.js',
		'Rainforest.Cards.WoodWizard.WastePreConsumer'
	);
	
	card_pkg.RegisterCard(
		'Wood Accreditation',
		'Clients.RainforestAlliance.Cards.WoodWizard.Complete',
		'/rainforestalliance/cards/WoodWizard/complete.js',
		'Rainforest.Cards.WoodWizard.Complete'
	);
	
	card_pkg.RegisterCard(
		'Wood Evidence',
		'Clients.RainforestAlliance.Cards.WoodEvidence',
		'/rainforestalliance/cards/woodEvidence.js',
		'Rainforest.Cards.WoodEvidence'
	);
	
END;
/

BEGIN	
	FOR a IN (
		SELECT app_sid FROM customer_options
	) LOOP
	
		FOR r IN (
			SELECT 	1 type_id, 'Root' description, 'Credit360.Chain.Products.RootComponent' handler_class, 'chain.component_pkg' handler_pkg,  '/csr/site/chain/components/products/RootNode.js' node_js_path FROM DUAL
			UNION ALL
			SELECT 	2 type_id, 'Logical' description, 'Credit360.Chain.Component.Logical' handler_class, 'chain.component_pkg' handler_pkg,  '/csr/site/chain/components/products/ComponentNode.js' node_js_path FROM DUAL
			UNION ALL
			SELECT 	3 type_id, 'Purchased' description, 'Credit360.Chain.Component.Purchased' handler_class, 'chain.component_pkg' handler_pkg,  '/csr/site/chain/components/products/ComponentNode.js' node_js_path FROM DUAL
		) LOOP
			
			BEGIN
				INSERT INTO component_type
				(app_sid, component_type_id, handler_class, handler_pkg, node_js_path, description)
				VALUES
				(a.app_sid, r.type_id, r.handler_class, r.handler_pkg, r.node_js_path, r.description);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE component_type
					   SET handler_class = r.handler_class,
						   handler_pkg = r.handler_pkg,
						   node_js_path = r.node_js_path,
						   description = r.description
					 WHERE app_sid = a.app_sid
					   AND component_type_id = r.type_id;
			END;
			
		END LOOP;
	
	END LOOP;

END;
/

ALTER TABLE COMPONENT_TYPE MODIFY (
	HANDLER_CLASS NOT NULL,
	HANDLER_PKG   NOT NULL,
	NODE_JS_PATH  NOT NULL
);

update chain.version set db_version = 15 where part = 'rap4';
update chain.version set db_version = 54 where part = 'trunk';
