-- Please update version.sql too -- this keeps clean builds in sync
 define version=2173
 @update_header

DECLARE
	v_plugin_type_id	  csr.plugin.plugin_type_id%TYPE := 10;
	v_js_class			  csr.plugin.js_class%TYPE := 'Chain.ManageCompany.SupplierList';
	v_description		  csr.plugin.description%TYPE := 'List of suppliers';
	v_js_include		  csr.plugin.js_include%TYPE := '/csr/site/chain/manageCompany/controls/SupplierList.js';
	v_cs_class			  csr.plugin.cs_class%TYPE := 'Credit360.Chain.Plugins.SupplierListDto';
BEGIN
	BEGIN		
		INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (10, 'Chain Company Tab');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN		
		INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (11, 'Chain Company Header');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
		 VALUES (csr.plugin_id_seq.nextval, v_plugin_type_id, v_description,  v_js_include, v_js_class, v_cs_class);
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin 
		   SET description = v_description,
		   	js_include = v_js_include,
		   	cs_class = v_cs_class
		 WHERE plugin_type_id = v_plugin_type_id
		   AND js_class = v_js_class;
END;
/

@update_tail