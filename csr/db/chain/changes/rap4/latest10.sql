define rap4_version=10
@update_header


UPDATE CHAIN.COMPONENT_TYPE
SET    
       DESCRIPTION       = 'Root Product Component',
       HANDLER_CLASS     = 'Credit360.Chain.Products.RootComponent',
       HANDLER_PKG       = 'chain.component_pkg',
       NODE_JS_PATH      = '/csr/site/chain/components/products/ComponentNode.js'
WHERE  COMPONENT_TYPE_ID = 1;


@update_tail