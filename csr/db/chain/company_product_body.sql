CREATE OR REPLACE PACKAGE BODY CHAIN.company_product_pkg
IS

/* PERMISSION ASSERTIONS */
PROCEDURE AssertCanCreateCompanyProduct(
	in_company_sid				IN	chain.company_product.company_sid%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF v_company_sid = in_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.CREATE_PRODUCTS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Create products access denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.CREATE_PRODUCTS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Create products on company '||in_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;
END;

PROCEDURE AssertCanDeleteCompanyProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_owner_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	-- Create access also gives you delete, so you can correct your own mistakes.
	AssertCanCreateCompanyProduct(in_company_sid => v_owner_company_sid);
END;

PROCEDURE AssertCanViewCompanyProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_as_supplier				IN	NUMBER
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_product_supplier_cnt		NUMBER;
BEGIN
	BEGIN
		SELECT company_sid
		  INTO v_owner_company_sid
		  FROM company_product
		 WHERE product_id = in_product_id;
	 
		IF v_company_sid = v_owner_company_sid THEN
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
				RETURN;
			END IF;
		ELSE
			IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
				RETURN;
			END IF;
		END IF;
		
		IF in_as_supplier = 1 THEN
			SELECT count(*)
			  INTO v_product_supplier_cnt
			  FROM product_supplier
			 WHERE product_id = in_product_id
			   AND supplier_company_sid =  v_company_sid;

			IF v_product_supplier_cnt > 0 AND type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
				RETURN;
			END IF;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read products access denied on product '||in_product_id);
END;

PROCEDURE AssertCanEditCompanyProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_owner_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;
	 
	IF v_company_sid = v_owner_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Edit products access denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Edit products on company '||v_owner_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;
END;

PROCEDURE AssertCanAddProductSupplier(
	in_purchaser_company_sid	IN	chain.product_supplier.purchaser_company_sid%TYPE,
	in_supplier_company_sid		IN	chain.product_supplier.supplier_company_sid%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF v_company_sid = in_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_supplier_company_sid, chain_pkg.ADD_PRODUCT_SUPPLIER) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Add product supplier on company '||in_supplier_company_sid||' access denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_purchaser_company_sid, in_supplier_company_sid, chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Add product supplier on companies '||in_purchaser_company_sid||' and '||in_supplier_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;
END;

PROCEDURE AssertCanViewProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id				chain.product_supplier.product_id%TYPE;
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	
	IF v_company_sid = v_supplier_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	ELSIF v_company_sid = v_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_purchaser_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	END IF;
END;

PROCEDURE AssertCanEditProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id				chain.product_supplier.product_id%TYPE;
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	
	IF v_company_sid = v_supplier_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	ELSIF v_company_sid = v_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_purchaser_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	END IF;
END;

PROCEDURE AssertCanManageProdCertReqs(
	in_product_id				IN	chain.company_product.product_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid			security_pkg.T_SID_ID;
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 0);

	SELECT company_sid
	  INTO v_owner_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	IF v_company_sid = v_owner_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.MANAGE_PRODUCT_CERT_REQS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Manage product certification requirements denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.MANAGE_PRODUCT_CERT_REQS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Manage product certification requirements on company '||v_owner_company_sid||' denied to company '||v_company_sid);
		END IF;
	END IF;
END;

PROCEDURE AssertCanViewProductCerts(
	in_product_id				IN	chain.company_product.product_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_product_supplier_cnt		NUMBER;
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 0);

	BEGIN
		SELECT company_sid
		  INTO v_owner_company_sid
		  FROM company_product
		 WHERE product_id = in_product_id;
	 
		IF v_company_sid = v_owner_company_sid THEN
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ) THEN
				RETURN;
			END IF;
		ELSE
			IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ) THEN
				RETURN;
			END IF;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read product certifications access denied on product '||in_product_id);
END;

PROCEDURE AssertCanEditProductCerts(
	in_product_id				IN	chain.company_product.product_id%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_product_supplier_cnt		NUMBER;
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 0);

	BEGIN
		SELECT company_sid
		  INTO v_owner_company_sid
		  FROM company_product
		 WHERE product_id = in_product_id;
	 
		IF v_company_sid = v_owner_company_sid THEN
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_WRITE) THEN
				RETURN;
			END IF;
		ELSE
			IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_WRITE) THEN
				RETURN;
			END IF;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read product certifications access denied on product '||in_product_id);
END;

PROCEDURE AssertCanEditProdSuppCerts(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id				chain.product_supplier.product_id%TYPE;
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	AssertCanViewProductSupplier(in_product_supplier_id => in_product_supplier_id);

	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	IF v_company_sid = v_purchaser_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, v_purchaser_company_sid, v_supplier_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to product supplier '||in_product_supplier_id);
		END IF;
	END IF;
END;

/* END PERMISIONS */

PROCEDURE UNSEC_GetProductIdFromRef (
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
)
AS
	v_product_id			NUMBER;
BEGIN
	BEGIN
		SELECT product_id
		  INTO v_product_id
		  FROM company_product
		 WHERE company_sid = in_company_sid
		   AND LOWER(product_ref) = LOWER(in_product_ref);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_product_id := NULL;
	END;

	out_product_id := v_product_id;
END;

PROCEDURE SearchOwnerCompanies(
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_sids					security.T_SID_TABLE;
BEGIN
	v_company_sids := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.CREATE_PRODUCTS);
	
	-- GetPermissibleCompanySids only got us the suppliers	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.CREATE_PRODUCTS) THEN
		v_company_sids.extend;
		v_company_sids(v_company_sids.COUNT) := v_company_sid;
	END IF;
	
	OPEN out_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company c
		  JOIN TABLE(v_company_sids) t ON t.column_value = c.company_sid
		 GROUP BY c.company_sid, c.name
		 ORDER BY c.name;
END;

PROCEDURE UNSEC_TryGetIdFromProductRef (
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
)
AS
	v_product_id	NUMBER;
BEGIN
	UNSEC_GetProductIdFromRef(in_company_sid, in_product_ref, v_product_id);
	IF v_product_id IS NULL THEN
		v_product_id := -1;
	END IF;

	out_product_id := v_product_id;
END;

PROCEDURE UNSEC_TryGetIdFromLookupKey(
	in_lookup_key	IN company_product.lookup_key%TYPE,
	in_company_sid	IN company_product.company_sid%TYPE,
	out_product_id	OUT company_product.product_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT product_id INTO out_product_id
		  FROM company_product
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND LOWER(lookup_key) = LOWER(in_lookup_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_product_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_product_id := -1;
	END;
END;

PROCEDURE UNSEC_TryGetIdFromDescription(
	in_description	IN company_product_tr.description%TYPE,
	in_company_sid	IN company_product.company_sid%TYPE,
	out_product_id	OUT company_product.product_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT p.product_id INTO out_product_id
		  FROM company_product p
		  JOIN company_product_tr t ON p.product_id = t.product_id
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = in_company_sid
		   AND LOWER(t.description) = LOWER(in_description)
		 GROUP BY p.company_sid, p.product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_product_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_product_id := -1;
	END;
END;

PROCEDURE UNSEC_SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
)
AS
	v_product_id			NUMBER;
	v_current_name			chain.company_product_tr.description%TYPE;
BEGIN
	IF in_product_id IS NULL THEN
		-- Create the base product
		v_product_id := product_id_seq.NEXTVAL;
	
		INSERT INTO chain.product (product_id) VALUES (v_product_id);
		
		-- Add the company product details
		INSERT INTO chain.company_product
			(product_id, company_sid, product_type_id, lookup_key, product_ref, is_active)
		VALUES
			(v_product_id, in_company_sid, in_product_type_id, in_lookup_key, in_product_ref, 1);
		
		-- Translations
		FOR r IN (
			SELECT lang
				FROM csr.v$customer_lang
		)
		LOOP
			INSERT INTO chain.company_product_tr
				(product_id, lang, description)
			VALUES
				(v_product_id, r.lang, in_name);
		END LOOP;
	
		out_product_id := v_product_id;

		product_metric_pkg.UNSEC_PropagateProductMetrics(out_product_id);

		chain_link_pkg.CompanyProductCreated(out_product_id);

		csr.csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
			in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
			in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
			in_object_sid		=>	v_product_id,
			in_description		=>	'Product {0} created', 
			in_param_1			=>	v_product_id
		);

	ELSE
		UPDATE chain.company_product
		   SET product_type_id = in_product_type_id,
			   lookup_key = in_lookup_key,
			   product_ref = in_product_ref
		 WHERE product_id = in_product_id;
	
		SELECT product_name
		  INTO v_current_name
		  FROM chain.v$company_product
		 WHERE product_id = in_product_id;

		UPDATE chain.company_product_tr
		   SET description = in_name
		 WHERE product_id = in_product_id
		   AND description =v_current_name;

		out_product_id := in_product_id;

		product_metric_pkg.UNSEC_PropagateProductMetrics(out_product_id);
		
		chain_link_pkg.CompanyProductUpdated(out_product_id);

		csr.csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
			in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
			in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
			in_object_sid		=>	in_product_id,
			in_description		=>	'Product {0} updated', 
			in_param_1			=>	in_product_id
		);

	END IF;
