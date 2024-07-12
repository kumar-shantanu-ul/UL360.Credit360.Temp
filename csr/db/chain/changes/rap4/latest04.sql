define rap4_version=4
@update_header


ALTER TABLE CMPNT_CMPNT_RELATIONSHIP ADD (
	POSITION NUMBER(10)
);

BEGIN
	UPDATE component_type SET handler_class = 'Credit360.Chain.Products.DefaultComponent' WHERE component_type_id = 1;
	UPDATE component_type SET handler_class = 'Credit360.Chain.Products.LogicalComponent' WHERE component_type_id = 2;
	UPDATE component_type SET handler_class = 'Credit360.Chain.Products.PurchasedComponent' WHERE component_type_id = 3;
	UPDATE component_type SET handler_class = 'Credit360.Chain.Products.WoodComponent' WHERE component_type_id = 50;
END;
/


@..\..\product_pkg
@..\..\cmpnt_prod_relationship_pkg
@..\..\cmpnt_cmpnt_relationship_pkg

@..\..\product_body
@..\..\cmpnt_prod_relationship_body
@..\..\cmpnt_cmpnt_relationship_body


@update_tail