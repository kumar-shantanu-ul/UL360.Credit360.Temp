define rap4_version=8
@update_header

-- 
-- TABLE: COMPONENT_SOURCE 
--

CREATE TABLE COMPONENT_SOURCE(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_TYPE_ID     NUMBER(10, 0)     NOT NULL,
    PROGRESSION_ACTION    VARCHAR2(100)     NOT NULL,
    CARD_TEXT             VARCHAR2(2000)    NOT NULL,
    DESCRIPTION_XML       VARCHAR2(4000),
    POSITION              NUMBER(10, 0)     NOT NULL
)
;

-- 
-- TABLE: COMPONENT_SOURCE 
--

ALTER TABLE COMPONENT_SOURCE ADD CONSTRAINT RefCOMPONENT_TYPE528 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

DELETE FROM card_group_progression
 WHERE from_card_id IN (SELECT card_id FROM card WHERE js_class_type = 'Chain.Cards.ComponentBuilder.ComponentSource');

UPDATE card_group
   SET name = 'Product Builder',
       description = 'Used to build the component tree from the base component'
 WHERE card_group_id = 12;

@..\..\card_pkg
@..\..\component_pkg

@..\..\card_body
@..\..\component_body

-- register component cards
BEGIN
	
	user_pkg.LogonAdmin;	
	
	card_pkg.DestroyCard('Chain.Cards.ComponentBuilder.RawMaterial');
	
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

	/*** COMPONENT BUILDER - ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Chain.Cards.AddComponent extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.AddComponent',
		'/csr/site/chain/cards/componentBuilder/addComponent.js', 
		'Chain.Cards.ComponentBuilder.AddComponent',
		T_STRING_LIST('existing', 'new', 'newpurchased')
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
		'You are dumb as rocks, how can you not know where your components come from?', 
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
END;
/



PROMPT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PROMPT >> You will now need to udpate rfa db
PROMPT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


@update_tail