END;

PROCEDURE SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
)
AS
BEGIN
	IF in_product_id IS NULL THEN
		AssertCanCreateCompanyProduct(in_company_sid => in_company_sid);
	ELSE
		AssertCanEditCompanyProduct(in_product_id => in_product_id);
	END IF;

	UNSEC_SaveCompanyProduct(
		in_product_id		=>	in_product_id,
		in_company_sid		=>	in_company_sid,
		in_product_type_id	=>	in_product_type_id,
		in_product_ref		=>	in_product_ref,
		in_lookup_key		=>	in_lookup_key,
		in_name				=>	in_name,
		out_product_id		=>	out_product_id
	);
END;

PROCEDURE SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	in_is_active			IN	chain.company_product.is_active%TYPE,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_desc_languages		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_product_id			OUT	chain.company_product.product_id%TYPE
)
AS
BEGIN
	SaveCompanyProduct(
		in_product_id		=>	in_product_id,
		in_company_sid		=>	in_company_sid,
		in_product_type_id	=>	in_product_type_id,
		in_product_ref		=>	in_product_ref,
		in_lookup_key		=>	in_lookup_key,
		in_name				=>	in_name,
		out_product_id		=>	out_product_id
	);

	IF in_is_active = 0 THEN
		DeactivateCompanyProduct(out_product_id);
	ELSE
		ReactivateCompanyProduct(out_product_id);
	END IF;
	
	FOR i IN 1..in_descriptions.COUNT
	LOOP
		SetTranslation(out_product_id, in_desc_languages(i), in_descriptions(i));
	END LOOP;
END;

PROCEDURE SaveCompanyProductTags(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_tag_group_id			IN	csr.tag_group.tag_group_id%TYPE,
	in_tag_ids				IN	security.security_pkg.T_SID_IDS
)
AS
	v_tag_ids_tbl			security.T_SID_TABLE;
BEGIN
	AssertCanEditCompanyProduct(in_product_id => in_product_id);

	-- crap hack for ODP.NET
	IF in_tag_ids IS NULL OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_tag_ids_tbl := security.T_SID_TABLE();
	ELSE
		v_tag_ids_tbl := security_pkg.SidArrayToTable(in_tag_ids);
	END IF;

	DELETE FROM company_product_tag
	 WHERE product_id = in_product_id
	   AND tag_group_id = in_tag_group_id;

	INSERT INTO company_product_tag (product_id, tag_group_id, tag_id)
	SELECT in_product_id, in_tag_group_id, column_value FROM TABLE(v_tag_ids_tbl);
END;

PROCEDURE DeleteCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
)
AS
BEGIN
	AssertCanDeleteCompanyProduct(in_product_id => in_product_id);

	chain_link_pkg.DeletingCompanyProduct(in_product_id);

	-- we first mark it as inactive so that we can propagate metrics correctly before it goes
	UPDATE chain.company_product
	   SET is_active = 0
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	product_metric_pkg.UNSEC_PropagateProductMetrics(in_product_id);

	DELETE FROM chain.product_metric_val
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');	 

	DELETE FROM chain.company_product_tr
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	DELETE FROM chain.company_product
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	DELETE FROM chain.product
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	chain_link_pkg.CompanyProductDeleted(in_product_id);

	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Product {0} deleted', 
		in_param_1			=>	in_product_id
	);
END;

PROCEDURE DeactivateCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
)
AS
	v_current_status		NUMBER;
BEGIN
	AssertCanEditCompanyProduct(in_product_id => in_product_id);
	
	SELECT is_active
	  INTO v_current_status
	  FROM company_product
	 WHERE product_id = in_product_id;
	
	-- If already inactive, don't do anything.
	IF v_current_status = 0 THEN
		RETURN;
	END IF;
	
	UPDATE chain.company_product
	   SET is_active = 0
	 WHERE product_id = in_product_id;
	 
	product_metric_pkg.UNSEC_PropagateProductMetrics(in_product_id);

	chain_link_pkg.CompanyProductDeactivated(in_product_id);
	   
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Product {0} deactivated', 
		in_param_1			=>	in_product_id
	);
END;

PROCEDURE ReactivateCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
)
AS
	v_current_status		NUMBER;
BEGIN
	AssertCanEditCompanyProduct(in_product_id => in_product_id);
	
	SELECT is_active
	  INTO v_current_status
	  FROM company_product
	 WHERE product_id = in_product_id;
	
	-- If already inactive, don't do anything.
	IF v_current_status = 1 THEN
		RETURN;
	END IF;
	
	UPDATE chain.company_product
	   SET is_active = 1
	 WHERE product_id = in_product_id;
	 
	product_metric_pkg.UNSEC_PropagateProductMetrics(in_product_id);

	chain_link_pkg.CompanyProductReactivated(in_product_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Product {0} reactivated', 
		in_param_1			=>	in_product_id
	);
END;

PROCEDURE SaveProductCertRequirement(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_type_id	IN	chain.certification_type.certification_type_id%TYPE,
	in_from_dtm					IN	DATE,
	in_to_dtm					IN	DATE
)
AS
BEGIN
	AssertCanManageProdCertReqs(in_product_id => in_product_id);
	
	BEGIN
		INSERT INTO chain.company_product_required_cert
			(product_id, certification_type_id, from_dtm, to_dtm)
		VALUES
			(in_product_id, in_certification_type_id, NVL(in_from_dtm, SYSDATE), in_to_dtm);	-- TODO; Trim to midnight today
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.company_product_required_cert
			   SET from_dtm = NVL(in_from_dtm, SYSDATE),
			       to_dtm = in_to_dtm
			 WHERE product_id = in_product_id
			   AND certification_type_id = in_certification_type_id;
	END;

	chain_link_pkg.ProductCertReqAdded(in_product_id, in_certification_type_id); 
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Added requirement to product {0} for certification of type {1}', 
		in_param_1			=>	in_product_id,
		in_param_2			=>	in_certification_type_id
	);
END;

PROCEDURE RemoveProductCertRequirement(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_type_id	IN	chain.certification_type.certification_type_id%TYPE
)
AS
BEGIN
	AssertCanManageProdCertReqs(in_product_id => in_product_id);
	
	DELETE FROM chain.company_product_required_cert
	 WHERE product_id = in_product_id
	   AND certification_type_id = in_certification_type_id;

	chain_link_pkg.ProductCertReqRemoved(in_product_id, in_certification_type_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Removed requirement from product {0} for certification of type {1}', 
		in_param_1			=>	in_product_id,
		in_param_2			=>	in_certification_type_id
	);
END;

PROCEDURE AddCertificationToProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_id			IN	chain.company_product_certification.certification_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_company_sid		security_pkg.T_SID_ID;
	v_cert_company_sid		security_pkg.T_SID_ID;
BEGIN
	AssertCanEditProductCerts(in_product_id => in_product_id);
	
	SELECT company_sid INTO v_product_company_sid FROM company_product WHERE product_id = in_product_id;
	SELECT company_sid INTO v_cert_company_sid FROM v$supplier_certification WHERE certification_id = in_certification_id;

	IF v_product_company_sid != v_cert_company_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Product company does not match certification company');
	END IF;

	BEGIN
		INSERT INTO chain.company_product_certification 
			(product_id, certification_id, applied_dtm)
		VALUES
			(in_product_id, in_certification_id, SYSDATE);
	EXCEPTION
		WHEN dup_val_on_index THEN
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'This certification already exists');
	END;

	chain_link_pkg.ProductCertAdded(in_product_id, in_certification_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Added certificate {1} to product {0}', 
		in_param_1			=>	in_product_id,
		in_param_2			=>	in_certification_id
	);

	OPEN out_cur FOR
		SELECT cpc.product_id, cpc.certification_id,
			   ct.certification_type_id, ct.label certification_type_label,
			   sc.valid_from_dtm, sc.expiry_dtm
		  FROM company_product_certification cpc
		  JOIN v$supplier_certification sc ON sc.certification_id = cpc.certification_id
		  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
		 WHERE cpc.product_id = in_product_id
		   AND cpc.certification_id = in_certification_id;
