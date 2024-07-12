exec security.user_pkg.logonadmin('philipsdev.credit360.com');
CREATE PUBLIC DATABASE LINK live
   USING 'live'; 
insert into chem.cas (cas_code, name, unconfirmed, is_voc, category)
select cas_code, name, unconfirmed, is_voc, category 
  from chem.cas@live;

INSERT INTO chem.cas_restricted (
	CAS_CODE, ROOT_REGION_SID, START_DTM, END_DTM, REMARKS, SOURCE, CLP_TABLE_3_1, CLP_TABLE_3_2
)
SELECT CAS_CODE, 166991, START_DTM, END_DTM, REMARKS, SOURCE, CLP_TABLE_3_1, CLP_TABLE_3_2
  FROM chem.cas_restricted@live
 WHERE app_sid = 11333837
   AND ROOT_REGION_SID = 12017721;


INSERT INTO chem.cas_group (
	CAS_GROUP_ID, PARENT_GROUP_ID, LABEL, LOOKUP_KEY
)
SELECT CAS_GROUP_ID, PARENT_GROUP_ID, LABEL, LOOKUP_KEY
  FROM chem.cas_group@live
 WHERE app_sid = 11333837;


INSERT INTO chem.cas_group_member (
	CAS_GROUP_ID, CAS_CODE
)
SELECT CAS_GROUP_ID, CAS_CODE
  FROM chem.cas_group_member@live
 WHERE app_sid = 11333837;


INSERT INTO chem.classification (
	CLASSIFICATION_ID, DESCRIPTION
)
SELECT CLASSIFICATION_ID, DESCRIPTION
  FROM chem.classification@live
 WHERE app_sid = 11333837; 

INSERT INTO chem.manufacturer (
	MANUFACTURER_ID, CODE, NAME
)
SELECT MANUFACTURER_ID, CODE, NAME
  FROM chem.manufacturer@live
 WHERE app_sid = 11333837;


INSERT INTO chem.substance (
	SUBSTANCE_ID, REF, DESCRIPTION, CLASSIFICATION_ID, MANUFACTURER_ID, REGION_SID
)
SELECT SUBSTANCE_ID, REF, DESCRIPTION, CLASSIFICATION_ID, MANUFACTURER_ID, null
  FROM chem.substance@live
 WHERE app_sid = 11333837;


INSERT INTO chem.substance_cas (
	SUBSTANCE_ID, CAS_CODE, PCT_COMPOSITION
)
SELECT SUBSTANCE_ID, CAS_CODE, PCT_COMPOSITION
  FROM chem.substance_cas@live
 WHERE app_sid = 11333837;


INSERT INTO chem.usage (
	USAGE_ID, DESCRIPTION
)
SELECT USAGE_ID, DESCRIPTION
  FROM chem.usage@live
 WHERE app_sid = 11333837;


INSERT INTO chem.waiver_status (
	WAIVER_STATUS_ID, DESCRIPTION
)
SELECT distinct WAIVER_STATUS_ID, DESCRIPTION
  FROM chem.waiver_status@live;

