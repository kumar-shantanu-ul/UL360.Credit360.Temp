-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.company_product (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id				NUMBER(10) NOT NULL,
	company_sid				NUMBER(10) NOT NULL,
	product_type_id			NUMBER(10) NOT NULL,
	lookup_key				VARCHAR2(1024),
	last_edited_by			NUMBER(10) NOT NULL,
	last_edited_dtm			DATE NOT NULL,
	CONSTRAINT pk_company_product PRIMARY KEY (app_sid, product_id)
);

ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_product
	FOREIGN KEY (app_sid, product_id) 
	REFERENCES chain.product(app_sid, product_id);

ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_company_sid
	FOREIGN KEY (app_sid, company_sid) 
	REFERENCES chain.company(app_sid, company_sid);

ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_product_typ
	FOREIGN KEY (app_sid, product_type_id) 
	REFERENCES chain.product_type (app_sid, product_type_id);

CREATE UNIQUE INDEX chain.company_product_lookup ON chain.company_product(app_sid, lower(lookup_key));

CREATE TABLE chain.company_product_version (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id						NUMBER(10) NOT NULL,
	version_number					NUMBER(10) NOT NULL,
	sku								VARCHAR2(1024) NOT NULL,
	product_active					NUMBER(1) NOT NULL,
	version_created_by				NUMBER(10) NOT NULL,
	version_created_dtm				DATE NOT NULL,
	version_activated_by			NUMBER(10),
	version_activated_dtm			DATE,
	version_deactivated_by			NUMBER(10),
	version_deactivated_dtm			DATE,
	CONSTRAINT pk_company_product_vers PRIMARY KEY (app_sid, product_id, version_number),
	CONSTRAINT ck_company_product_vers_active CHECK (product_active IN (0, 1))
);

ALTER TABLE chain.company_product_version ADD CONSTRAINT fk_chain_company_ver_product
	FOREIGN KEY (app_sid, product_id) 
	REFERENCES chain.company_product (app_sid, product_id);

CREATE TABLE chain.company_product_version_tr (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id				NUMBER(10) NOT NULL,
	version_number			NUMBER(10) NOT NULL,
	lang					VARCHAR2(10) NOT NULL,
	description				VARCHAR2(1024) NOT NULL,
	last_changed_dtm		DATE,
	CONSTRAINT pk_company_product_version_tr PRIMARY KEY (app_sid, product_id, version_number, lang)
);

ALTER TABLE chain.company_product_version_tr ADD CONSTRAINT fk_company_prod_vers_tr_prod
	FOREIGN KEY (app_sid, product_id, version_number) 
	REFERENCES chain.company_product_version (app_sid, product_id, version_number);


-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.v$customer_lang TO chain;

-- ** Cross schema constraints ***
ALTER TABLE chain.company_product
ADD CONSTRAINT fk_company_product_edit_user
FOREIGN KEY (app_sid, last_edited_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_create_usr
FOREIGN KEY (app_sid, version_created_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_activt_usr
FOREIGN KEY (app_sid, version_activated_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_deact_usr
FOREIGN KEY (app_sid, version_deactivated_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE OR REPLACE VIEW chain.v$company_product_current_vers AS
	SELECT product_id, max(version_number) current_version_number
	  FROM chain.company_product_version
	 WHERE (version_deactivated_dtm IS NULL AND version_activated_dtm IS NOT NULL)
		OR (version_deactivated_dtm IS NULL AND version_activated_dtm IS NULL)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  GROUP BY product_id;

CREATE OR REPLACE VIEW chain.v$company_product_version AS
	SELECT vers.product_id, vers.version_number, sku, version_created_by, version_created_dtm, version_activated_by, version_activated_dtm, version_deactivated_by, version_deactivated_dtm,
		   product_active, CASE WHEN (version_deactivated_dtm IS NULL AND version_activated_dtm IS NOT NULL) THEN 1 ELSE 0 END published
	  FROM chain.company_product_version vers
	  JOIN chain.v$company_product_current_vers cur ON vers.product_id = cur.product_id 
												   AND vers.version_number = cur.current_version_number
	  WHERE vers.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	

CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.product_id, tr.description product_name, cp.company_sid, c.name company_name, cp.product_type_id, pt.description product_type_name, ver.sku, cp.lookup_key, cp.last_edited_by, 
		   cu.full_name last_edited_name, last_edited_dtm, ver.product_active is_active, 0 weight_val, 'kg' weight_unit, 0 volume_val, 'cm3' volume_unit, 0 is_fully_certified, 1 is_owner, 0 is_supplier, 
       ver.version_number, ver.published
	  FROM chain.company_product cp
 LEFT JOIN csr.csr_user cu ON cp.last_edited_by = cu.csr_user_sid
	  JOIN chain.v$product_type pt ON cp.product_type_id = pt.product_type_id
	  JOIN chain.company c ON cp.company_sid = c.company_sid
	  JOIN chain.v$company_product_version ver ON cp.product_id = ver.product_id
	  JOIN chain.company_product_version_tr tr ON tr.product_id = cp.product_id AND tr.version_number = ver.version_number AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
   
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE CHAIN.company_product_pkg AS END;
/
GRANT EXECUTE ON CHAIN.company_product_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/company_product_body

@update_tail