END;

PROCEDURE RemoveCertificationFromProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_id			IN	chain.company_product_certification.certification_id%TYPE
)
AS
BEGIN
	AssertCanEditProductCerts(in_product_id => in_product_id);

	DELETE FROM chain.company_product_certification
	 WHERE product_id = in_product_id
	   AND certification_id = in_certification_id;

	chain_link_pkg.ProductCertRemoved(in_product_id, in_certification_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	'Removed certificate {1} from product {0}', 
		in_param_1			=>	in_product_id,
		in_param_2			=>	in_certification_id
	);
END;

PROCEDURE GetProductCertifications(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertCanViewProductCerts(in_product_id => in_product_id);

	OPEN out_cur FOR
		SELECT cpc.product_id, cpc.certification_id,
			   ct.certification_type_id, ct.label certification_type_label,
			   sc.valid_from_dtm, sc.expiry_dtm
		  FROM company_product_certification cpc
		  JOIN v$supplier_certification sc ON sc.certification_id = cpc.certification_id
		  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
		 WHERE cpc.product_id = in_product_id
		 ORDER BY cpc.certification_id;
END;

/* INTERNALS */

PROCEDURE INTERNAL_PopulateProdCertIds (
	in_product_id				IN	company_product.product_id%TYPE,
	out_product_ids				OUT security.T_SID_TABLE,
	out_cert_type_ids			OUT security.T_SID_TABLE
)
AS
BEGIN
	out_product_ids := security.T_SID_TABLE();
	out_product_ids.EXTEND;
	out_product_ids(1) := in_product_id;

	SELECT certification_type_id
	  BULK COLLECT INTO out_cert_type_ids
	  FROM company_product_required_cert
	 WHERE product_id = in_product_id;
END;

FUNCTION INTERNAL_MergeDateRanges(
	in_tbl						IN	T_OBJECT_CERTIFICATION_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE
AS
	v_tbl						T_OBJECT_CERTIFICATION_TABLE;
	v_distant_future			DATE := TO_DATE('9999-12-31', 'YYYY-MM-DD');
BEGIN
	-- With thanks to https://stewashton.wordpress.com/2014/03/16/merging-contiguous-date-ranges/	
	WITH certs AS (
		SELECT object_id, certification_type_id, from_dtm, NVL(to_dtm, v_distant_future) to_dtm
			FROM TABLE(in_tbl)
			WHERE is_certified = 1
	), cert_group_starts AS (
		SELECT object_id, certification_type_id, from_dtm, to_dtm,
				CASE WHEN from_dtm <= LAG(to_dtm) OVER(PARTITION BY object_id, certification_type_id ORDER BY from_dtm, to_dtm NULLS LAST)
					THEN 0 ELSE 1 END is_group_start
			FROM certs
	), cert_groups AS (
		SELECT object_id, certification_type_id, from_dtm, to_dtm,
			   SUM(is_group_start) OVER(PARTITION BY object_id, certification_type_id ORDER BY from_dtm, to_dtm NULLS LAST) group_num
		  FROM cert_group_starts
	)
	SELECT T_OBJECT_CERTIFICATION_ROW(object_id, certification_type_id, 1, MIN(from_dtm), NULLIF(MAX(to_dtm), v_distant_future))
	  BULK COLLECT INTO v_tbl
	  FROM cert_groups
	 GROUP BY object_id, certification_type_id, group_num;

	RETURN v_tbl;
END;

FUNCTION INTERNAL_GetReqdProductCerts(
	in_product_ids				IN	security.T_SID_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE,
	in_view_cert_company_sids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE
AS
	v_starting_tbl				T_OBJECT_CERTIFICATION_TABLE;
	v_merged_tbl				T_OBJECT_CERTIFICATION_TABLE;
	v_final_tbl					T_OBJECT_CERTIFICATION_TABLE;
BEGIN
	SELECT T_OBJECT_CERTIFICATION_ROW(cpc.product_id, sc.certification_type_id, 1, sc.valid_from_dtm, sc.expiry_dtm)
	  BULK COLLECT INTO v_starting_tbl
	  FROM company_product_required_cert cprc
	  JOIN TABLE(in_product_ids) pids ON cprc.product_id = pids.column_value
	  JOIN TABLE(in_certification_type_ids) ctids ON cprc.certification_type_id = ctids.column_value
	  JOIN company_product_certification cpc ON cpc.product_id = cprc.product_id
	  JOIN v$supplier_certification sc ON sc.certification_id = cpc.certification_id AND sc.certification_type_id = cprc.certification_type_id
	  JOIN TABLE(in_view_cert_company_sids) sids ON sc.company_sid = sids.column_value;

	v_merged_tbl := INTERNAL_MergeDateRanges(v_starting_tbl);

	SELECT T_OBJECT_CERTIFICATION_ROW(t.object_id, t.certification_type_id, t.is_certified, t.from_dtm, t.to_dtm)
	  BULK COLLECT INTO v_final_tbl
	  FROM company_product_required_cert cprc
	  JOIN TABLE(v_merged_tbl) t 
		   ON t.object_id = cprc.product_id
		   AND t.certification_type_id = cprc.certification_type_id
		   AND t.from_dtm <= cprc.from_dtm
		   AND (t.to_dtm IS NULL OR
			   (cprc.from_dtm IS NOT NULL AND t.to_dtm >= cprc.from_dtm));
	
	RETURN v_final_tbl;
END;

FUNCTION INTERNAL_GetReqdSupplierCerts(
	in_product_supplier_ids		IN	security.T_SID_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE,
	in_view_cert_company_sids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE
AS
	v_tbl						T_OBJECT_CERTIFICATION_TABLE;
	v_merged_tbl				T_OBJECT_CERTIFICATION_TABLE;
BEGIN
	SELECT T_OBJECT_CERTIFICATION_ROW(psc.product_supplier_id, sc.certification_type_id, 1, sc.valid_from_dtm, sc.expiry_dtm)
	  BULK COLLECT INTO v_tbl
	  FROM company_product_required_cert cprc
	  JOIN product_supplier ps ON ps.product_id = cprc.product_id
	  JOIN TABLE(in_product_supplier_ids) psids ON ps.product_supplier_id = psids.column_value
	  JOIN TABLE(in_certification_type_ids) ctids ON cprc.certification_type_id = ctids.column_value
	  JOIN product_supplier_certification psc ON psc.product_supplier_id = ps.product_supplier_id
	  JOIN v$supplier_certification sc ON sc.certification_id = psc.certification_id AND sc.certification_type_id = cprc.certification_type_id
	  JOIN TABLE(in_view_cert_company_sids) sids ON sc.company_sid = sids.column_value;

	v_merged_tbl := INTERNAL_MergeDateRanges(v_tbl);
	
	SELECT T_OBJECT_CERTIFICATION_ROW(t.object_id, t.certification_type_id, t.is_certified, t.from_dtm, t.to_dtm)
	  BULK COLLECT INTO v_tbl
	  FROM company_product_required_cert cprc
	  JOIN product_supplier ps ON ps.product_id = cprc.product_id
	  JOIN TABLE(v_merged_tbl) t 
		   ON t.object_id = ps.product_supplier_id
		   AND t.certification_type_id = cprc.certification_type_id
		   AND t.from_dtm <= cprc.from_dtm
		   AND (t.to_dtm IS NULL OR
			   (cprc.from_dtm IS NOT NULL AND t.to_dtm >= cprc.from_dtm));
	
	RETURN v_tbl;
END;

FUNCTION GetReqdSupplierCerts(
	in_product_supplier_ids		IN	T_FILTERED_OBJECT_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_product_supplier_ids			security.T_SID_TABLE;
	v_product_company_sids			security.T_SID_TABLE;
	v_view_certifications			security.T_SID_TABLE;
	v_view_prod_supp_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security_pkg.PERMISSION_READ);
	v_view_prod_sos_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security_pkg.PERMISSION_READ);
BEGIN
	SELECT DISTINCT product_supplier_id
	  BULK COLLECT INTO v_product_supplier_ids
	  FROM (
		SELECT ps.product_supplier_id
		  FROM product_supplier ps
		  JOIN TABLE(in_product_supplier_ids) t ON t.object_id = ps.product_supplier_id
		  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
		  LEFT JOIN TABLE(v_view_prod_supp_certs) supp_cap ON supp_cap.secondary_company_type_id = sc.company_type_id 
														  AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_view_prod_sos_certs) sos_cap ON sos_cap.secondary_company_type_id = pc.company_type_id
													    AND sos_cap.tertiary_company_type_id = sc.company_type_id
														AND pc.company_sid != v_company_sid
		 WHERE supp_cap.primary_company_type_id IS NOT NULL OR sos_cap.primary_company_type_id IS NOT NULL
	  );

	SELECT DISTINCT ps.supplier_company_sid
	  BULK COLLECT INTO v_product_company_sids
	  FROM product_supplier ps
	  JOIN TABLE(v_product_supplier_ids) pids ON pids.column_value = ps.product_supplier_id;

	v_view_certifications := type_capability_pkg.FilterPermissibleCompanySids(v_product_company_sids, chain_pkg.VIEW_CERTIFICATIONS);

	RETURN INTERNAL_GetReqdSupplierCerts(v_product_supplier_ids, in_certification_type_ids, v_view_certifications);
END;

/* SUPPLIED PRODUCT */

PROCEDURE SearchSupplierPurchasers(
	in_product_id					IN	chain.product_supplier.product_id%TYPE,
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_relationships					T_COMPANY_REL_SIDS_TABLE := company_pkg.GetVisibleRelationships;
	v_company_sids					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 1);

	FOR r IN (
		SELECT t.primary_company_sid, t.secondary_company_sid
		  FROM TABLE(v_relationships) t
		  LEFT JOIN company_product cp ON t.primary_company_sid = cp.company_sid
		  LEFT JOIN product_supplier ps ON t.primary_company_sid = ps.supplier_company_sid
		 WHERE (cp.is_active = 1 AND cp.product_id = in_product_id)
		    OR (ps.is_active = 1 AND ps.product_id = in_product_id)
	) LOOP
		IF r.primary_company_sid = v_company_sid THEN
			IF type_capability_pkg.CheckCapability(v_company_sid, r.secondary_company_sid, chain_pkg.ADD_PRODUCT_SUPPLIER) THEN
				v_company_sids.EXTEND;
				v_company_sids(v_company_sids.COUNT) := r.primary_company_sid;
			END IF;
		ELSE
			IF type_capability_pkg.CheckCapability(v_company_sid, r.primary_company_sid, r.secondary_company_sid, chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS) THEN
				v_company_sids.EXTEND;
				v_company_sids(v_company_sids.COUNT) := r.primary_company_sid;
			END IF;
		END IF;
	END LOOP;

	OPEN out_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company c
		  JOIN TABLE(v_company_sids) t ON t.column_value = c.company_sid
		 GROUP BY c.company_sid, c.name
		 ORDER BY c.name;
END;

PROCEDURE SearchSupplierSuppliers(
	in_product_id					IN	chain.product_supplier.product_id%TYPE,
	in_purchaser_company_sid		IN	chain.product_supplier.purchaser_company_sid%TYPE,
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_relationships					T_COMPANY_REL_SIDS_TABLE := company_pkg.GetVisibleRelationships;
	v_company_sids					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 1);

	FOR r IN (
		SELECT t.primary_company_sid, t.secondary_company_sid
		  FROM TABLE(v_relationships) t
		  LEFT JOIN company_product cp ON t.primary_company_sid = cp.company_sid
		  LEFT JOIN product_supplier ps ON t.primary_company_sid = ps.supplier_company_sid
		 WHERE (cp.is_active = 1 AND cp.product_id = in_product_id AND cp.company_sid = in_purchaser_company_sid)
		    OR (ps.is_active = 1 AND ps.product_id = in_product_id AND ps.supplier_company_sid = in_purchaser_company_sid)
	) LOOP	
		IF r.primary_company_sid = v_company_sid THEN
			IF type_capability_pkg.CheckCapability(v_company_sid, r.secondary_company_sid, chain_pkg.ADD_PRODUCT_SUPPLIER) THEN
				v_company_sids.EXTEND;
				v_company_sids(v_company_sids.COUNT) := r.secondary_company_sid;
			END IF;
		ELSE
			IF type_capability_pkg.CheckCapability(v_company_sid, r.primary_company_sid, r.secondary_company_sid, chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS) THEN
				v_company_sids.EXTEND;
				v_company_sids(v_company_sids.COUNT) := r.secondary_company_sid;
			END IF;
		END IF;
	END LOOP;

	OPEN out_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company c
		  JOIN TABLE(v_company_sids) t ON t.column_value = c.company_sid
		 GROUP BY c.company_sid, c.name
		 ORDER BY c.name;
END;

-- I feel bad having a dependency here on product_supplier_report_pkg, but there's 
-- a lot of code there to work out the permissions, and it felt wrong moving it here.
PROCEDURE INTERNAL_EmitSupplier(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cert_reqs_cur 				OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur	 				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_list							security.T_ORDERED_SID_TABLE;
	v_tags_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	v_list := security.T_ORDERED_SID_TABLE();
	v_list.EXTEND;
	v_list(1) := security.T_ORDERED_SID_ROW(in_product_supplier_id, 0);
	  
	product_supplier_report_pkg.CollectSearchResults(v_list, out_cur, out_cert_reqs_cur, out_tags_cur);
END;

PROCEDURE AddSupplierToProduct(
	in_product_id					IN	chain.company_product.product_id%TYPE,
	in_purchaser_company_sid		IN	chain.product_supplier.purchaser_company_sid%TYPE,
	in_supplier_company_sid			IN	chain.product_supplier.supplier_company_sid%TYPE,
	in_start_dtm					IN	chain.product_supplier.start_dtm%TYPE,
	in_end_dtm						IN	chain.product_supplier.end_dtm%TYPE,
	in_product_supplier_ref			IN	chain.product_supplier.product_supplier_ref%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cert_reqs_cur 				OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur	 				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_record_exists			NUMBER;
	v_product_supplier_id			product_supplier.product_supplier_id%TYPE;
	v_description					VARCHAR2(512);
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 1);

	AssertCanAddProductSupplier(
		in_purchaser_company_sid => in_purchaser_company_sid, 
		in_supplier_company_sid => in_supplier_company_sid
	);	

	-- You can only add a supplier below an existing level; ie a T1 directly off the company product, or
	-- as a T2+ off an existing supplied product. Make sure it exists. 
	SELECT SUM(c)
	  INTO v_parent_record_exists
	  FROM (
		SELECT COUNT(*) c
		  FROM company_product
		 WHERE company_sid = in_purchaser_company_sid
		   AND product_id = in_product_id
		UNION
		SELECT COUNT(*) c
		  FROM product_supplier
		 WHERE supplier_company_sid = in_purchaser_company_sid
		   AND product_id = in_product_id
	);
	
	IF v_parent_record_exists < 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'No parent record exists.');
		RETURN;
	END IF;
	
	BEGIN
		INSERT INTO chain.product_supplier
			(product_id, product_supplier_id, purchaser_company_sid, supplier_company_sid, start_dtm, end_dtm, product_supplier_ref, is_active)
		VALUES
			(in_product_id, product_supplier_id_seq.nextval, in_purchaser_company_sid, in_supplier_company_sid, in_start_dtm, in_end_dtm, in_product_supplier_ref, 1)
		RETURNING 
			product_supplier_id INTO v_product_supplier_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'This product supplier already exists');
	END;

	product_metric_pkg.UNSEC_PropagateProdSupMetrics(v_product_supplier_id);

	chain_link_pkg.ProductSupplierAdded(v_product_supplier_id);
	
	v_description := 'Added product supplier from '||in_supplier_company_sid||' to '||in_purchaser_company_sid||' to product '||in_product_id
					 ||' starting '||in_start_dtm|| CASE in_end_dtm IS NULL WHEN TRUE THEN '' ELSE ' to '||in_end_dtm END;
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	in_product_id,
		in_description		=>	v_description, 
		in_param_1			=>	in_product_id,
		in_param_2			=>	in_purchaser_company_sid,
		in_param_3			=>	in_supplier_company_sid
	);

	scheduled_alert_pkg.CreateProductCompanyAlert(
		in_company_product_id => in_product_id, 
		in_purchaser_company_sid => in_purchaser_company_sid, 
		in_supplier_company_sid => in_supplier_company_sid);

	INTERNAL_EmitSupplier(v_product_supplier_id, out_cur, out_cert_reqs_cur, out_tags_cur);
