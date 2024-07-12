-- Please update version.sql too -- this keeps clean builds in sync
define version=3231
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_item_description(
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id			NUMBER(10, 0)	NOT NULL,
	compliance_language_id		NUMBER(10, 0)	NOT NULL,
	title						VARCHAR2(1024)	NOT NULL,
	summary						VARCHAR2(4000),
	details						CLOB,
	citation					VARCHAR2(4000),
	CONSTRAINT pk_compliance_item_description
		PRIMARY KEY (app_sid, compliance_item_id, compliance_language_id),
	CONSTRAINT fk_comp_item_desc_comp_lang
		FOREIGN KEY (app_sid, compliance_language_id)
		REFERENCES csr.compliance_language (app_sid, compliance_language_id)
);

CREATE INDEX csr.ix_compliance_it_compliance_la on csr.compliance_item_description (app_sid, compliance_language_id);

GRANT CREATE TABLE TO csr;

/* COMPLIANCE ITEM TITLE INDEX */
DROP INDEX csr.ix_ci_title_search;
CREATE INDEX csr.ix_ci_title_search on csr.compliance_item_description(title) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM SUMMARY INDEX */
DROP INDEX csr.ix_ci_summary_search;
CREATE INDEX csr.ix_ci_summary_search on csr.compliance_item_description(summary) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM DETAILS INDEX */
DROP INDEX csr.ix_ci_details_search;
CREATE INDEX csr.ix_ci_details_search on csr.compliance_item_description(details) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM CITATION INDEX */
DROP INDEX csr.ix_ci_citation_search;
CREATE INDEX csr.ix_ci_citation_search on csr.compliance_item_description(citation) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');


CREATE TABLE csrimp.compliance_item_description(
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id			NUMBER(10, 0)	NOT NULL,
	compliance_language_id		NUMBER(10, 0)	NOT NULL,
	title						VARCHAR2(1024)	NOT NULL,
	summary						VARCHAR2(4000),
	details						CLOB,
	citation					VARCHAR2(4000),
	CONSTRAINT pk_compliance_item_description 
		PRIMARY KEY (csrimp_session_id, compliance_item_id, compliance_language_id),
	CONSTRAINT fk_compliance_item_description
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_description TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_description TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
EXEC security.user_pkg.logonadmin('');

INSERT INTO csr.compliance_language (app_sid, compliance_language_id , lang_id)
	 SELECT co.app_sid, csr.compliance_lang_id_seq.NEXTVAL, l.lang_id FROM csr.compliance_options co, aspen2.lang l
	  WHERE lang = 'en';

INSERT INTO csr.compliance_item_description (app_sid, compliance_item_id, compliance_language_id, title, summary, details, citation)  
	 SELECT ci.app_sid, ci.compliance_item_id, cl.compliance_language_id, ci.title, ci.summary, ci.details, ci.citation
	   FROM csr.compliance_item ci, csr.compliance_language cl
	   JOIN aspen2.lang l ON l.lang_id = cl.lang_id
	  WHERE l.lang = 'en' 
	    AND ci.app_sid = cl.app_sid;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@..\schema_pkg

@..\schema_body
@..\csr_app_body
@..\enable_body
@..\compliance_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\csrimp\imp_body

@update_tail
