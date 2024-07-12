-- Please update version.sql too -- this keeps clean builds in sync
define version=2262
@update_header

ALTER TABLE chain.product_type ADD (
	lookup_key				VARCHAR2(255)
);

CREATE UNIQUE INDEX chain.product_type_lookup ON chain.product_type(app_sid, NVL2(lookup_key, lookup_key, product_type_id));

ALTER TABLE csrimp.chain_product_type ADD (
	lookup_key				VARCHAR2(255)
);

@..\chain\product_pkg

@..\chain\product_body
@..\csrimp\imp_body
@..\schema_body

@update_tail