END;

PROCEDURE UpdateProductSupplier (
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE,
	in_start_dtm					IN	chain.product_supplier.start_dtm%TYPE,
	in_end_dtm						IN	chain.product_supplier.end_dtm%TYPE,
	in_product_supplier_ref			IN	chain.product_supplier.product_supplier_ref%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cert_reqs_cur 				OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur	 				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_product_id					chain.product_supplier.product_id%TYPE;
	v_purchaser_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	AssertCanEditProductSupplier(in_product_supplier_id => in_product_supplier_id);
	
	UPDATE product_supplier
	   SET start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   product_supplier_ref = in_product_supplier_ref
	 WHERE product_supplier_id = in_product_supplier_id;

	chain_link_pkg.ProductSupplierUpdated(in_product_supplier_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Updated product supplier from {2} to {1} in product {0}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	v_purchaser_company_sid,
		in_param_3			=>	v_supplier_company_sid
	);
	
	INTERNAL_EmitSupplier(in_product_supplier_id, out_cur, out_cert_reqs_cur, out_tags_cur);
END;

PROCEDURE SaveProductSupplierTags(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE,
	in_tag_group_id					IN	csr.tag_group.tag_group_id%TYPE,
	in_tag_ids						IN	security.security_pkg.T_SID_IDS
)
AS
	v_product_id					chain.product_supplier.product_id%TYPE;
	v_tag_ids_tbl			security.T_SID_TABLE;
BEGIN
	SELECT product_id
	  INTO v_product_id
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	AssertCanEditProductSupplier(in_product_supplier_id => in_product_supplier_id);

	-- crap hack for ODP.NET
	IF in_tag_ids IS NULL OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_tag_ids_tbl := security.T_SID_TABLE();
	ELSE
		v_tag_ids_tbl := security_pkg.SidArrayToTable(in_tag_ids);
	END IF;

	DELETE FROM product_supplier_tag
	 WHERE product_supplier_id = in_product_supplier_id
	   AND tag_group_id = in_tag_group_id;

	INSERT INTO product_supplier_tag (product_supplier_id, tag_group_id, tag_id)
	SELECT in_product_supplier_id, in_tag_group_id, column_value FROM TABLE(v_tag_ids_tbl);
END;

PROCEDURE DeactivateProductSupplier(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id					chain.product_supplier.product_id%TYPE;
	v_purchaser_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	AssertCanEditProductSupplier(in_product_supplier_id => in_product_supplier_id);
	
	UPDATE product_supplier
	   SET is_active = 0
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	product_metric_pkg.UNSEC_PropagateProdSupMetrics(in_product_supplier_id);

	chain_link_pkg.ProductSupplierDeactivated(in_product_supplier_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Deactivated product supplier from {2} to {1} in product {0}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	v_purchaser_company_sid,
		in_param_3			=>	v_supplier_company_sid
	);
END;

PROCEDURE ReactivateProductSupplier(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id					chain.product_supplier.product_id%TYPE;
	v_purchaser_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);
	AssertCanEditProductSupplier(in_product_supplier_id => in_product_supplier_id);
	
	UPDATE product_supplier
	   SET is_active = 1
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	product_metric_pkg.UNSEC_PropagateProdSupMetrics(in_product_supplier_id);

	chain_link_pkg.ProductSupplierReactivated(in_product_supplier_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Reactivated product supplier from {2} to {1} in product {0}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	v_purchaser_company_sid,
		in_param_3			=>	v_supplier_company_sid
	);
END;

PROCEDURE RemoveSupplierFromProduct(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
)
AS
	v_product_id					chain.product_supplier.product_id%TYPE;
	v_purchaser_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT product_id, purchaser_company_sid, supplier_company_sid
	  INTO v_product_id, v_purchaser_company_sid, v_supplier_company_sid
	  FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	AssertCanViewCompanyProduct(in_product_id => v_product_id, in_as_supplier => 1);

	AssertCanAddProductSupplier(
		in_purchaser_company_sid => v_purchaser_company_sid, 
		in_supplier_company_sid => v_supplier_company_sid
	);

	chain_link_pkg.RemovingProductSupplier(in_product_supplier_id);
	
	-- we mark the supplier is inactive so we can correctly propagate the metric values
	UPDATE product_supplier
	   SET is_active = 0
	 WHERE product_supplier_id = in_product_supplier_id;
	 
	product_metric_pkg.UNSEC_PropagateProdSupMetrics(in_product_supplier_id);

	DELETE FROM product_supplier_metric_val
	 WHERE product_supplier_id = in_product_supplier_id;

	DELETE FROM product_supplier_certification
	 WHERE product_supplier_id = in_product_supplier_id;

	DELETE FROM product_supplier
	 WHERE product_supplier_id = in_product_supplier_id;

	chain_link_pkg.ProductSupplierRemoved(in_product_supplier_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Removed product supplier from {2} to {1} from product {0}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	v_purchaser_company_sid,
		in_param_3			=>	v_supplier_company_sid
	);
END;

PROCEDURE AddCertToProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE,
	in_certification_id			IN	chain.product_supplier_certification.certification_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_id				product_supplier.product_id%TYPE;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_cert_company_sid			security_pkg.T_SID_ID;
BEGIN
	AssertCanEditProdSuppCerts(in_product_supplier_id => in_product_supplier_id);
	
	SELECT product_id, supplier_company_sid INTO v_product_id, v_supplier_company_sid FROM product_supplier WHERE product_supplier_id = in_product_supplier_id;
	SELECT company_sid INTO v_cert_company_sid FROM v$supplier_certification WHERE certification_id = in_certification_id;

	IF v_supplier_company_sid != v_cert_company_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier company does not match certification company');
	END IF;

	BEGIN
		INSERT INTO chain.product_supplier_certification 
			(product_supplier_id, certification_id, applied_dtm)
		VALUES
			(in_product_supplier_id, in_certification_id, SYSDATE);
	EXCEPTION
		WHEN dup_val_on_index THEN
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'This certification already exists');
	END;

	chain_link_pkg.ProdSuppCertAdded(in_product_supplier_id, in_certification_id);
	
	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Added certificate {2} to product {0} supplier {1}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	in_product_supplier_id,
		in_param_3			=>	in_certification_id
	);

	OPEN out_cur FOR
		SELECT psc.product_supplier_id, psc.certification_id,
			   ct.certification_type_id, ct.label certification_type_label,
			   sc.valid_from_dtm, sc.expiry_dtm
		  FROM product_supplier_certification psc
		  JOIN v$supplier_certification sc ON sc.certification_id = psc.certification_id
		  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
		 WHERE psc.product_supplier_id = in_product_supplier_id
		   AND psc.certification_id = in_certification_id;
