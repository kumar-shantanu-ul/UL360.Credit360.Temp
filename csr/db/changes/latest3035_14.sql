-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.PRODUCT_TYPE_TR(
    APP_SID                         NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PRODUCT_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    LANG                            VARCHAR2(10)      NOT NULL,
    DESCRIPTION                     VARCHAR2(1023),
    LAST_CHANGED_DTM_DESCRIPTION    DATE,
    CONSTRAINT PK_PRODUCT_TYPE_TR_DESCRIPTION PRIMARY KEY (APP_SID, PRODUCT_TYPE_ID, LANG),
	CONSTRAINT FK_PRODUCT_TYPE_IS FOREIGN KEY
    	(APP_SID, PRODUCT_TYPE_ID) REFERENCES CHAIN.PRODUCT_TYPE (APP_SID, PRODUCT_TYPE_ID)
    	ON DELETE CASCADE
)
;

CREATE TABLE CSRIMP.CHAIN_PRODUCT_TYPE_TR (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PRODUCT_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    LANG                            VARCHAR2(10)      NOT NULL,
    DESCRIPTION                     VARCHAR2(1023),
    LAST_CHANGED_DTM_DESCRIPTION    DATE,
    CONSTRAINT PK_PRODUCT_TYPE_TR PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_TYPE_ID, LANG),
	CONSTRAINT FK_PRODUCT_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- Alter tables
ALTER TABLE CHAIN.PRODUCT_TYPE ADD (
	NODE_TYPE					NUMBER(10, 0) 	DEFAULT 0 NOT NULL,
	ACTIVE						NUMBER(1, 0) 	DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_NODE_TYPE CHECK (NODE_TYPE >= 0 AND NODE_TYPE <= 1),
	CONSTRAINT CHK_ACTIVE CHECK (ACTIVE IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_PRODUCT_TYPE ADD (
	NODE_TYPE					NUMBER(10, 0) 	DEFAULT 0 NOT NULL,
	ACTIVE						NUMBER(1, 0) 	DEFAULT 1 NOT NULL
);


-- *** Grants ***
GRANT SELECT ON csr.v$customer_lang TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- cvs/csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$product_type AS
	SELECT pt.app_sid, pt.product_type_id, pt.parent_product_type_id, pttr.description, pt.lookup_key, pt.node_type, pt.active
	  FROM product_type pt, product_type_tr pttr
	 WHERE pt.app_sid = pttr.app_sid AND pt.product_type_id = pttr.product_type_id
	   AND pttr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (4, 201, 'Product Type');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg

@../chain/product_type_pkg
@../chain/product_type_body

@../chain/product_pkg
@../chain/product_body

GRANT EXECUTE ON chain.product_type_pkg TO web_user;

@update_tail
