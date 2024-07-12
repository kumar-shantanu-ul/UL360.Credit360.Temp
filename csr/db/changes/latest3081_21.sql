-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.product_metric (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	applies_to_product			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	applies_to_prod_supplier	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	product_metric_icon_id		NUMBER(10, 0)	NULL,
	is_mandatory				NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	show_measure				NUMBER(1, 0)	DEFAULT 1 NOT NULL,
	CONSTRAINT pk_product_metric PRIMARY KEY (app_sid, ind_sid),
	CONSTRAINT chk_prod_metric_mand CHECK (is_mandatory IN (0,1)),
	CONSTRAINT chk_prod_met_app_to_prod CHECK (applies_to_product IN (0,1)),
	CONSTRAINT chk_prod_met_app_to_pr_supp CHECK (applies_to_prod_supplier IN (0,1)),
	CONSTRAINT chk_prod_metric_shw_msr CHECK (show_measure IN (0,1))
);

CREATE TABLE chain.product_metric_icon (
	product_metric_icon_id		NUMBER(10,0) 	NOT NULL,
	description					VARCHAR2(255)	NOT NULL,
	icon_path					VARCHAR2(500)	NOT NULL,
	CONSTRAINT pk_product_metric_icon PRIMARY KEY (product_metric_icon_id)
);

CREATE TABLE chain.product_metric_product_type (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	product_type_id				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_product_metric_product_type PRIMARY KEY (app_sid, ind_sid, product_type_id)
);

CREATE TABLE csrimp.chain_product_metric (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	applies_to_product			NUMBER(1, 0)	NOT NULL,
	applies_to_prod_supplier	NUMBER(1, 0)	NOT NULL,
	product_metric_icon_id		NUMBER(10, 0)	NULL,
	is_mandatory				NUMBER(1, 0)	NOT NULL,
	show_measure				NUMBER(1, 0)	NOT NULL,
	CONSTRAINT pk_chain_product_metric PRIMARY KEY (csrimp_session_id, ind_sid),
	CONSTRAINT fk_chain_product_metric_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.chain_prd_mtrc_prd_type (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	product_type_id				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_chain_prd_mtrc_prd_type PRIMARY KEY (csrimp_session_id, ind_sid, product_type_id),
	CONSTRAINT fk_chain_prd_mtrc_prd_type_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.product_metric_val DROP CONSTRAINT fk_product_metric_val_ind;
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	FROM all_constraints
	WHERE constraint_name = 'FK_SUPPLIED_PRDUCT_MTRC_VL_IND' AND owner = 'CHAIN' AND table_name = 'PRODUCT_SUPPLIER_METRIC_VAL';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PRODUCT_SUPPLIER_METRIC_VAL DROP CONSTRAINT FK_SUPPLIED_PRDUCT_MTRC_VL_IND';
	END IF;
END;
/
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	FROM all_constraints
	WHERE constraint_name = 'FK_PRODUCT_SUPPLR_MTRC_VL_IND' AND owner = 'CHAIN' AND table_name = 'PRODUCT_SUPPLIER_METRIC_VAL';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PRODUCT_SUPPLIER_METRIC_VAL DROP CONSTRAINT FK_PRODUCT_SUPPLR_MTRC_VL_IND';
	END IF;
END;
/

DROP TABLE chain.product_metric_ind;

ALTER TABLE chain.product_metric_val ADD CONSTRAINT fk_prd_mtrc_val_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid);

ALTER TABLE chain.product_supplier_metric_val ADD CONSTRAINT fk_prd_suppl_mtrc_val_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid);	

ALTER TABLE chain.product_metric ADD CONSTRAINT fk_prd_mtrc_prd_mtrc_icon
	FOREIGN KEY (product_metric_icon_id)
	REFERENCES chain.product_metric_icon (product_metric_icon_id);

ALTER TABLE chain.product_metric_product_type ADD CONSTRAINT fk_prd_mtrc_prd_type_prd_type
	FOREIGN KEY (app_sid, product_type_id)
	REFERENCES chain.product_type (app_sid, product_type_id)
;

ALTER TABLE chain.product_metric_product_type ADD CONSTRAINT fk_prd_mtrc_prd_type_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid)
;


-- *** Grants ***
grant select, insert, update on chain.product_metric to csrimp;
grant select, insert, update on chain.product_metric_product_type to csrimp;
grant select, insert, update, delete on csrimp.chain_product_metric to tool_user;
grant select, insert, update, delete on csrimp.chain_prd_mtrc_prd_type to tool_user;
grant select, insert, update on chain.product_metric to CSR;
grant select, insert, update on chain.product_metric_product_type to CSR;

-- ** Cross schema constraints ***
ALTER TABLE chain.product_metric  ADD CONSTRAINT fk_product_metric_ind
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES csr.ind (app_sid, ind_sid)
;
-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO chain.product_metric_icon(product_metric_icon_id, description, icon_path) VALUES(1, 'Weight', '/fp/shared/images/productWeight.gif');
INSERT INTO chain.product_metric_icon(product_metric_icon_id, description, icon_path) VALUES(2, 'Volume', '/fp/shared/images/productVolume.gif');

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 10 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/

BEGIN


	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  								/* CT_COMPANIES */
		in_capability		=> 'Product metric values', 			/* PRODUCT_METRIC_VAL */
		in_perm_type		=> 0 									/* SPECIFIC_PERMISSION */
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  									/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product metric values of suppliers',/* PRODUCT_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 									/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  								/* CT_COMPANIES */
		in_capability		=> 'Supplier product metric values',	/* PRD_SUPP_METRIC_VAL */
		in_perm_type		=> 0 									/* SPECIFIC_PERMISSION */
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  									/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product metric values of suppliers',/* PRD_SUPP_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 									/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

create or replace procedure csr.createIndex(
	in_sql							in	varchar2
) authid current_user
as
	e_name_in_use					exception;
	pragma exception_init(e_name_in_use, -00955);
begin
	begin
		dbms_output.put_line(in_sql);
		execute immediate in_sql;
	exception
		when e_name_in_use then
			null;
	end;
end;
/

begin
	csr.createIndex('create index chain.ix_prd_mtrc_prd_mtrc_icon on chain.product_metric (product_metric_icon_id)');
	csr.createIndex('create index chain.ix_prd_mtrc_prd_type_prd_type on chain.product_metric_product_type (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_prd_mtrc_prd_type_prd_mtrc on chain.product_metric_product_type (app_sid, ind_sid)');
end;
/

drop procedure csr.createIndex;

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.product_metric_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.product_metric_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/
GRANT EXECUTE ON chain.product_metric_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/product_metric_pkg
@../schema_pkg

@../chain/chain_body
@../chain/product_body
@../schema_body
@../csrimp/imp_body
@../chain/product_metric_body

@update_tail
