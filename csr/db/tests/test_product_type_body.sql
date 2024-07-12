CREATE OR REPLACE PACKAGE BODY csr.test_product_type_pkg AS

v_site_name		VARCHAR2(200);
m_root_product_type_id	chain.product_type.product_type_id%TYPE;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_primary_root_sid				security.security_pkg.T_SID_ID;
	v_cust_comp_sid					security.security_pkg.T_SID_ID;
	v_xml							CLOB;
	v_str 							VARCHAR2(2000);
	v_r0 							security.security_pkg.T_SID_ID;
	v_s0							security.security_pkg.T_SID_ID;
	v_s1							security.security_pkg.T_SID_ID;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	chain.test_chain_utils_pkg.SetupSingleTier;
END;

PROCEDURE SetUp AS
	v_company_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> NULL,
		in_description				=> 'TestProductTypeRoot',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_FOLDER,
		out_product_type_id			=> m_root_product_type_id
	);
END;

PROCEDURE TearDown AS
BEGIN
	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	m_root_product_type_id
	);
END;

PROCEDURE TearDownFixture AS
BEGIN 
	chain.test_chain_utils_pkg.TearDownSingleTier;
END;

PROCEDURE TestAddDeleteProductType AS
	v_id			chain.product_type.product_type_id%TYPE;
	v_count			NUMBER;
	v_count_tr		NUMBER;
BEGIN
	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> m_root_product_type_id,
		in_description				=> 'TestProductType',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_LEAF,
		out_product_type_id			=> v_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.product_type
	 WHERE product_type_id = v_id;
	
	SELECT COUNT(*)
	  INTO v_count_tr
	  FROM chain.product_type_tr
	 WHERE product_type_id = v_id;
	
	unit_test_pkg.AssertIsTrue(1 = v_count, 'Expected count');
	unit_test_pkg.AssertIsTrue(1 = v_count_tr, 'Expected count tr');

	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	v_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.product_type
	 WHERE product_type_id != m_root_product_type_id;
	
	unit_test_pkg.AssertIsTrue(0 = v_count, 'Expected count');
END;

PROCEDURE TestRenameProductType AS
	v_id			chain.product_type.product_type_id%TYPE;
	v_count			NUMBER;
	v_desc			chain.product_type_tr.description%TYPE;
BEGIN
	
	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> m_root_product_type_id,
		in_description				=> 'TestProductType',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_LEAF,
		out_product_type_id			=> v_id
	);

	chain.product_type_pkg.RenameProductType(
		in_product_type_id	=>	v_id,
		in_description		=>	'TestProductTypeRenamed'
	);

	SELECT description
	  INTO v_desc
	  FROM chain.v$product_type
	 WHERE product_type_id = v_id;
	
	unit_test_pkg.AssertIsTrue(v_desc = 'TestProductTypeRenamed', 'Expected description');

	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	v_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.product_type
	 WHERE product_type_id != m_root_product_type_id;
	
	unit_test_pkg.AssertIsTrue(0 = v_count, 'Expected count');
END;

PROCEDURE TestMoveProductType AS
	v_id			chain.product_type.product_type_id%TYPE;
	v_id2			chain.product_type.product_type_id%TYPE;
	v_id_move		chain.product_type.product_type_id%TYPE;
	v_count			NUMBER;
	v_par			chain.product_type.parent_product_type_id%TYPE;
BEGIN
	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> m_root_product_type_id,
		in_description				=> 'TestProductType',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_FOLDER,
		out_product_type_id			=> v_id
	);

	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> m_root_product_type_id,
		in_description				=> 'TestProductType2',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_FOLDER,
		out_product_type_id			=> v_id2
	);

	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> v_id,
		in_description				=> 'TestProductTypeMove',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_LEAF,
		out_product_type_id			=> v_id_move
	);

	chain.product_type_pkg.MoveProductType(
		in_product_type_id	=>	v_id_move,
		in_new_parent_id	=>	v_id2
	);

	SELECT parent_product_type_id
	  INTO v_par
	  FROM chain.product_type
	 WHERE product_type_id = v_id_move;
	
	unit_test_pkg.AssertIsTrue(v_par = v_id2, 'Expected parent');

	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	v_id
	);

	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	v_id2
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.product_type
	 WHERE product_type_id != m_root_product_type_id;
	
	unit_test_pkg.AssertIsTrue(0 = v_count, 'Expected count');
END;

PROCEDURE TestActivateDeactivate AS
	v_id			chain.product_type.product_type_id%TYPE;
	v_active		NUMBER;
	v_count			NUMBER;
BEGIN
	chain.product_type_pkg.AddProductType(
		in_parent_product_type_id	=> m_root_product_type_id,
		in_description				=> 'TestProductType',
		in_node_type				=> chain.product_type_pkg.PRODUCT_TYPE_LEAF,
		in_active					=> 0,
		out_product_type_id			=> v_id
	);

	chain.product_type_pkg.ActivateProductType(
		in_product_type_id	=>	v_id
	);

	SELECT active
	  INTO v_active
	  FROM chain.v$product_type
	 WHERE product_type_id = v_id;
	
	unit_test_pkg.AssertIsTrue(1 = v_active, 'Expected active');

	chain.product_type_pkg.DeactivateProductType(
		in_product_type_id	=>	v_id
	);

	SELECT active
	  INTO v_active
	  FROM chain.v$product_type
	 WHERE product_type_id = v_id;
	
	unit_test_pkg.AssertIsTrue(0 = v_active, 'Expected inactive');

	chain.product_type_pkg.DeleteProductType(
		in_product_type_id	=>	v_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.product_type
	 WHERE product_type_id != m_root_product_type_id;
	
	unit_test_pkg.AssertIsTrue(0 = v_count, 'Expected count');
END;

END test_product_type_pkg;
/