END;

PROCEDURE RemoveCertFromProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE,
	in_certification_id			IN	chain.product_supplier_certification.certification_id%TYPE
)
AS
	v_product_id				product_supplier.product_id%TYPE;
BEGIN
	AssertCanEditProdSuppCerts(in_product_supplier_id => in_product_supplier_id);
	
	DELETE FROM chain.product_supplier_certification
	 WHERE product_supplier_id = in_product_supplier_id
	   AND certification_id = in_certification_id;

	chain_link_pkg.ProdSuppCertRemoved(in_product_supplier_id, in_certification_id);
	
	SELECT product_id INTO v_product_id FROM product_supplier WHERE product_supplier_id = in_product_supplier_id;

	csr.csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'), 
		in_audit_type_id	=>	csr.csr_data_pkg.AUDIT_TYPE_CHAIN_COMP_PRODUCT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'), 
		in_object_sid		=>	v_product_id,
		in_description		=>	'Removed certificate {2} from product {0} supplier {1}', 
		in_param_1			=>	v_product_id,
		in_param_2			=>	in_product_supplier_id,
		in_param_3			=>	in_certification_id
	);
END;

PROCEDURE SearchProducts (
	in_search_term			VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
BEGIN

	OPEN out_cur FOR
		SELECT product_id, product_name
		  FROM v$company_product
		 WHERE LOWER(product_name) LIKE v_search;

END;

PROCEDURE GetProduct(
	in_product_id					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_type_id			company_type.company_type_id%TYPE;
	v_owner_company_sid				security_pkg.T_SID_ID;
	v_root_type_id					product_type.product_type_id%TYPE := product_type_pkg.GetRootProductType;
	v_read_only						NUMBER := 1;
	v_can_view_certs				NUMBER := 0;
	v_can_add_certs					NUMBER := 0;
	v_can_view_suppliers			NUMBER := 0;
	v_can_add_suppliers				NUMBER := 0;
	v_can_view_prod_metric_vals		NUMBER := 0;
	v_can_set_prod_metric_vals		NUMBER := 0;
	v_product_supplier_cnt			NUMBER;
	v_read_product_suppliers		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(
		v_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_read_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(
		v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_add_product_suppliers			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(
		v_company_sid, chain_pkg.ADD_PRODUCT_SUPPLIER);
	v_add_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(
		v_company_sid, chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS);
BEGIN
	AssertCanViewCompanyProduct(in_product_id => in_product_id, in_as_supplier => 1);

	SELECT company_sid
	  INTO v_owner_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;
	
	SELECT count(*)
		INTO v_product_supplier_cnt
		FROM product_supplier
		WHERE product_id = in_product_id
		AND supplier_company_sid =  v_company_sid;
	 
	v_owner_company_type_id := company_type_pkg.GetCompanyTypeId(v_owner_company_sid);
		
	-- Look for any company type that we can supply products to that can belong to the chain of suppliers for
	-- the product we're looking at.
	WITH ctr AS (
		SELECT primary_company_type_id, secondary_company_type_id
		  FROM company_type_relationship
		 START WITH primary_company_type_id = v_owner_company_type_id
	   CONNECT BY NOCYCLE primary_company_type_id = PRIOR secondary_company_type_id
	)
	SELECT DECODE(NVL(SUM(sup.primary_company_type_id),0) + NVL(SUM(sos.primary_company_type_id), 0), 0, 0, 1),
		DECODE(NVL(SUM(asup.primary_company_type_id),0) + NVL(SUM(asos.primary_company_type_id), 0), 0, 0, 1)
	  INTO v_can_view_suppliers, v_can_add_suppliers
	  FROM ctr
	  LEFT JOIN TABLE(v_read_product_suppliers) sup ON sup.primary_company_type_id = ctr.primary_company_type_id
												  AND sup.secondary_company_type_id = ctr.secondary_company_type_id
	  LEFT JOIN TABLE(v_read_product_sup_of_sup) sos ON sos.secondary_company_type_id = ctr.primary_company_type_id
												   AND sos.tertiary_company_type_id = ctr.secondary_company_type_id
	  LEFT JOIN TABLE(v_add_product_suppliers) asup ON asup.primary_company_type_id = ctr.primary_company_type_id
												  AND asup.secondary_company_type_id = ctr.secondary_company_type_id
	  LEFT JOIN TABLE(v_add_product_sup_of_sup) asos ON asos.secondary_company_type_id = ctr.primary_company_type_id
												   AND asos.tertiary_company_type_id = ctr.secondary_company_type_id;
	
	IF v_can_view_suppliers = 0 THEN
		-- Context company is itself a supplier, so check if it has permission to see products it supplies
		IF v_product_supplier_cnt > 0 AND type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
			v_can_view_suppliers := 1;
		END IF;
	END IF;

	IF v_company_sid = v_owner_company_sid THEN
		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_WRITE) THEN
			v_read_only := 0;
		END IF;
		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ) THEN
			v_can_view_certs := 1;
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_WRITE) THEN
				v_can_add_certs := 1;
			END IF;
		END IF;
		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_READ) THEN
			v_can_view_prod_metric_vals := 1;
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
				v_can_set_prod_metric_vals := 1;
			END IF;
		END IF;
	ELSE
		IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_WRITE) THEN
			v_read_only := 0;
		END IF;
		IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ) THEN
			v_can_view_certs := 1;
			IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_WRITE) THEN
				v_can_add_certs := 1;
			END IF;
		END IF;
		IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_READ) THEN
			v_can_view_prod_metric_vals := 1;
			IF type_capability_pkg.CheckCapability(v_company_sid, v_owner_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
				v_can_set_prod_metric_vals := 1;
			END IF;
		END IF;		
		IF (v_product_supplier_cnt > 0) AND type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_READ) THEN
			v_can_view_prod_metric_vals := 1;
			IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
				v_can_set_prod_metric_vals := 1;
			END IF;
		END IF;
	END IF;

	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT cp.product_id, cp.product_name, cp.product_ref, cp.lookup_key, cp.is_active, v_read_only read_only,
			   c.company_sid, c.name company_name,
			   pt.product_type_id, NVL(pt_tree.tree_path, pt.description) product_type_name,
			   v_can_view_certs can_view_certifications, v_can_view_suppliers can_view_suppliers,
			   v_can_add_certs can_add_certifications, v_can_add_suppliers can_add_suppliers,
			   v_can_view_prod_metric_vals can_view_prod_metric_vals, v_can_set_prod_metric_vals can_set_prod_metric_vals
		  FROM v$company_product cp
		  JOIN v$company c ON c.company_sid = cp.company_sid
		  JOIN chain.v$product_type pt ON pt.product_type_id = cp.product_type_id
		  LEFT JOIN (
				SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ') tree_path
				  FROM chain.v$product_type
				 START WITH parent_product_type_id = v_root_type_id
			   CONNECT BY parent_product_type_id = PRIOR product_type_id
		  ) pt_tree ON pt_tree.product_type_id = pt.product_type_id
		 WHERE cp.product_id = in_product_id;

	OPEN out_tags_cur FOR
		SELECT cpt.product_id, cpt.tag_group_id, cpt.tag_id, t.tag
		  FROM company_product_tag cpt
		  JOIN csr.v$tag t ON t.tag_id = cpt.tag_id
		 WHERE cpt.product_id = in_product_id;
