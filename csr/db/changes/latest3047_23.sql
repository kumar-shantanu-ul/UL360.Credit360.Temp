-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.reference_validation(
	REFERENCE_VALIDATION_ID 	NUMBER(10) NOT NULL,
	DESCRIPTION 				VARCHAR2(255) NOT NULL,
	VALIDATION_REGEX			VARCHAR2(255) NULL,
	VALIDATION_TEXT 			VARCHAR2(255) NULL,
	CONSTRAINT PK_REFERENCE_VALIDATION PRIMARY KEY (REFERENCE_VALIDATION_ID)
);

-- Alter tables
ALTER TABLE chain.reference ADD REFERENCE_VALIDATION_ID NUMBER(10) DEFAULT 0;
ALTER TABLE csrimp.chain_reference ADD REFERENCE_VALIDATION_ID NUMBER(10);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	UPDATE chain.reference
	   SET reference_validation_id = 1
	 WHERE lookup_key = 'BSCI_ID' OR lookup_key ='HIGGID';
	
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY','ACT'));
END;
/

INSERT INTO chain.reference_validation(reference_validation_id, description, validation_regex, validation_text)
  	 VALUES (0, 'Any', NULL, NULL);

INSERT INTO chain.reference_validation(reference_validation_id, description, validation_regex, validation_text)
  	 VALUES (1, 'Numeric only', '^[0-9]+$', 'Please enter only numbers');

INSERT INTO chain.reference_validation(reference_validation_id, description, validation_regex, validation_text)
   	 VALUES (2, 'Text only', '^[a-zA-Z]+$', 'Please enter only letters');


ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT FK_REFERENCE_VALIDATION
	FOREIGN KEY (REFERENCE_VALIDATION_ID)
	REFERENCES CHAIN.REFERENCE_VALIDATION(REFERENCE_VALIDATION_ID)
;

ALTER TABLE CHAIN.REFERENCE MODIFY REFERENCE_VALIDATION_ID NOT NULL;

BEGIN
	UPDATE chain.company_reference
	   SET value = NULL
	 WHERE company_reference_id IN (
		 SELECT company_reference_id
		   FROM (
			 SELECT company_reference_id, CASE WHEN LENGTH(TRIM(TRANSLATE(value, '0123456789', ' '))) IS NOT NULL THEN 1 ELSE 0 END not_numeric
			   FROM chain.company_reference cr
			   JOIN chain.reference r ON r.reference_id = cr.reference_id
			  WHERE r.lookup_key = 'HIGGID'
		   )
		   WHERE not_numeric = 1
	   );
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/helper_pkg

@../enable_body
@../schema_body
@../chain/higg_setup_body
@../chain/chain_body
@../chain/helper_body
@../chain/company_body
@../csrimp/imp_body

@update_tail
