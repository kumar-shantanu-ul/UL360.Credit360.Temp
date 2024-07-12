-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=41
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.doc_folder_name_translation (
	app_sid				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	doc_folder_sid		NUMBER(10, 0)		NOT NULL,
	lang				VARCHAR2(10)		NOT NULL,
	translated			VARCHAR2(1023)		NOT NULL,
	CONSTRAINT pk_doc_folder_name_translation PRIMARY KEY (app_sid, doc_folder_sid, lang)
);

CREATE TABLE csrimp.doc_folder_name_translation (
	csrimp_session_id	NUMBER(10, 0) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	doc_folder_sid		NUMBER(10, 0)		NOT NULL,
	lang				VARCHAR2(10)		NOT NULL,
	translated			VARCHAR2(1023)		NOT NULL,
	CONSTRAINT pk_doc_folder_name_translation PRIMARY KEY (csrimp_session_id, doc_folder_sid, lang)
);

-- Alter tables
ALTER TABLE csr.doc_folder_name_translation ADD CONSTRAINT fk_df_name_translation_df
	FOREIGN KEY (app_sid, doc_folder_sid)
	REFERENCES csr.doc_folder(app_sid, doc_folder_sid);

ALTER TABLE csrimp.doc_folder_name_translation ADD CONSTRAINT fk_doc_folder_name_tr_is
	FOREIGN KEY (csrimp_session_id)
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

-- *** Grants ***
GRANT INSERT, UPDATE ON csr.doc_folder_name_translation TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.doc_folder_name_translation TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$doc_folder AS
	SELECT df.doc_folder_sid, df.description, df.lifespan_is_override, df.lifespan,
		   df.approver_is_override, df.approver_sid, df.company_sid, df.is_system_managed,
		   df.property_sid, dfnt.lang, dfnt.translated
	  FROM doc_folder df
	  JOIN doc_folder_name_translation dfnt ON df.app_sid = dfnt.app_sid AND df.doc_folder_sid = dfnt.doc_folder_sid
	 WHERE dfnt.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);

		INSERT INTO csr.doc_folder_name_translation (doc_folder_sid, lang, translated)
		SELECT df.doc_folder_sid, cl.lang, NVL(so.name, so.sid_id) AS translated
		  FROM csr.doc_folder df
		  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
		 CROSS JOIN csr.v$customer_lang cl
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM csr.doc_folder_name_translation
			 WHERE doc_folder_sid = df.doc_folder_sid 
			   AND lang = cl.lang
		 );

		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../doc_folder_pkg

@../schema_body
@../csr_app_body
@../doc_lib_body
@../doc_folder_body
@../supplier_body
@../csrimp/imp_body

@update_tail
