-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options ADD (
	PERMIT_DOC_LIB_SID 			NUMBER(10)
);

ALTER TABLE csr.doc_folder ADD (
	PERMIT_ITEM_ID	 			NUMBER(10)
);

ALTER TABLE csr.doc_folder ADD CONSTRAINT FK_DOC_FOLDER_PERMIT_ITEM_ID
	FOREIGN KEY (app_sid, permit_item_id)
	REFERENCES csr.compliance_permit(app_sid, compliance_permit_id)
;

ALTER TABLE csr.compliance_options ADD CONSTRAINT FK_COMP_OPTIONS_DOC_LIB_SID
	FOREIGN KEY (app_sid, permit_doc_lib_sid)
	REFERENCES csr.doc_library (app_sid, doc_library_sid)
;

ALTER TABLE csrimp.compliance_options ADD (
	PERMIT_DOC_LIB_SID 			NUMBER(10)
);

ALTER TABLE csrimp.doc_folder ADD (
	PERMIT_ITEM_ID	 			NUMBER(10)
);

CREATE INDEX csr.ix_compli_op_permit_doc_lib ON csr.compliance_options (app_sid, permit_doc_lib_sid);

CREATE INDEX csr.ix_doc_folder_compli_permit ON csr.doc_folder (app_sid, permit_item_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- ../create_views.sql
CREATE OR REPLACE VIEW csr.v$doc_folder AS
	SELECT df.doc_folder_sid, df.description, df.lifespan_is_override, df.lifespan,
		   df.approver_is_override, df.approver_sid, df.company_sid, df.is_system_managed,
		   df.property_sid, dfnt.lang, dfnt.translated, df.permit_item_id
	  FROM doc_folder df
	  JOIN doc_folder_name_translation dfnt ON df.app_sid = dfnt.app_sid AND df.doc_folder_sid = dfnt.doc_folder_sid
	 WHERE dfnt.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 21, 'Permit document library', '/csr/site/compliance/controls/DocLibTab.js', 
	'Credit360.Compliance.Controls.DocLibTab', 'Credit360.Compliance.Plugins.DocLibTab', 'Shows document library for a permit item.');

