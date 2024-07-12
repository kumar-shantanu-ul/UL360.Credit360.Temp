-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.doc_type
(
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	doc_type_id						NUMBER(10,0) NOT NULL,
	doc_library_sid					NUMBER(10,0) NOT NULL,
	name							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_doc_type			PRIMARY KEY (app_sid, doc_type_id),
    CONSTRAINT uk_doc_type_name		UNIQUE (app_sid, doc_library_sid, name)
);

CREATE TABLE csrimp.doc_type
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	doc_type_id						NUMBER(10,0) NOT NULL,
	doc_library_sid					NUMBER(10,0) NOT NULL,
	name							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_doc_type			PRIMARY KEY (csrimp_session_id, doc_type_id),
    CONSTRAINT fk_doc_type_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_doc_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_type_id					NUMBER(10)	NOT NULL,
	new_doc_type_id					NUMBER(10)	NOT NULL,
    CONSTRAINT fk_map_doc_type_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE SEQUENCE csr.doc_type_id_seq;

-- Alter tables
ALTER TABLE csrimp.doc_version ADD doc_type_id NUMBER(10,0) NULL;

ALTER TABLE csr.doc_version ADD 
(
	doc_type_id NUMBER(10,0) NULL,
	CONSTRAINT fk_doc_version_doc_type 
		FOREIGN KEY (app_sid, doc_type_id) 
		REFERENCES csr.doc_type (app_sid, doc_type_id)
);

ALTER TABLE csr.doc_type ADD 
(
	CONSTRAINT fk_doc_type_doc_lib
		FOREIGN KEY (app_sid, doc_library_sid)
		REFERENCES csr.doc_library (app_sid, doc_library_sid)
);

CREATE INDEX csr.ix_doc_version_doc_type ON csr.doc_version (app_sid, doc_type_id);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.doc_type TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.map_doc_type TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.doc_type TO csrimp;
GRANT SELECT ON csr.doc_type_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- ../create_views.sql
CREATE OR REPLACE VIEW csr.v$doc_current AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   df.lifespan,
		   dv.version, dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id;

CREATE OR REPLACE VIEW csr.v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan,
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status,
		   dd.app_sid, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL;

CREATE OR REPLACE VIEW csr.v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version,
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status, doc_type_id, doc_type_name
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') OR pending_version IS NULL
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,
		   df.lifespan,
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm,
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status, 
		   dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dvp.doc_type_id
	   WHERE (NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL) OR dc.version IS null;


-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (87, 'Document library - document types', 'EnableDocLibDocTypes', 'Enables document types in the document library.', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../doc_pkg
@../doc_lib_pkg
@../enable_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../csr_app_body
@../doc_body
@../doc_lib_body
@../enable_body
@../initiative_doc_body
@../schema_body
@../section_body
@../csrimp/imp_body

@update_tail
