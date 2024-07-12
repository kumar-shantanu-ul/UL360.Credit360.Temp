define rap4_version=3
@update_header


ALTER TABLE COMPONENT_TYPE ADD (
        HANDLER_CLASS        VARCHAR2(255),
	    HANDLER_PKG          VARCHAR2(255),
	    NODE_JS_PATH         VARCHAR2(255)
);


BEGIN
	-- move the wood class to the correct type_id
	UPDATE component_type
	   SET component_type_id = 50 
	 WHERE component_type_id = 3
	   AND description = 'Wood';
	
	FOR a IN (
		SELECT app_sid FROM customer_options
	) LOOP
	
		FOR r IN (
			SELECT 	1 type_id, 'Common' description, 'Credit360.Chain.Component.Common' handler_class, 'chain.component_pkg' handler_pkg,  '/csr/site/chain/components/products/ComponentNode.js' node_js_path FROM DUAL
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

	FOR a IN (
		SELECT app_sid FROM customer_options WHERE chain_implementation = 'RFA'
	) LOOP
	
		FOR r IN (
			SELECT 	50 type_id, 'Rainforest Alliance Wood' description, 'Credit360.Chain.Component.Wood' handler_class, 'chain.component_pkg' handler_pkg,  '/csr/site/chain/components/products/ComponentNode.js' node_js_path FROM DUAL
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


@..\..\product_pkg
@..\..\component_pkg

@..\..\product_body
@..\..\component_body

@update_tail