-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.BSCI_RSP (
	rsp_id							NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_bsci_rsp PRIMARY KEY (rsp_id)
);

COMMENT ON TABLE CHAIN.BSCI_RSP IS 'desc="RSP"';
COMMENT ON COLUMN CHAIN.BSCI_RSP.LABEL IS 'desc="Label"';

-- Alter tables
ALTER TABLE CHAIN.BSCI_AUDIT
ADD AUDIT_RESULT VARCHAR2(255) NULL;

ALTER TABLE CHAIN.BSCI_AUDIT
DROP COLUMN AUDIT_SCORE;

ALTER TABLE CHAIN.BSCI_AUDIT
DROP COLUMN AUDIT_SUCCESS;

ALTER TABLE CHAIN.BSCI_SUPPLIER
ADD (
	RSP_ID							NUMBER(10) NULL,
	IS_AUDIT_IN_PROGRESS			NUMBER(1) NULL,
	AUDIT_IN_PROGRESS_DTM			DATE NULL,
	CONSTRAINT PK_BSCI_SUPPLIER PRIMARY KEY (COMPANY_SID),
	CONSTRAINT CHK_IS_AUDIT_IN_PROGRESS CHECK(IS_AUDIT_IN_PROGRESS IN (0,1)),
	CONSTRAINT FK_BSCI_SUPPLIER_RSP FOREIGN KEY (RSP_ID)
	REFERENCES CHAIN.BSCI_RSP (RSP_ID)
);

COMMENT ON TABLE CHAIN.BSCI_SUPPLIER IS 'desc="BSCI Supplier"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.APP_SID IS 'app_sid';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.COMPANY_SID IS 'company';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ADDRESS IS 'desc="Address"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CITY IS 'desc="City"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.INDUSTRY IS 'desc="Industry"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.COUNTRY IS 'desc="Country"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.POSTCODE IS 'desc="Postcode"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.REGION IS 'desc="Region"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.TERRITORY IS 'desc="Territory"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ADDRESS_LOCATION_TYPE IS 'desc="Address location type"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ALIAS IS 'desc="Alias"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_ANNOUNCEMENT_METHOD IS 'desc="Audit announcement method"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.FACTORY_CONTACT IS 'desc="Factory contact"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_EXPIRATION_DTM IS 'desc="Audit expiration date"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_IN_PROGRESS IS 'desc="Is audit in progress?"';	
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_RESULT IS 'desc="Audit result"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.BSCI_COMMENTS IS 'desc="BSCI comments"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.LINKED_PARTICIPANTS IS 'desc="Linked participants"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IN_COMMITMENTS IS 'desc="Commitments"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IN_SUPPLY_CHAIN IS 'desc="Supply chain"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.LEGAL_STATUS IS 'desc="Legal status"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NAME IS 'desc="Name"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NUMBER_OF_ASSOCIATES IS 'desc="Number of associates"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NUMBER_OF_BUILDINGS IS 'desc="Number of buildings"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PARTICIPANT_NAME IS 'desc="Participant name"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PRODUCT_GROUP IS 'desc="Product group"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PRODUCT_TYPE IS 'desc="Product type"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CODE_OF_CONDUCT_ACCEPTED IS 'desc="CoC accepted"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CODE_OF_CONDUCT_SIGNED IS 'desc="CoC signed"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_DTM IS 'desc="Audit date"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.SECTOR IS 'desc="Sector"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.WEBSITE IS 'desc="Website"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.YEAR_FOUNDED IS 'desc="Year founded"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.RSP_ID IS 'desc="RSP",enum,enum_desc_col=LABEL';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IS_AUDIT_IN_PROGRESS IS 'desc="Audit in progress",boolean';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_IN_PROGRESS_DTM IS 'desc="Audit in progress date"';


ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
ADD AUDIT_RESULT VARCHAR2(255) NULL;

ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
DROP COLUMN AUDIT_SCORE;

ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
DROP COLUMN AUDIT_SUCCESS;

ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER
ADD (
	RSP_ID							NUMBER(10) NULL,
	IS_AUDIT_IN_PROGRESS			NUMBER(1) NULL,
	AUDIT_IN_PROGRESS_DTM			DATE NULL
);



