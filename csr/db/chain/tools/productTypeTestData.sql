PROMPT >> 
PROMPT >> Host name (e.g. m.credit360.com):
PROMPT >> 

DECLARE
	v_app_sid 				security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID;

	v_pc_container_sid		security.security_pkg.T_SID_ID;
	v_a_product_type_id 	chain.product_type.product_type_id%TYPE;
	v_c_product_type_id 	chain.product_type.product_type_id%TYPE;
	v_f_product_type_id 	chain.product_type.product_type_id%TYPE;
	
	
	PROCEDURE create_product_roots(
		out_a_product_type_id			OUT	chain.product_type.product_type_id%TYPE,
		out_c_product_type_id			OUT	chain.product_type.product_type_id%TYPE,
		out_f_product_type_id			OUT	chain.product_type.product_type_id%TYPE
	)
	AS
		v_root_product_type_id			chain.product_type.product_type_id%TYPE;
	BEGIN
		-- Create the root of roots.
		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  NULL,
				in_description				=>	'Product Types',
				in_node_type				=>	1,
				out_product_type_id			=>	v_root_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN SELECT product_type_id 
				   INTO out_a_product_type_id
				   FROM chain.v$product_type
				  WHERE parent_product_type_id IS NULL
					AND description = 'Product Types';
		END;

		-- Create some root Product_Types
		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_root_product_type_id,
				in_description				=>	'Ambient',
				in_node_type				=>	1,
				out_product_type_id			=>	out_a_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN SELECT product_type_id 
				   INTO out_a_product_type_id
				   FROM chain.v$product_type
				  WHERE parent_product_type_id = v_root_product_type_id
					AND description = 'Ambient';
		END;

		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_root_product_type_id,
				in_description				=>	'Chilled',
				in_node_type				=>	1,
				out_product_type_id			=>	out_c_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN SELECT product_type_id 
				   INTO out_c_product_type_id
				   FROM chain.v$product_type
				  WHERE parent_product_type_id = v_root_product_type_id
					AND description = 'Chilled';
		END;
		
		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_root_product_type_id,
				in_description				=>	'Frozen',
				in_node_type				=>	1,
				out_product_type_id			=>	out_f_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN SELECT product_type_id 
				   INTO out_f_product_type_id
				   FROM chain.v$product_type
				  WHERE parent_product_type_id = v_root_product_type_id
					AND description = 'Frozen';
		END;
	END;

	PROCEDURE create_translation(
		in_product_type_id		IN	chain.product_type.product_type_id%TYPE,
		in_description			IN	chain.product_type_tr.description%TYPE,
		in_lang					IN	chain.product_type_tr.lang%TYPE
	)
	AS
		v_app_sid 	security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	BEGIN
		UPDATE chain.product_type_tr 
		   SET description = in_description
		 WHERE app_sid = v_app_sid
		   AND product_type_id = in_product_type_id
		   AND lang = in_lang;
	END;
	
	PROCEDURE create_product_data(
		in_a_product_type_id			IN	chain.product_type.product_type_id%TYPE,
		in_c_product_type_id			IN	chain.product_type.product_type_id%TYPE,
		in_f_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id2 	chain.product_type.product_type_id%TYPE;
	BEGIN
		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_a_product_type_id,
				in_description				=>	'Tinned goods',
				in_node_type				=> 1,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			create_translation(v_tmp_product_type_id, 'Tinned goods (es)', 'es');
		
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_tmp_product_type_id,
				in_description				=>	'Baked Beanz',
				out_product_type_id			=>	v_tmp_product_type_id2
			);
			create_translation(v_tmp_product_type_id2, 'Baked Beanz (es)', 'es');

			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_tmp_product_type_id,
				in_description				=>	'Tinned Toms',
				out_product_type_id			=>	v_tmp_product_type_id2
			);
			create_translation(v_tmp_product_type_id2, 'Tinned Toms (es)', 'es');

			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_tmp_product_type_id,
				in_description				=>	'Sweetcorn',
				out_product_type_id			=>	v_tmp_product_type_id2
			);
			create_translation(v_tmp_product_type_id2, 'Sweetcorn (es)', 'es');

		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN NULL;
		END;

		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_c_product_type_id,
				in_description				=>	'Butter',
				in_node_type				=>	1,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_c_product_type_id,
				in_description				=>	'Milk',
				in_node_type				=>	1,
				out_product_type_id			=>	v_product_type_id
			);
			-- Actual Products
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_product_type_id,
				in_description				=>	'Whole',
				in_lookup_key				=>	'MILK001_' || v_product_type_id,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_product_type_id,
				in_description				=>	'Semi-skimmed',
				in_lookup_key				=>	'MILK002_' || v_product_type_id,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_product_type_id,
				in_description				=>	'Skimmed',
				in_lookup_key				=>	'MILK003_' || v_product_type_id,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_product_type_id,
				in_description				=>	'Soya',
				in_lookup_key				=>	'MILK004_' || v_product_type_id,
				in_active					=>	0,
				out_product_type_id			=>	v_tmp_product_type_id
			);
			-- Another subtree
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_product_type_id,
				in_description				=>	'Alternatives',
				in_node_type				=>	1,
				out_product_type_id			=>	v_tmp_product_type_id2
			);
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_tmp_product_type_id2,
				in_description				=>	'Rice Milk',
				out_product_type_id			=>	v_tmp_product_type_id
			);
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  v_tmp_product_type_id2,
				in_description				=>	'Coconut Milk',
				out_product_type_id			=>	v_tmp_product_type_id
			);
			
			
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_c_product_type_id,
				in_description				=>	'Yogurt',
				in_node_type				=>	1,
				out_product_type_id			=>	v_tmp_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN NULL;
		END;
	END;
	
	PROCEDURE test_delete(
		in_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_deltest_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  in_product_type_id,
			in_description				=>	'Duck Eggs',
			out_product_type_id			=>	v_product_type_id
		);
		chain.product_type_pkg.DeleteProductType(
			in_product_type_id	=>  v_product_type_id
		);

		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  in_product_type_id,
			in_description				=>	'Eggs',
			in_node_type				=>	1,
			out_product_type_id			=>	v_product_type_id
		);
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  v_product_type_id,
			in_description				=>	'Duck Eggs',
			in_node_type				=>	1,
			out_product_type_id			=>	v_deltest_product_type_id
		);
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  v_deltest_product_type_id,
			in_description				=>	'Mallard Eggs',
			in_node_type				=>	1,
			out_product_type_id			=>	v_tmp_product_type_id
		);
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  v_product_type_id,
			in_description				=>	'Big Eggs',
			out_product_type_id			=>	v_tmp_product_type_id
		);
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  v_product_type_id,
			in_description				=>	'Small Eggs',
			out_product_type_id			=>	v_tmp_product_type_id
		);
		
		chain.product_type_pkg.DeleteProductType(
			in_product_type_id	=>  v_deltest_product_type_id
		);
	END;

	PROCEDURE test_rename(
		in_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		chain.product_type_pkg.RenameProductType(
			in_product_type_id	=>  in_product_type_id,
			in_description => 'Chiller'
		);
	END;

	PROCEDURE test_move(
		in_a_product_type_id			IN	chain.product_type.product_type_id%TYPE,
		in_c_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  in_a_product_type_id,
			in_description				=>	'Almond',
			in_lookup_key				=>	'MILK005_' || in_a_product_type_id,
			in_active					=>	1,
			out_product_type_id			=>	v_product_type_id
		);
		chain.product_type_pkg.MoveProductType(
			in_product_type_id	=>  v_product_type_id,
			in_new_parent_id => in_c_product_type_id
		);
		
		SELECT product_type_id
		  INTO v_tmp_product_type_id
		  FROM chain.v$product_type
		 WHERE description = 'Milk'
		   AND node_type = 1
		   AND parent_product_type_id = in_c_product_type_id;
		
		chain.product_type_pkg.MoveProductType(
			in_product_type_id	=>  v_product_type_id,
			in_new_parent_id => v_tmp_product_type_id
		);
	END;

	PROCEDURE test_activation(
		in_c_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		SELECT product_type_id
		  INTO v_product_type_id
		  FROM chain.v$product_type
		 WHERE description = 'Soya'
		   AND node_type = 0;

		
		chain.product_type_pkg.ActivateProductType(
			in_product_type_id	=>  v_product_type_id
		);

		SELECT product_type_id
		  INTO v_product_type_id
		  FROM chain.v$product_type
		 WHERE description = 'Almond'
		   AND node_type = 0;

	   chain.product_type_pkg.DeactivateProductType(
			in_product_type_id	=>  v_product_type_id
		);
	END;


	PROCEDURE test_amend(
		in_c_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		SELECT product_type_id
		  INTO v_product_type_id
		  FROM chain.v$product_type
		 WHERE description = 'Soya'
		   AND node_type = 0;

	   chain.product_type_pkg.AmendProductType(
			in_product_type_id	=>  v_product_type_id,
			in_description	=>  'Soya Milk',
			in_lookup_key	=>  'SOYA001_' || v_product_type_id,
			in_node_type	=>  0,
			in_active	=> 1
		);
	END;

	PROCEDURE test_add_more_products(
		in_a_product_type_id			IN	chain.product_type.product_type_id%TYPE,
		in_c_product_type_id			IN	chain.product_type.product_type_id%TYPE,
		in_f_product_type_id			IN	chain.product_type.product_type_id%TYPE
	)
	AS
		v_product_type_id 	chain.product_type.product_type_id%TYPE;
		v_tmp_product_type_id 	chain.product_type.product_type_id%TYPE;
	BEGIN
		BEGIN
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_a_product_type_id,
				in_description				=>	'Spaghetti Hoops',
				out_product_type_id			=>	v_tmp_product_type_id
			);

			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_c_product_type_id,
				in_description				=>	'Eggs',
				in_node_type				=>	1,
				out_product_type_id			=>	v_tmp_product_type_id
			);

			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_f_product_type_id,
				in_description				=>	'Vanilla Ice-cream',
				out_product_type_id			=>	v_tmp_product_type_id
			);
			
			chain.product_type_pkg.AddProductType(
				in_parent_product_type_id	=>  in_f_product_type_id,
				in_description				=>	'Fish',
				in_node_type				=>	1,
				out_product_type_id			=>	v_tmp_product_type_id
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN NULL;
		END;
	END;
	
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Script to generate some hardcoded test data.
	
	/*-- Create a Product_Compliance container; we don't need one but it's commented out for now, in case we do later.
	-- Inherit ACLs from the parent.
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id,
			v_app_sid,
			security.security_pkg.SO_CONTAINER,
			'Product Compliance',
			v_pc_container_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_pc_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Product Compliance');
	END;*/

	create_product_roots(v_a_product_type_id, v_c_product_type_id, v_f_product_type_id);
	
	create_product_data(v_a_product_type_id, v_c_product_type_id, v_f_product_type_id);
	
	test_delete(v_a_product_type_id);
	
	test_rename(v_c_product_type_id);
	
	test_move(v_a_product_type_id, v_c_product_type_id);
	
	test_activation(v_c_product_type_id);
	
	test_amend(v_c_product_type_id);
	
	test_add_more_products(v_a_product_type_id, v_c_product_type_id, v_f_product_type_id);
END;
/

commit;
exit