END;

PROCEDURE GetProductsForMetricsImport(
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sids 			security.T_SID_TABLE:= type_capability_pkg.GetPermissibleCompanySids(chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE);
	v_product_mtrc_as_supplier		NUMBER := 0;
BEGIN
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_WRITE) THEN
		v_owner_company_sids.extend;
		v_owner_company_sids(v_owner_company_sids.COUNT) := v_company_sid;
	END IF;

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
		v_product_mtrc_as_supplier := 1;
	END IF;

	OPEN out_cur FOR
		SELECT DISTINCT cp.product_id, cp.product_name, cp.product_ref, cp.lookup_key, cp.is_active,
		       c.company_sid, c.name company_name,
		       pt.product_type_id, pt.description product_type_name
		  FROM v$company_product cp
		  JOIN v$company c ON c.company_sid = cp.company_sid
		  JOIN chain.v$product_type pt ON pt.product_type_id = cp.product_type_id
		  LEFT JOIN TABLE(v_owner_company_sids) owner_perm ON owner_perm.column_value = cp.company_sid
		  LEFT JOIN product_supplier ps ON ps.product_id = cp.product_id
		  WHERE (owner_perm.column_value IS NOT NULL
				OR (v_product_mtrc_as_supplier = 1 AND ps.supplier_company_sid = v_company_sid));
END;

PROCEDURE GetPrdSupplrsForMetricsImport(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_write_prdcts_as_suppliers		NUMBER := 0;
	v_write_product_supp_metrics	T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL, security.security_pkg.PERMISSION_WRITE);
	v_write_prd_sup_of_sup_mtrc		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, security.security_pkg.PERMISSION_WRITE);
