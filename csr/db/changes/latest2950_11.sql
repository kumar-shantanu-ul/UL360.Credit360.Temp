-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
CREATE TABLE CSR.TRANS_ATTR_TYPE(
    TYPE_NAME     VARCHAR2(256)    NOT NULL,
    BASIC_TYPE    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_TRANS_ATTR_TYPE PRIMARY KEY (TYPE_NAME)
);

CREATE TABLE CSR.TRANS_ATTR_UNIT(
    TYPE_NAME    VARCHAR2(256)    NOT NULL,
    UOM          VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_TRANS_ATTR_UNIT PRIMARY KEY (TYPE_NAME, UOM)
);

CREATE TABLE CSR.TRANS_ATTR_FOR_BUILDING(
    ATTR_NAME       VARCHAR2(256)    NOT NULL,
    TYPE_NAME       VARCHAR2(256)    NOT NULL,
    LABEL           VARCHAR2(256)    NOT NULL,
    IS_MANDATORY    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_MANDATORY IN(0,1)),
    CONSTRAINT PK_TRANS_ATTR_FOR_BUILDING PRIMARY KEY (ATTR_NAME)
);

BEGIN
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('m'||UNISTR('\00B3')||'', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('m'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'NUMERIC');

	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('m'||UNISTR('\00B3')||'', 'm'||UNISTR('\00B3')||'');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('m'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'');

	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('waterUseTotal', 'm'||UNISTR('\00B3')||'', 'Water Use (All Water Sources)');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('indoorWaterUseTotalAllWaterSources', 'm'||UNISTR('\00B3')||'', 'Indoor Water Use (All Water Sources)');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('indoorWaterIntensityAllWaterSources', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'Indoor Water Intensity (All Water Sources)');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('outdoorWaterUseTotalAllWaterSources', 'm'||UNISTR('\00B3')||'', 'Outdoor Water Use (All Water Sources)');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedPotableWaterMixedUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Potable Water - Mixed Indoor/Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedPotableWaterIndoorUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Potable Water - Indoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedPotableWaterIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'Municipally Supplied Potable Water - Indoor Intensity');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedPotableWaterOutdoorUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Potable Water - Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedReclaimedWaterMixedUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedReclaimedWaterIndoorUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Reclaimed Water - Indoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedReclaimedWaterIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'Municipally Supplied Reclaimed Water - Indoor Intensity');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('municipallySuppliedReclaimedWaterOutdoorUse', 'm'||UNISTR('\00B3')||'', 'Municipally Supplied Reclaimed Water - Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('alternativeWaterGeneratedOnsiteMixedUse', 'm'||UNISTR('\00B3')||'', 'Alternative Water Generated On Site - Mixed Indoor/Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('alternativeWaterGeneratedOnsiteIndoorUse', 'm'||UNISTR('\00B3')||'', 'Alternative Water Generated On Site - Indoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('alternativeWaterGeneratedOnsiteIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'Alternative Water Generated On Site - Indoor Intensity');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('alternativeWaterGeneratedOnsiteOutdoorUse', 'm'||UNISTR('\00B3')||'', 'Alternative Water Generated On Site - Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('otherWaterSourcesMixedUse', 'm'||UNISTR('\00B3')||'', 'Other Water Sources - Mixed Indoor/Outdoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('otherWaterSourcesIndoorUse', 'm'||UNISTR('\00B3')||'', 'Other Water Sources - Indoor Use');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('otherWaterSourcesIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'Other Water Sources - Indoor Intensity');
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label) VALUES ('otherWaterSourcesOutdoorUse', 'm'||UNISTR('\00B3')||'', 'Other Water Sources - Outdoor Use');
	
	FOR r IN (
		SELECT type_name, basic_type
		  FROM csr.trans_attr_type
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_type (type_name, basic_type)
			VALUES (r.type_name, r.basic_type);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_type
				   SET basic_type = r.basic_type
				 WHERE type_name = r.type_name;
		END;
	END LOOP;

	FOR r IN (
		SELECT type_name, uom
		  FROM csr.trans_attr_unit
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_unit (type_name, uom)
			VALUES (r.type_name, r.uom);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	FOR r IN (
		SELECT attr_name, type_name, label, is_mandatory
		  FROM csr.trans_attr_for_building
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_for_building (attr_name, type_name, label, is_mandatory)
			VALUES (r.attr_name, r.type_name, r.label, r.is_mandatory);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_for_building
				   SET type_name = r.type_name,
				       label = r.label,
				       is_mandatory = r.is_mandatory
				 WHERE attr_name = r.attr_name;
		END;
	END LOOP;
END;
/

DROP TABLE CSR.TRANS_ATTR_TYPE;
DROP TABLE CSR.TRANS_ATTR_UNIT;
DROP TABLE CSR.TRANS_ATTR_FOR_BUILDING;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
