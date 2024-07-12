-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	-- Delete the schema, if it already exists.
	DBMS_XMLSCHEMA.DeleteSchema('http://www.cr360.com/XMLSchemas/recurrences.xsd',4);
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	-- Register the schema
	DBMS_XMLSCHEMA.RegisterSchema(
	OWNER => 'CSR',
	SCHEMAURL => 'http://www.cr360.com/XMLSchemas/recurrences.xsd',
	SCHEMADOC => '<?xml version="1.0" encoding="utf-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
  <xs:complexType name="day-type">
    <xs:attribute name="number" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:positiveInteger">
          <xs:minInclusive value="1"/>
          <xs:maxInclusive value="31"/>
        </xs:restriction>
      </xs:simpleType>
      </xs:attribute>
    <xs:attribute name="month" type="month-type" use="optional"/>
  </xs:complexType>
  <xs:simpleType name="month-type">
    <xs:restriction base="xs:string">
      <xs:enumeration value="jan"/>
      <xs:enumeration value="feb"/>
      <xs:enumeration value="mar"/>
      <xs:enumeration value="apr"/>
      <xs:enumeration value="may"/>
      <xs:enumeration value="jun"/>
      <xs:enumeration value="jul"/>
      <xs:enumeration value="aug"/>
      <xs:enumeration value="sep"/>
      <xs:enumeration value="oct"/>
      <xs:enumeration value="nov"/>
      <xs:enumeration value="dec"/>
    </xs:restriction>
  </xs:simpleType>
  <xs:simpleType name="weekday">
    <xs:restriction base="xs:string">
      <xs:enumeration value="sunday"/>
      <xs:enumeration value="monday"/>
      <xs:enumeration value="tuesday"/>
      <xs:enumeration value="wednesday"/>
      <xs:enumeration value="thursday"/>
      <xs:enumeration value="friday"/>
      <xs:enumeration value="saturday"/>
    </xs:restriction>
  </xs:simpleType>
  <xs:complexType name="everyn">
    <xs:attribute name="every-n" use="optional"/>
  </xs:complexType>
  <xs:complexType name="day-varying-type">
    <xs:attribute name="day" type="weekday" use="required"/>
    <xs:attribute name="type" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:string">
          <xs:enumeration value="first"/>
          <xs:enumeration value="second"/>
          <xs:enumeration value="third"/>
          <xs:enumeration value="fourth"/>
          <xs:enumeration value="last"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:attribute>
    <xs:attribute name="month" use="optional" type="month-type"/>
  </xs:complexType>
  <xs:complexType name="x-day-b-yearly">
    <xs:attribute name="number" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:positiveInteger">
          <xs:minInclusive value="1"/>
          <xs:maxInclusive value="365"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:attribute>
    <xs:attribute name="month" type="month-type" use="required"/>
  </xs:complexType>
  <xs:complexType name="x-day-b-monthly">
    <xs:attribute name="number" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:positiveInteger">
          <xs:minInclusive value="1"/>
          <xs:maxInclusive value="180"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:attribute>
    <xs:attribute name="month" type="month-type" use="optional"/>
  </xs:complexType>
  <xs:complexType name="recurrence-weekly">
    <xs:choice>
      <xs:sequence>
        <xs:element name="monday"/>
        <xs:element name="tuesday" minOccurs="0"/>
        <xs:element name="wednesday" minOccurs="0"/>
        <xs:element name="thursday" minOccurs="0"/>
        <xs:element name="friday" minOccurs="0"/>
        <xs:element name="saturday" minOccurs="0"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="tuesday"/>
        <xs:element name="wednesday" minOccurs="0"/>
        <xs:element name="thursday" minOccurs="0"/>
        <xs:element name="friday" minOccurs="0"/>
        <xs:element name="saturday" minOccurs="0"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="wednesday"/>
        <xs:element name="thursday" minOccurs="0"/>
        <xs:element name="friday" minOccurs="0"/>
        <xs:element name="saturday" minOccurs="0"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="thursday"/>
        <xs:element name="friday" minOccurs="0"/>
        <xs:element name="saturday" minOccurs="0"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="friday"/>
        <xs:element name="saturday" minOccurs="0"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="saturday"/>
        <xs:element name="sunday" minOccurs="0"/>
      </xs:sequence>
      <xs:sequence>
        <xs:element name="sunday"/>
      </xs:sequence>
    </xs:choice>
  </xs:complexType>
  <xs:complexType name="recurrence-monthly">
    <xs:sequence>
      <xs:choice minOccurs="1" maxOccurs="1">
        <xs:element name="x-day-b" type="x-day-b-monthly"/>
        <xs:element name="day-varying" type="day-varying-type"/>
        <xs:element name="day" type="day-type"/>
      </xs:choice>
    </xs:sequence>
    <xs:attribute name="every-n" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:string">
          <xs:enumeration value="1"/>
          <xs:enumeration value="2"/>
          <xs:enumeration value="3"/>
          <xs:enumeration value="4"/>
          <xs:enumeration value="5"/>
          <xs:enumeration value="6"/>
          <xs:enumeration value="7"/>
          <xs:enumeration value="8"/>
          <xs:enumeration value="9"/>
          <xs:enumeration value="10"/>
          <xs:enumeration value="11"/>
          <xs:enumeration value="12"/>
          <xs:enumeration value="weekday"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:attribute>
  </xs:complexType>
  <xs:complexType name="recurrence-yearly">
    <xs:sequence>
      <xs:choice minOccurs="1" maxOccurs="1">
        <xs:element name="x-day-b" type="x-day-b-yearly"/>
        <xs:element name="day-varying" type="day-varying-type"/>
        <xs:element name="day" type="day-type"/>
      </xs:choice>
    </xs:sequence>
    <xs:attribute name="every-n" use="required">
      <xs:simpleType>
        <xs:restriction base="xs:integer">
          <xs:enumeration value="1"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:attribute>
  </xs:complexType>
  <xs:element name="recurrences">
    <xs:complexType>
      <xs:sequence>
        <xs:choice minOccurs="1" maxOccurs="1">
          <xs:element name="monthly" type="recurrence-monthly"/>
          <xs:element name="yearly" type="recurrence-yearly"/>
          <xs:element name="weekly" type="recurrence-weekly"/>
          <xs:element name="daily" type="everyn"/>
          <xs:element name="hourly" type="everyn"/>
        </xs:choice>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>',
	LOCAL => FALSE
	);
END;
/

CREATE OR REPLACE TRIGGER csr.validate_schedule_xml
BEFORE INSERT OR UPDATE
	ON csr.delegation
	FOR EACH ROW
DECLARE
	v_schedule_xml			XMLTYPE;
	v_schema_url			VARCHAR2(255) := 'http://www.cr360.com/XMLSchemas/recurrences.xsd';
BEGIN
	IF :new.schedule_xml IS NOT NULL THEN 
		v_schedule_xml := XMLTYPE(:new.schedule_xml, v_schema_url);
		v_schedule_xml.SchemaValidate();
	END IF;
END;
/
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\delegation_body

@update_tail
