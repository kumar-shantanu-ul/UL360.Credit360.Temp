define rap4_version=6
@update_header

-- create a temporary table for product/component pairing
CREATE GLOBAL TEMPORARY TABLE TT_PRODUCT_MAPPING_SEARCH
(
	COMPONENT_ID				NUMBER(10) NOT NULL,
	COMPONENT_DESCRIPTION		VARCHAR2(500),
	PRODUCT_ID					NUMBER(10) NOT NULL,
	PRODUCT_DESCRIPTION			VARCHAR2(500),
	MAPPED						NUMBER(1) NOT NULL,
	REJECTED					NUMBER(1) NOT NULL,
	CODE_LABEL1 				VARCHAR2(100),
	CODE1						VARCHAR2(100), 
	CODE_LABEL2					VARCHAR2(100), 
	CODE2						VARCHAR2(100),
	CODE_LABEL3					VARCHAR2(100), 
	CODE3						VARCHAR2(100),
	POSITION					NUMBER(10)
)
ON COMMIT PRESERVE ROWS;

-- add a component code column
ALTER TABLE COMPONENT ADD (
    COMPONENT_CODE       VARCHAR2(100)
);

-- recreate component views
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


-- register component cards
BEGIN
	user_pkg.logonadmin;
	
	/*** ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Add component card that first prompts you to search for an existing component and then allows you to create a new one if you wish.', 
		'Credit360.Chain.Cards.AddComponent',
		'/csr/site/chain/cards/addComponent.js', 
		'Chain.Cards.AddComponent'
	);

	/*** EDIT COMPONENT ***/
	card_pkg.RegisterCard(
		'Edit a component''s details.', 
		'Credit360.Chain.Cards.EditComponent',
		'/csr/site/chain/cards/editComponent.js', 
		'Chain.Cards.EditComponent'
	);
END;
/

-- rebuild packages
@..\..\component_pkg
@..\..\cmpnt_prod_relationship_body
@..\..\component_body

@update_tail