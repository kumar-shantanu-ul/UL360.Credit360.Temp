-- Please update version.sql too -- this keeps clean builds in sync
define version=3239
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE csr.compliance_item_desc_hist_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.compliance_item_desc_hist (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	compliance_item_desc_hist_id	NUMBER(10, 0)	NOT NULL,
	compliance_item_id				NUMBER(10, 0)	NOT NULL,
	compliance_language_id			NUMBER(10, 0)	NOT NULL,
	major_version					NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	title							VARCHAR2(1024)	NOT NULL,
	summary							VARCHAR2(4000),
	details							CLOB,
	citation						VARCHAR2(4000),
	description						CLOB,
	change_dtm						DATE,
	CONSTRAINT pk_compliance_item_desc_hist PRIMARY KEY (app_sid, compliance_item_desc_hist_id),
	CONSTRAINT fk_comp_item_dsc_hst_comp_item
		FOREIGN KEY (app_sid, compliance_item_id)
		REFERENCES csr.compliance_item (app_sid, compliance_item_id),
	CONSTRAINT fk_comp_item_dsc_hst_comp_lang
		FOREIGN KEY (app_sid, compliance_language_id)
		REFERENCES csr.compliance_language (app_sid, compliance_language_id)
);


CREATE TABLE csrimp.compliance_item_desc_hist (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_desc_hist_id	NUMBER(10, 0)	NOT NULL,
	compliance_item_id				NUMBER(10, 0)	NOT NULL,
	compliance_language_id			NUMBER(10, 0)	NOT NULL,
	major_version					NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	title							VARCHAR2(1024)	NOT NULL,
	summary							VARCHAR2(4000),
	details							CLOB,
	citation						VARCHAR2(4000),
	description						CLOB,
	change_dtm						DATE,
	CONSTRAINT pk_compliance_item_desc_hist PRIMARY KEY (csrimp_session_id, compliance_item_desc_hist_id),
	CONSTRAINT fk_compliance_item_desc_hist
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item_desc_hist (
	csrimp_session_id					NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_desc_hist_id			NUMBER(10)	NOT NULL,
	new_comp_item_desc_hist_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_comp_item_desc_hist PRIMARY KEY (csrimp_session_id, old_comp_item_desc_hist_id),
	CONSTRAINT uk_map_comp_item_desc_hist UNIQUE (csrimp_session_id, new_comp_item_desc_hist_id),
	CONSTRAINT fk_map_comp_item_desc_hist FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE INDEX csr.ix_comp_item_desc_hist_comp_it ON csr.compliance_item_desc_hist (app_sid, compliance_item_id);
CREATE INDEX csr.ix_comp_item_desc_hist_comp_lg ON csr.compliance_item_desc_hist (app_sid, compliance_language_id);


-- Alter tables

ALTER TABLE csr.compliance_item_description ADD (
	major_version				NUMBER(10)		DEFAULT 1 NOT NULL,
	minor_version				NUMBER(10)		DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.compliance_item_description ADD (
	major_version				NUMBER(10)		DEFAULT 1 NOT NULL,
	minor_version				NUMBER(10)		DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.doc_folder MODIFY (
	description				NULL
);



-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_desc_hist TO csrimp;
GRANT SELECT ON csr.compliance_item_desc_hist_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_desc_hist TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.compliance_item_description cid
   SET (cid.major_version, cid.minor_version) =
		(SELECT ci.major_version, ci.minor_version
		  FROM csr.compliance_item ci
		 WHERE ci.app_sid = cid.app_sid
		   AND ci.compliance_item_id = cid.compliance_item_id
		)
;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg

@../csr_app_body
@../schema_body

@../csrimp/imp_body


@update_tail
