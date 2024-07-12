exec security.user_pkg.logonadmin;

variable v_app_sid number;

begin
SELECT app_sid INTO :v_app_sid FROM csr.customer WHERE host = 'hs.credit360.com';
end;
/

INSERT INTO chem.cas_restricted (
	APP_SID, CAS_CODE, ROOT_REGION_SID, START_DTM, END_DTM, REMARKS, SOURCE, CLP_TABLE_3_1, CLP_TABLE_3_2
)
SELECT :v_app_sid, CAS_CODE, ROOT_REGION_SID, START_DTM, END_DTM, REMARKS, SOURCE, CLP_TABLE_3_1, CLP_TABLE_3_2
  FROM chem.cas_restricted
 WHERE app_sid = 11333837;


INSERT INTO chem.cas_group (
	APP_SID, CAS_GROUP_ID, PARENT_GROUP_ID, LABEL, LOOKUP_KEY
)
SELECT :v_app_sid, CAS_GROUP_ID, PARENT_GROUP_ID, LABEL, LOOKUP_KEY
  FROM chem.cas_group
 WHERE app_sid = 11333837;


INSERT INTO chem.cas_group_member (
	APP_SID, CAS_GROUP_ID, CAS_CODE
)
SELECT :v_app_sid, CAS_GROUP_ID, CAS_CODE
  FROM chem.cas_group_member
 WHERE app_sid = 11333837;


INSERT INTO chem.classification (
	APP_SID, CLASSIFICATION_ID, DESCRIPTION
)
SELECT :v_app_sid, CLASSIFICATION_ID, DESCRIPTION
  FROM chem.classification
 WHERE app_sid = 11333837; 

INSERT INTO chem.manufacturer (
	APP_SID, MANUFACTURER_ID, CODE, NAME
)
SELECT :v_app_sid, MANUFACTURER_ID, CODE, NAME
  FROM chem.manufacturer
 WHERE app_sid = 11333837;


INSERT INTO chem.substance (
	APP_SID, SUBSTANCE_ID, REF, DESCRIPTION, CLASSIFICATION_ID, MANUFACTURER_ID, REGION_SID, IS_CENTRAL
)
SELECT :v_app_sid, SUBSTANCE_ID, REF, DESCRIPTION, CLASSIFICATION_ID, MANUFACTURER_ID, null, is_central
  FROM chem.substance
 WHERE app_sid = 11333837;


INSERT INTO chem.substance_cas (
	APP_SID, SUBSTANCE_ID, CAS_CODE, PCT_COMPOSITION
)
SELECT :v_app_sid, SUBSTANCE_ID, CAS_CODE, PCT_COMPOSITION
  FROM chem.substance_cas
 WHERE app_sid = 11333837;


INSERT INTO chem.usage (
	APP_SID, USAGE_ID, DESCRIPTION
)
SELECT :v_app_sid, USAGE_ID, DESCRIPTION
  FROM chem.usage
 WHERE app_sid = 11333837;

