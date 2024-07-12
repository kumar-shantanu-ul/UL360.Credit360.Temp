-- Please update version.sql too -- this keeps clean builds in sync
define version=3280
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.gresb_property_sub_type (
    gresb_property_type_id      NUMBER(10),
    gresb_property_sub_type_id  NUMBER(10),
    name                        VARCHAR2(255),
    gresb_code                  VARCHAR2(255),
    pos                         NUMBER(2),
    CONSTRAINT pk_gresb_property_sub_type PRIMARY KEY (gresb_property_type_id, gresb_property_sub_type_id),
    CONSTRAINT uk_gresb_prop_sub_type_code UNIQUE (gresb_code)
);
-- Alter tables

ALTER TABLE csr.property_type DROP COLUMN gresb_prop_type_code;
ALTER TABLE csr.property_type ADD (gresb_property_type_id NUMBER(10));
ALTER TABLE csr.property_sub_type ADD (
	gresb_property_type_id NUMBER(10),
	gresb_property_sub_type_id NUMBER(10)
);
TRUNCATE TABLE csr.gresb_property_type;
ALTER TABLE csr.gresb_property_type DROP CONSTRAINT PK_GRESB_PROP_TYPE;
ALTER TABLE csr.gresb_property_type DROP COLUMN code;
ALTER TABLE csr.gresb_property_type ADD (
    gresb_property_type_id  NUMBER(10),
    pos                     NUMBER(2)
);
ALTER TABLE csr.gresb_property_type ADD CONSTRAINT pk_gresb_property_type PRIMARY KEY (gresb_property_type_id);
ALTER TABLE csr.property_type ADD CONSTRAINT fk_prop_type_gresb_prop_type
	FOREIGN KEY (gresb_property_type_id)
	REFERENCES csr.gresb_property_type(gresb_property_type_id);
ALTER TABLE csr.property_sub_type ADD CONSTRAINT fk_prop_stype_gresb_prop_stype
	FOREIGN KEY (gresb_property_type_id, gresb_property_sub_type_id)	
	REFERENCES csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id);

ALTER TABLE csrimp.property_type DROP COLUMN gresb_prop_type_code;
ALTER TABLE csrimp.property_type ADD (gresb_property_type_id NUMBER(10));
ALTER TABLE csrimp.property_sub_type ADD (
	gresb_property_type_id NUMBER(10),
	gresb_property_sub_type_id NUMBER(10)
);

CREATE INDEX csr.ix_prop_sub_type_gresb ON csr.property_sub_type (gresb_property_type_id, gresb_property_sub_type_id);

CREATE INDEX csr.ix_prop_type_gresb ON csr.property_type (gresb_property_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (1, 'Retail', 0);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (2, 'Office', 1);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (3, 'Industrial', 2);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (4, 'Residential', 3);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (5, 'Hotel', 4);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (6, 'Lodging, Leisure '||CHR(38)||' Recreation', 5);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (7, 'Education', 6);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (8, 'Technology/Science', 7);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (9, 'Healthcare', 8);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (10, 'Mixed use', 9);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (11, 'Other', 10);

INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 1, 'High Street', 'REHS', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 2, 'Retail Centers: Shopping Center', 'RCSC', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 3, 'Retail Centers: Strip Mall', 'RCSM', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 4, 'Retail Centers: Lifestyle Center', 'RCLC', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 5, 'Retail Centers: Warehouse', 'RCWH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 6, 'Restaurants/Bars', 'RRBA', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 7, 'Other', 'REOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 1, 'Corporate: Low-Rise Office', 'OCLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 2, 'Corporate: Mid-Rise Office', 'OCMI', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 3, 'Corporate: High-Rise Office', 'OCHI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 4, 'Medical Office', 'OFMO', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 5, 'Business Park', 'OFBP', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 6, 'Other', 'OFOT', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 1, 'Distribution Warehouse', 'INDW', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 2, 'Industrial Park', 'INIP', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 3, 'Manufacturing', 'INMA', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 4, 'Other', 'INOT', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 1, 'Multi-Family: Low-Rise Multi-Family', 'RMFL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 2, 'Multi-Family: Mid-Rise Multi Family', 'RMFM', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 3, 'Multi-Family: High-Rise Multi-Family', 'RMFH', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 4, 'Family Homes', 'RSFH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 5, 'Student Housing', 'RSSH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 6, 'Retirement Living', 'RSRL', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 7, 'Other', 'RSOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (5, 1, 'Hotel', 'HTL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 1, 'Lodging, Leisure '||CHR(38)||' Recreation', 'LLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 2, 'Indoor Arena', 'LLIA', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 3, 'Fitness Center', 'LLFC', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 4, 'Performing Arts', 'LLPA', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 5, 'Swimming Center', 'LLSC', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 6, 'Museum/Gallery', 'LLMG', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 7, 'Other', 'LLOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 1, 'School', 'EDSC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 2, 'University', 'EDUN', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 3, 'Library', 'EDLI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 4, 'Other', 'EDOT', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 1, 'Data Center', 'TSDC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 2, 'Laboratory/Life Sciences', 'TSLS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 3, 'Other', 'TSOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 1, 'Healthcare Center', 'HEHC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 2, 'Senior Homes', 'HESH', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 3, 'Other', 'HEOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 1, 'Office/Retail', 'XORE', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 2, 'Office/Residential', 'XORS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 3, 'Office/Industrial', 'XOIN', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 4, 'Other', 'XOTH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 1, 'Parking (Indoors)', 'OTPI', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 2, 'Self-Storage', 'OTSS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 3, 'Other', 'OTHR', 2);

UPDATE csr.module SET license_warning = 1 WHERE license_warning IS NULL AND module_id = 84; 

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../property_pkg

@../property_body
@../region_body
@../schema_body
@../util_script_body
@../csrimp/imp_body

@update_tail
