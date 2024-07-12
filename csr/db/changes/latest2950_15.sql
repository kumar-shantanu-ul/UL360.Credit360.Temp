-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE chain.grid_extension (
	grid_extension_id				NUMBER(10, 0)	NOT NULL,
	base_card_group_id				NUMBER(10)		NOT NULL,
	extension_card_group_id			NUMBER(10)		NOT NULL,
	record_name						VARCHAR2(255)	NOT NULL,
	CONSTRAINT pk_grid_extension PRIMARY KEY (grid_extension_id),
	CONSTRAINT fk_eg_base_card_group FOREIGN KEY (base_card_group_id) REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_eg_extension_card_group FOREIGN KEY (extension_card_group_id) REFERENCES chain.card_group (card_group_id)
);

CREATE UNIQUE INDEX CHAIN.uk_grid_extension ON CHAIN.grid_extension (base_card_group_id, extension_card_group_id);

CREATE TABLE chain.customer_grid_extension (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	grid_extension_id				NUMBER(10),
	enabled							NUMBER(1) DEFAULT 0,
	CONSTRAINT pk_customer_grid_extension PRIMARY KEY (app_sid, grid_extension_id),
	CONSTRAINT fk_cge_ge FOREIGN KEY (grid_extension_id) REFERENCES chain.grid_extension (grid_extension_id),
	CONSTRAINT chk_ege_enabled CHECK (enabled IN (0,1))
);

CREATE TABLE csrimp.chain_customer_grid_ext (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	grid_extension_id				NUMBER(10),
	enabled							NUMBER(1) DEFAULT 0,
	CONSTRAINT pk_customer_grid_extension PRIMARY KEY (csrimp_session_id, grid_extension_id)
);

-- Alter tables

-- *** Grants ***
GRANT INSERT ON chain.customer_grid_extension TO csrimp;
GRANT SELECT ON chain.customer_grid_extension TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE VIEW chain.v$grid_extension AS
	WITH enabled_card_groups AS 
	(
		SELECT DISTINCT cgc.app_sid, cgc.card_group_id
		  FROM chain.card_group_card cgc
		  JOIN chain.filter_type ft ON cgc.card_id = ft.card_id
	)
	SELECT grid_extension_id, 
		   base_card_group_id, 
		   cg1.name base_card_group_name, 
		   extension_card_group_id, 
		   cg2.name extension_card_group_name, 
		   record_name,
		   cg1.name  || ' -> ' || cg2.name name
	  FROM chain.grid_extension ge
	  JOIN chain.card_group cg1 ON cg1.card_group_id = ge.base_card_group_id
	  JOIN chain.card_group cg2 ON cg2.card_group_id = ge.extension_card_group_id
	 WHERE cg1.card_group_id IN (SELECT card_group_id FROM enabled_card_groups)
	   AND cg2.card_group_id IN (SELECT card_group_id FROM enabled_card_groups);	

-- *** Data changes ***
-- RLS

-- Data
	INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name) 
	VALUES (1, 41 /*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, 'company');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/helper_pkg
@../chain/company_filter_pkg
@../audit_report_pkg
@../user_report_pkg
@../property_report_pkg
@../schema_pkg

@../chain/chain_body
@../chain/filter_body
@../chain/helper_body
@../chain/company_filter_body
@../audit_report_body
@../user_report_body
@../property_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