DECLARE
	v_comp_lib_folder_sid		NUMBER(10);
	v_doclib_sid				NUMBER(10);
	v_act_id					security.security_pkg.T_ACT_ID;
	PROCEDURE CreateLibrary(
		in_parent_sid_id			IN	security.security_pkg.T_SID_ID,
		in_library_name				IN	security.security_pkg.T_SO_NAME,
		in_documents_name			IN	security.security_pkg.T_SO_NAME,
		in_trash_name				IN	security.security_pkg.T_SO_NAME,
		in_app_sid					IN	security.security_pkg.T_SID_ID,
		out_doc_library_sid			OUT	security.security_pkg.T_SID_ID
	)
	AS
		v_documents_sid				security.security_pkg.T_SID_ID;
		v_trash_folder_sid			security.security_pkg.T_SID_ID;
		PROCEDURE CreateFolder(
			in_parent_sid					IN	security.security_pkg.T_SID_ID,
			in_name							IN	security.security_pkg.T_SO_NAME,
			in_description					IN	csr.doc_folder.description%TYPE DEFAULT EMPTY_CLOB(),
			in_approver_is_override			IN	csr.doc_folder.approver_is_override%TYPE DEFAULT 0,
			in_approver_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_lifespan_is_override			IN	csr.doc_folder.lifespan_is_override%TYPE DEFAULT 0,
			in_lifespan						IN	csr.doc_folder.lifespan%TYPE DEFAULT NULL,
			in_company_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_property_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_is_system_managed			IN	csr.doc_folder.is_system_managed%TYPE DEFAULT 0,
			in_permit_item_id				IN  security.security_pkg.T_SID_ID DEFAULT NULL,
			out_sid_id						OUT	security.security_pkg.T_SID_ID
		)
		AS
			v_lifespan						csr.doc_folder.lifespan%TYPE;
			v_approver_sid					security.security_pkg.T_SID_ID;
			v_company_sid					security.security_pkg.T_SID_ID;
			v_property_sid					security.security_pkg.T_SID_ID;
			v_parent_is_doc_lib				security.security_pkg.T_SID_ID;
			v_name							security.security_pkg.T_SO_NAME := in_name;
			v_permit_item_id				security.security_pkg.T_SID_ID;
		BEGIN
			-- For system managed folders e.g. Documents, Recycle bin keep so name else set so name to null
			IF in_is_system_managed = 0 THEN
				v_name := NULL;
			END IF;
		
			security.Securableobject_Pkg.CreateSO(security.security_pkg.GetACT(), in_parent_sid, 
				security.class_pkg.GetClassId('DocFolder'), v_name, out_sid_id);
			
			BEGIN
				SELECT lifespan, approver_sid, company_sid, property_sid, permit_item_id
				  INTO v_lifespan, v_approver_sid, v_company_sid, v_property_sid, v_permit_item_id
				  FROM csr.doc_folder
				 WHERE doc_folder_sid = in_parent_sid;
			EXCEPTION	
				WHEN NO_DATA_FOUND THEN
					NULL; -- ignore - probably this is under the root
			END;
			
			INSERT INTO csr.doc_folder (doc_folder_sid, description, lifespan, approver_sid, company_sid, 
									property_sid, is_system_managed, permit_item_id)		  
				SELECT out_sid_id doc_folder_sid, in_description description, 
					CASE WHEN in_lifespan_is_override = 1 THEN in_lifespan ELSE v_lifespan END, 
					CASE WHEN in_approver_is_override = 1 THEN in_approver_sid ELSE v_approver_sid END,
					NVL(in_company_sid, v_company_sid), NVL(in_property_sid, v_property_sid), in_is_system_managed,
					NVL(in_permit_item_id, v_permit_item_id)
				  FROM dual;
		
			INSERT INTO csr.doc_folder_name_translation (doc_folder_sid, lang, translated)
			SELECT out_sid_id, lang, in_name
			  FROM csr.v$customer_lang;
		END;
	BEGIN
		security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), in_parent_sid_id, 
			security.class_pkg.GetClassId('DocLibrary'), in_library_name, out_doc_library_sid);
		
		CreateFolder(
			in_parent_sid			=> out_doc_library_sid, 
			in_name					=> in_documents_name,
			in_is_system_managed	=> 1,
			out_sid_id				=> v_documents_sid
		);
	
		CreateFolder(
			in_parent_sid			=> out_doc_library_sid, 
			in_name					=> in_trash_name,
			in_is_system_managed	=> 1,
			out_sid_id				=> v_trash_folder_sid
		);
	
		INSERT INTO csr.doc_library (app_sid, doc_library_sid, documents_sid, trash_folder_sid)
		VALUES (in_app_sid, out_doc_library_sid, v_documents_sid, v_trash_folder_sid);
	END;	
BEGIN
	security.user_pkg.LogonAdmin();
	
	FOR r IN (
		SELECT co.app_sid, c.host 
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		
		BEGIN
			security.SecurableObject_pkg.CreateSO(v_act_id, r.app_sid, security.security_pkg.SO_CONTAINER, 'ComplianceDocLibs', v_comp_lib_folder_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_comp_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'ComplianceDocLibs');
		END;

		BEGIN
			CreateLibrary(
				v_comp_lib_folder_sid,
				'Permits',
				'Documents',
				'Recycle bin',
				r.app_sid,
				v_doclib_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_doclib_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'ComplianceDocLibs/Permits');
		END;

		UPDATE csr.compliance_options
		   SET permit_doc_lib_sid = v_doclib_sid
		 WHERE app_sid = r.app_sid;
		 
		 security.user_pkg.LogonAdmin();
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg
@../doc_folder_pkg

@../permit_body
@../doc_folder_body
@../doc_body
@../enable_body
@../schema_body
@../csrimp/imp_body

@update_tail