-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_bsci_09_audit_type_id 		security.security_pkg.T_SID_ID;
	v_bsci_14_audit_type_id 		security.security_pkg.T_SID_ID;
	v_score_type_id					csr.score_type.score_type_id%TYPE;
	PROCEDURE AddClosureType(
		in_audit_type_id			csr.internal_audit_type.internal_audit_type_id%TYPE,
		in_label					VARCHAR2,
		in_lookup					VARCHAR2
	) AS
		v_audit_closure_type_id			csr.audit_closure_type.audit_closure_type_id%TYPE;
	BEGIN
		BEGIN
			INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
			VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, in_label, 0, in_lookup)
			RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
		EXCEPTION
			WHEN dup_val_on_index THEN
				SELECT audit_closure_type_id
				  INTO v_audit_closure_type_id
				  FROM csr.audit_closure_type
				 WHERE app_sid = security.security_pkg.GetApp
				   AND lookup_key = in_lookup;
		END;
		
		BEGIN
			INSERT INTO csr.audit_type_closure_type (app_sid, internal_audit_type_id, audit_closure_type_id, re_audit_due_after, 
					re_audit_due_after_type, reminder_offset_days, reportable_for_months, ind_sid)
			VALUES (security.security_pkg.GetApp, in_audit_type_id, v_audit_closure_type_id, NULL, NULL, NULL, NULL, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN NULL;
		END;
	END;
	PROCEDURE DeleteScoreType(
		in_score_type_id	IN	csr.score_type.score_type_id%TYPE
	)
	AS
	BEGIN
		DELETE FROM csr.current_supplier_score
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		
		DELETE FROM csr.supplier_score_log
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		 
		DELETE FROM csr.score_threshold
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		
		DELETE FROM csr.score_type
		 WHERE score_type_id=in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
	END;
BEGIN
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (1, 'Yes');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (2, 'No');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (3, 'Orphan');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (4, 'Idle');
	
	FOR r IN (
		SELECT bo.app_sid, c.host
		  FROM chain.bsci_options bo
		  JOIN csr.customer c ON c.app_sid = bo.app_sid
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		UPDATE chain.reference
		   SET label = 'BSCI DBID'
		 WHERE lookup_key = 'BSCI_ID'
		   AND app_sid = r.app_sid;
		
		UPDATE chain.bsci_supplier s
		   SET (is_audit_in_progress, audit_in_progress_dtm) = (
			SELECT CASE WHEN UPPER(audit_in_progress) = 'NO' THEN 0 ELSE 1 END,
				CASE WHEN INSTR(audit_in_progress, '-') > 0 THEN 
					TO_DATE(TRIM(SUBSTR(audit_in_progress, INSTR(audit_in_progress, '-') + 1)), 'yyyy-mm-dd') 
				ELSE NULL END
			  FROM chain.bsci_supplier
			 WHERE company_sid = s.company_sid
		   );
		
		SELECT internal_audit_type_id
		  INTO v_bsci_09_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE app_sid = security.security_pkg.GetApp
		   AND UPPER(lookup_key) = 'BSCI_2009';
		
		AddClosureType(v_bsci_09_audit_type_id, 'Non-compliant', 'NON_COMPLIANT');
		AddClosureType(v_bsci_09_audit_type_id, 'Improvements needed', 'IMPROVEMENTS_NEEDED');
		AddClosureType(v_bsci_09_audit_type_id, 'Good', 'GOOD');
		   
		SELECT internal_audit_type_id
		  INTO v_bsci_14_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE app_sid = security.security_pkg.GetApp
		   AND UPPER(lookup_key) = 'BSCI_2014';
		   
		AddClosureType(v_bsci_14_audit_type_id, 'A', 'A');
		AddClosureType(v_bsci_14_audit_type_id, 'B', 'B');
		AddClosureType(v_bsci_14_audit_type_id, 'C', 'C');
		AddClosureType(v_bsci_14_audit_type_id, 'D', 'D');
		AddClosureType(v_bsci_14_audit_type_id, 'E', 'E');
		AddClosureType(v_bsci_14_audit_type_id, 'Zero tolerance', 'ZERO_TOLERANCE');
		
		-- Set closure types for existing audits
		UPDATE csr.internal_audit ia
		   SET ia.audit_closure_type_id = (
			SELECT ct.audit_closure_type_id
			  FROM csr.audit_closure_type ct
			  JOIN csr.score_threshold st ON UPPER(st.description) = UPPER(ct.label)
			  JOIN csr.audit_type_closure_type atct ON atct.audit_closure_type_id = ct.audit_closure_type_id
			 WHERE ia.nc_score_thrsh_id = st.score_threshold_id
			)
		 WHERE ia.internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id)
		   AND EXISTS (
			SELECT 1
			  FROM csr.audit_closure_type ct
			  JOIN csr.score_threshold st ON UPPER(st.description) = UPPER(ct.label)
			  JOIN csr.audit_type_closure_type atct ON atct.audit_closure_type_id = ct.audit_closure_type_id
			 WHERE ia.nc_score_thrsh_id = st.score_threshold_id
		   );
		
		UPDATE chain.bsci_audit ba
		   SET ba.audit_result = (
			SELECT act.lookup_key
			  FROM csr.internal_audit ia
			  JOIN csr.audit_closure_type act ON act.audit_closure_type_id = ia.audit_closure_type_id
			 WHERE ia.internal_audit_sid = ba.internal_audit_sid
		   )
		 WHERE EXISTS (
			SELECT 1
			  FROM csr.internal_audit ia
			 WHERE ia.internal_audit_sid = ba.internal_audit_sid
		 );
		
		-- Get rid of the old score type
		UPDATE csr.internal_audit
		   SET nc_score_thrsh_id = NULL, 
		       nc_score = NULL
		 WHERE internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id);
		 
		UPDATE csr.internal_audit_type
		   SET nc_score_type_id = NULL
		 WHERE internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id);
		
		BEGIN
			SELECT score_type_id
			  INTO v_score_type_id
			  FROM csr.score_type
			 WHERE UPPER(label) = 'BSCI AUDIT';
			
			DeleteScoreType(v_score_type_id);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
		
		DELETE FROM csr.audit_type_closure_type
		 WHERE audit_closure_type_id IN (
			SELECT audit_closure_type_id
			  FROM csr.audit_closure_type
			 WHERE lookup_key IN ('BSCI_SUCCESS', 'BSCI_FAILURE')
		 );
		
		DELETE FROM csr.audit_closure_type
		 WHERE lookup_key IN ('BSCI_SUCCESS', 'BSCI_FAILURE');
		
		security.user_pkg.Logoff(security.security_pkg.GetAct);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\bsci_pkg

@..\enable_body
@..\schema_body
@..\chain\bsci_body
@..\csrimp\imp_body

@update_tail
