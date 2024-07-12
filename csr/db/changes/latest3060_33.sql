-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_item
ADD compliance_item_type NUMBER(10);

UPDATE csr.compliance_item ci
  SET ci.compliance_item_type = (
	  SELECT NVL2(creq.compliance_item_id, 0, NVL2(creg.compliance_item_id, 1, NVL2(cc.compliance_item_id, 2, 0))) compliance_type
	    FROM csr.compliance_item ci2
	    LEFT JOIN csr.compliance_regulation creg on ci2.compliance_item_id = creg.compliance_item_id
	    LEFT JOIN csr.compliance_requirement creq on ci2.compliance_item_id = creq.compliance_item_id
	    LEFT JOIN csr.compliance_permit_condition cc on ci2.compliance_item_id = cc.compliance_item_id
	   WHERE ci.compliance_item_id = ci2.compliance_item_Id
);

ALTER TABLE csr.compliance_item
MODIFY compliance_item_type NOT NULL;

ALTER TABLE csrimp.compliance_item
ADD compliance_item_Type NUMBER(10) NOT NULL;

DROP INDEX csr.uk_compliance_item_ref;

CREATE UNIQUE INDEX csr.uk_compliance_item_ref ON csr.compliance_item (
	DECODE(compliance_item_type, 2, TO_CHAR("COMPLIANCE_ITEM_ID"), DECODE("SOURCE", 0, NVL("REFERENCE_CODE", TO_CHAR("COMPLIANCE_ITEM_ID")), TO_CHAR("COMPLIANCE_ITEM_ID")))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (
	csr.plugin_id_seq.NEXTVAL, 21, 
	'Permit conditions tab', 
	'/csr/site/compliance/controls/PermitConditionsTab.js', 
	'Credit360.Compliance.Controls.PermitConditionsTab', 
	'Credit360.Compliance.Plugins.PermitConditionsTab', 
	'Shows permit conditions.'
);

INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.COMPLIANCE.PERMIT', 'activeTab', 'STRING', 'Stores the last active plugin tab');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\compliance_pkg

@..\compliance_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\schema_body
@..\imp_body
@..\enable_body

@update_tail