BEGIN	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
		v_write_prdcts_as_suppliers := 1;
	END IF;

	OPEN out_cur FOR
		SELECT ps.product_supplier_id, ps.product_supplier_ref,
			   ps.product_id,
			   ps.purchaser_company_sid, pc.name purchaser_company_name,
			   ps.supplier_company_sid, sc.name supplier_company_name,
			   cp.product_name, cp.product_ref, cp.lookup_key, cp.is_active, 
			   owner.company_sid, owner.name company_name, 
			   pt.product_type_id, pt.description product_type_name
		  FROM product_supplier ps
		  JOIN v$company_product cp ON cp.product_id = ps.product_id
		  JOIN v$company owner ON owner.company_sid = cp.company_sid
		  JOIN v$product_type pt ON pt.product_type_id = cp.product_type_id
		  JOIN v$company pc ON pc.company_sid = ps.purchaser_company_sid
		  JOIN v$company sc ON sc.company_sid = ps.supplier_company_sid  
		  LEFT JOIN TABLE(v_write_product_supp_metrics) write_sup ON write_sup.secondary_company_type_id = sc.company_type_id AND write_sup.tertiary_company_type_id IS NULL
		  LEFT JOIN TABLE(v_write_prd_sup_of_sup_mtrc) write_sos ON write_sos.secondary_company_type_id = pc.company_type_id AND write_sos.tertiary_company_type_id = sc.company_type_id
		   -- Check write permission on product_supplier_metric
		 WHERE ((ps.supplier_company_sid = v_company_sid AND v_write_prdcts_as_suppliers = 1)
		    OR (ps.purchaser_company_sid = v_company_sid AND write_sup.primary_company_type_id IS NOT NULL)
		    OR write_sos.primary_company_type_id IS NOT NULL);
END;

PROCEDURE GetProducts(
	in_product_ids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT SYS_REFCURSOR,
	out_tags_cur			OUT SYS_REFCURSOR
)
AS
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sid		security_pkg.T_SID_ID;
	v_read_only				NUMBER := 1;
	v_product_ids			security.T_SID_TABLE;
	v_pos					NUMBER(10);
BEGIN
	v_product_ids := security_pkg.SidArrayToTable(in_product_ids);
	
	FOR p IN (
		SELECT column_value FROM TABLE(v_product_ids)
	)
	LOOP
		AssertCanViewCompanyProduct(in_product_id => p.column_value, in_as_supplier => 1);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT cp.product_id, cp.product_name, cp.product_ref, cp.lookup_key, cp.is_active, v_read_only read_only,
			   c.company_sid, c.name company_name,
			   pt.product_type_id, pt.description product_type_name
		  FROM v$company_product cp
		  JOIN TABLE(v_product_ids) x on cp.product_id = x.column_value
		  JOIN v$company c ON c.company_sid = cp.company_sid
		  JOIN chain.v$product_type pt ON pt.product_type_id = cp.product_type_id;

	OPEN out_tags_cur FOR
		SELECT cpt.product_id, cpt.tag_group_id, cpt.tag_id, t.tag
		  FROM company_product_tag cpt
		  JOIN csr.v$tag t ON t.tag_id = cpt.tag_id
		  JOIN TABLE(v_product_ids) x on cpt.product_id = x.column_value;
END;

FUNCTION INTERNAL_GetProductCertReqs(
	in_product_ids				IN	security.T_SID_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_products_as_suppliers		NUMBER := 0;
	v_product_ids_with_certs	security.T_SID_TABLE;
	v_product_company_sids		security.T_SID_TABLE;
	v_product_supplier_ids		security.T_SID_TABLE;
	v_prod_supp_ids_with_certs	security.T_SID_TABLE;
	v_view_certifications		security.T_SID_TABLE;
	v_read_product_suppliers	T_PERMISSIBLE_TYPES_TABLE;
	v_read_product_sup_of_sup	T_PERMISSIBLE_TYPES_TABLE;
	v_read_product_certs		T_PERMISSIBLE_TYPES_TABLE;
	v_read_product_supp_certs	T_PERMISSIBLE_TYPES_TABLE;
	v_read_product_sos_certs	T_PERMISSIBLE_TYPES_TABLE;
	v_product_certs				T_OBJECT_CERTIFICATION_TABLE;
	v_supplier_certs			T_OBJECT_CERTIFICATION_TABLE;
	v_tbl						T_OBJECT_CERTIFICATION_TABLE;
BEGIN
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
		v_products_as_suppliers := 1;
	END IF;

	-- We assume the caller has already done the capability checks to read the products, but not necessarily their certifications.
	-- If we don't have PRODUCT_CERTIFICATIONS on a product, then we can't see its certifications or even the requirements,
	-- so we're only going to return details for the products where we have that permission.

	v_read_product_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ);
	
	SELECT DISTINCT product_id
	  BULK COLLECT INTO v_product_ids_with_certs
	  FROM company_product cp
	  JOIN v$company c ON c.company_sid = cp.company_sid
	  JOIN TABLE(in_product_ids) pids ON pids.column_value = cp.product_id
	  LEFT JOIN TABLE(v_read_product_certs) rpc_own ON rpc_own.secondary_company_type_id IS NULL AND c.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_product_certs) rpc_others ON rpc_others.secondary_company_type_id = c.company_type_id AND c.company_sid != v_company_sid
	 WHERE rpc_own.primary_company_type_id IS NOT NULL 
	    OR rpc_others.primary_company_type_id IS NOT NULL;

	IF v_product_ids_with_certs.COUNT = 0 THEN
		return T_OBJECT_CERTIFICATION_TABLE();
	END IF;

	-- We don't assume that the caller has done any capability checks to read the suppliers, nor their certifications.
	-- If we can see a product supplier, we'll consider it in our calculations (e.g. for what counts as a leaf node)
	-- even if we can't see its certifications.  If we can't see its certifications, we'll treat it as uncertified.

	v_read_product_suppliers := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_read_product_sup_of_sup := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	
	SELECT ps.product_supplier_id
	  BULK COLLECT INTO v_product_supplier_ids
	  FROM product_supplier ps
	  JOIN v$company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN v$company sc ON sc.company_sid = ps.supplier_company_sid
	  JOIN TABLE(v_product_ids_with_certs) pids ON pids.column_value = ps.product_id
	  LEFT JOIN TABLE(v_read_product_suppliers) read_sup ON read_sup.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_product_sup_of_sup) read_sos ON read_sos.secondary_company_type_id = pc.company_type_id AND read_sos.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
	 WHERE ps.is_active = 1
	   AND ((ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1)
			OR read_sup.primary_company_type_id IS NOT NULL
			OR read_sos.primary_company_type_id IS NOT NULL);

	v_read_product_supp_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_READ);
	v_read_product_sos_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_READ);
	
	SELECT ps.product_supplier_id
	  BULK COLLECT INTO v_prod_supp_ids_with_certs
	  FROM product_supplier ps
	  JOIN v$company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN v$company sc ON sc.company_sid = ps.supplier_company_sid
	  JOIN TABLE(v_product_supplier_ids) pids ON pids.column_value = ps.product_supplier_id
	  LEFT JOIN TABLE(v_read_product_supp_certs) read_sup_certs ON read_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_product_sos_certs) read_sos_certs ON read_sos_certs.secondary_company_type_id = pc.company_type_id AND read_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
	 WHERE read_sup_certs.primary_company_type_id IS NOT NULL
	    OR read_sos_certs.primary_company_type_id IS NOT NULL;

	-- Not only do we need to be able to see a product or product supplier's certifications, but we need to
	-- be able to see the certifications themselves.  These *should* be on the same companies as the product
	-- or the product supplier, so we save ourselves a join here.

	SELECT DISTINCT company_sid
	  BULK COLLECT INTO v_product_company_sids
	  FROM (
			SELECT cp.company_sid
			  FROM company_product cp
			  JOIN TABLE(v_product_ids_with_certs) pids ON pids.column_value = cp.product_id
			 UNION
			SELECT ps.supplier_company_sid company_sid
			  FROM product_supplier ps
			  JOIN TABLE(v_prod_supp_ids_with_certs) pids ON pids.column_value = ps.product_supplier_id
	  );

	v_view_certifications := type_capability_pkg.FilterPermissibleCompanySids(v_product_company_sids, chain_pkg.VIEW_CERTIFICATIONS);
	IF v_company_sid MEMBER OF v_product_company_sids AND type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.VIEW_CERTIFICATIONS) THEN
		v_view_certifications.EXTEND;
		v_view_certifications(v_view_certifications.COUNT) := v_company_sid;
	END IF;

	v_product_certs := INTERNAL_GetReqdProductCerts(v_product_ids_with_certs, in_certification_type_ids, v_view_certifications);
	v_supplier_certs := INTERNAL_GetReqdSupplierCerts(v_prod_supp_ids_with_certs, in_certification_type_ids, v_view_certifications);

	WITH all_certs AS (
		SELECT cp.product_id,
			   cprc.certification_type_id,
			   NULL purchaser_company_sid,
			   cp.company_sid supplier_company_sid,
			   NVL(pc.is_certified, 0) is_certified
		  FROM company_product cp
		  JOIN TABLE(v_product_ids_with_certs) pids ON pids.column_value = cp.product_id
		  JOIN company_product_required_cert cprc ON cprc.product_id = cp.product_id
		  LEFT JOIN TABLE(v_product_certs) pc ON pc.object_id = cp.product_id AND pc.certification_type_id = cprc.certification_type_id
		  UNION ALL
		SELECT ps.product_id,
			   cprc.certification_type_id,
			   ps.purchaser_company_sid,
			   ps.supplier_company_sid,
			   NVL(sc.is_certified, 0) is_certified
		  FROM product_supplier ps
		  JOIN TABLE(v_product_supplier_ids) pids ON pids.column_value = ps.product_supplier_id
		  JOIN company_product_required_cert cprc ON cprc.product_id = ps.product_id
		  LEFT JOIN TABLE(v_supplier_certs) sc ON sc.object_id = ps.product_supplier_id AND sc.certification_type_id = cprc.certification_type_id
	), tree AS (
		SELECT product_id, certification_type_id, is_certified,
			   CASE WHEN purchaser_company_sid IS NULL THEN 1 ELSE 0 END is_owner,
			   CASE WHEN purchaser_company_sid IS NULL THEN is_certified ELSE 0 END is_certified_owner,
			   CASE WHEN purchaser_company_sid IS NULL THEN 0 ELSE 1 END is_supplier,
			   CASE WHEN purchaser_company_sid IS NULL THEN 0 ELSE is_certified END is_certified_supplier,
			   CONNECT_BY_ISLEAF is_leaf,
			   CASE WHEN CONNECT_BY_ISLEAF = 1 THEN is_certified ELSE 0 END is_certified_leaf,
			   CASE WHEN CONNECT_BY_ISLEAF = 1 AND SYS_CONNECT_BY_PATH(is_certified, '/') NOT LIKE '%1%' THEN 1 ELSE 0 END is_rollup_failure
		  FROM all_certs
		 START WITH purchaser_company_sid IS NULL
	   CONNECT BY product_id = PRIOR product_id
			   AND certification_type_id = PRIOR certification_type_id
			   AND purchaser_company_sid = PRIOR supplier_company_sid
	), totals AS (
		SELECT product_id, certification_type_id,
			   COUNT(*) num_things,				SUM(is_certified) certified_things,
			   SUM(is_owner) num_owners,		SUM(is_certified_owner) certified_owners,
			   SUM(is_supplier) num_suppliers,	SUM(is_certified_supplier) certified_suppliers,
			   SUM(is_leaf) num_leaves,			SUM(is_certified_leaf) certified_leaves,
			   SUM(is_rollup_failure) num_rollup_failures
		  FROM tree
		 GROUP BY product_id, certification_type_id
	)
	SELECT T_OBJECT_CERTIFICATION_ROW(cprc.product_id, cprc.certification_type_id,
		   CASE ct.product_requirement_type_id
				WHEN chain_pkg.CERT_REQ_TYPE_PRODUCT_OWNER THEN
						CASE WHEN t.certified_owners = t.num_owners THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ANY_SUPPLIER THEN
						CASE WHEN t.certified_suppliers > 0 THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ANY_SUP_OR_OWNER THEN
						CASE WHEN t.certified_things > 0 THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ALL_SUPPLIERS THEN
						CASE WHEN t.certified_suppliers = t.num_suppliers AND t.num_suppliers > 0 THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ALL_SUPS_AND_OWN THEN
						CASE WHEN t.certified_things = t.num_things AND t.num_suppliers > 0 THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ALL_LEAF_SUPPLRS THEN
						CASE WHEN t.certified_leaves = t.num_leaves AND t.num_suppliers > 0 THEN 1 ELSE 0 END
				WHEN chain_pkg.CERT_REQ_TYPE_ROLL_UP THEN
						CASE WHEN t.num_rollup_failures > 0 THEN 0 ELSE 1 END
		   ELSE 0 END,
		   cprc.from_dtm, cprc.to_dtm)
	  BULK COLLECT INTO v_tbl
	  FROM company_product_required_cert cprc
	  JOIN TABLE(v_product_ids_with_certs) pids ON cprc.product_id = pids.column_value
	  JOIN TABLE(in_certification_type_ids) ctids ON cprc.certification_type_id = ctids.column_value
	  JOIN certification_type ct ON ct.certification_type_id = cprc.certification_type_id
	  LEFT JOIN totals t ON t.product_id = cprc.product_id AND t.certification_type_id = ct.certification_type_id;

	RETURN v_tbl;
END;

PROCEDURE GetCertRequirementsForProduct(
	in_product_id				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_product_ids				security.T_SID_TABLE;
	v_cert_type_ids				security.T_SID_TABLE;
	v_tbl						T_OBJECT_CERTIFICATION_TABLE;
BEGIN
	AssertCanViewProductCerts(in_product_id => in_product_id);

	INTERNAL_PopulateProdCertIds(in_product_id, v_product_ids, v_cert_type_ids);
	v_tbl := INTERNAL_GetProductCertReqs(v_product_ids, v_cert_type_ids);
	
	OPEN out_cur FOR
		SELECT t.object_id product_id, t.from_dtm, t.to_dtm, t.is_certified,
			   ct.certification_type_id, ct.label certification_type_label
		  FROM TABLE(v_tbl) t
		  JOIN certification_type ct ON ct.certification_type_id = t.certification_type_id
		 ORDER BY ct.label;
END;

-- Testing - TO DELETE in future
PROCEDURE CreateType(
	in_parent_id		IN	NUMBER,
	in_desc				IN	VARCHAR2,
	in_node_type		IN	NUMBER DEFAULT 0,
	out_id				OUT	NUMBER
)
AS
BEGIN

	BEGIN
		chain.product_type_pkg.AddProductType(
			in_parent_product_type_id	=>  in_parent_id,
			in_description				=>	in_desc,
			in_node_type				=>	in_node_type,
			out_product_type_id			=>	out_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			security_pkg.debugmsg('Failed adding type; '||in_desc);
			SELECT product_type_id
			  INTO out_id
			  FROM chain.product_type
			 WHERE lower(label) = lower('Product Types');
	END;

END;

PROCEDURE GetAllTranslations(
	in_validation_lang		IN	company_product_tr.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.is_active, tr.description, tr.lang, rownum rn,
			   CASE WHEN tr.last_changed_dtm_description > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM company_product p
		  JOIN company_product_tr tr ON p.app_sid = tr.app_sid
		   AND p.product_id = tr.product_id
		  JOIN aspen2.translation_set ts ON p.app_sid = ts.application_sid
		   AND ts.lang = tr.lang
		 ORDER BY rn,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTranslations(
	in_product_ids			IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	company_product_tr.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_product_desc_tbl		T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
	v_can_write					NUMBER(1) := 1;
BEGIN
	IF in_product_ids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of product IDs do not match number of descriptions.');
	END IF;
	
	IF in_product_ids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_product_desc_tbl.EXTEND(in_product_ids.COUNT);

	FOR i IN 1..in_product_ids.COUNT
	LOOP
		v_product_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_product_ids(i), in_descriptions(i));
	END LOOP;

	IF NOT (security_pkg.IsAdmin(SYS_CONTEXT('SECURITY', 'ACT')) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		v_can_write := 0;
	END IF;
	
	OPEN out_cur FOR
		SELECT pt.product_id sid, v_can_write can_write,
			   CASE pt.description WHEN pd.description THEN 0 ELSE 1 END has_changed
		  FROM company_product_tr pt
		  JOIN TABLE(v_product_desc_tbl) pd ON pt.product_id = pd.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE SetTranslation(
	in_product_id		IN	company_product.product_id%TYPE,
	in_lang				IN	company_product_tr.lang%TYPE,
	in_translated		IN	VARCHAR2
)
AS
	v_description	company_product_tr.description%TYPE;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;

	BEGIN
		SELECT description
		  INTO v_description
		  FROM company_product_tr
		 WHERE product_id = in_product_id
		   AND lang = in_lang;

		IF v_description != in_translated THEN
			UPDATE company_product_tr
			   SET last_changed_dtm_description = SYSDATE,
				   description = in_translated
			 WHERE product_id = in_product_id
			   AND lang = in_lang;
		END IF;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO company_product_tr
				(product_id, lang, description, last_changed_dtm_description)
			VALUES
				(in_product_id, in_lang, in_translated, SYSDATE);
	END;

END;

END company_product_pkg;
/
