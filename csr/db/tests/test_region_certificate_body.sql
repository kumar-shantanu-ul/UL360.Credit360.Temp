CREATE OR REPLACE PACKAGE BODY csr.test_region_certificate_pkg AS

m_count								NUMBER;
m_id								NUMBER;

v_test_group_sid					security.security_pkg.T_SID_ID;
v_unauthed_user_sid					security.security_pkg.T_SID_ID;

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-regioncertificates.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;
v_pm_role_sid				security.security_pkg.T_SID_ID;
v_workflow_sid				security.security_pkg.T_SID_ID;
v_property_type_id			security.security_pkg.T_SID_ID;	

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin;

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
	v_pm_role_sid := unit_test_pkg.GetOrCreateRole('Property Manager');
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_unauthed_user_sid := unit_test_pkg.GetOrCreateUser('unauthed.user');
	COMMIT; -- need to commit before logging as this user
END;



/* private Setup, TearDown helpers */

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	DELETE FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp;
	
	DELETE FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp;
	
	DELETE FROM csr.certification_level WHERE certification_id >= 99990 AND certification_id <= 99999;
	DELETE FROM csr.certification WHERE certification_type_id = 99999;
	DELETE FROM csr.energy_rating WHERE certification_type_id = 99999;
	DELETE FROM csr.certification_type WHERE certification_type_id = 99999;
END;


/* Fixture Setup, TearDown */

PROCEDURE SetUpFixture 
AS
	v_user_sid					security.security_pkg.T_SID_ID;
BEGIN
	--dbms_output.put_line('SetUpFixture');

	BEGIN
		TearDownFixture;
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	CreateSite;
	security.user_pkg.LogonAdmin(v_site_name);
	SELECT csr_user_sid INTO v_administrator_sid FROM csr.csr_user WHERE user_name = 'builtinadministrator';
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	v_user_sid := unit_test_pkg.GetOrCreateUser('admin');

	DeleteDataCreatedDuringTests;

	INSERT INTO csr.certification_type (certification_type_id, name, lookup_key) VALUES (99999, 'Test Cert Type', 'TEST_CERT_TYPE');
	
	INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99998, 99999, 99998, 'Test Certification 1');
	INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99999, 99999, 99999, 'Test Certification 2');
	INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99990, 99999, 99990, 'Test Certification 3');
	INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99991, 99999, 99991, 'Test Certification 4');
	INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99992, 99999, 99992, 'Test Certification 5');

	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99999, 99999, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99998, 99999, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99997, 99999, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99996, 99999, 3, 'Bronze');

	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99996, 99990, 0, 'cl1');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99995, 99991, 0, 'cl2');

	INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (99997, 99999, 99997, 'Test Rating 0');
	INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (99998, 99999, 99998, 'Test Rating 1');
	INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (99999, 99999, 99999, 'Test Rating 2');

	unit_test_pkg.CreateCommonMenu;
	unit_test_pkg.CreateCommonWebResources;
	unit_test_pkg.EnableChain;
	enable_pkg.EnableWorkflow;
	test_common_pkg.SetupChainPropertyWorkflow;

	property_pkg.SavePropertyType(
			in_property_type_id => NULL,
			in_property_type_name => 'Test Property Type',
			in_space_type_ids => NULL,
			in_gresb_prop_type => NULL,
			out_property_type_id => v_property_type_id
	);

END;

PROCEDURE TearDownFixture AS
BEGIN 
	--dbms_output.put_line('TearDownFixture');
	DeleteDataCreatedDuringTests;

	test_common_pkg.TeardownChainPropertyWorkflow;

	security.user_pkg.LogonAdmin(v_site_name);
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;


/* Per test Setup, TearDown */

PROCEDURE SetUp AS
BEGIN
	--dbms_output.put_line('SetUp');
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	dbms_output.put_line('TearDown');
	DELETE FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp;
	DELETE FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp;

	dbms_output.put_line('TearDown Regions');
	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'Test_RegCert%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;

FUNCTION CreateTestRegion(
	in_name		IN	VARCHAR2
) RETURN security.security_pkg.T_SID_ID
AS
	v_region_root_sid	security.security_pkg.T_SID_ID;
	v_region_sid_1		security.security_pkg.T_SID_ID;
	v_role_sid			security.security_pkg.T_SID_ID;

	v_company_sid		security.security_pkg.T_SID_ID;	
	v_flow_item_id		flow_item.flow_item_id%TYPE;
BEGIN
	SELECT c.company_sid
	  INTO v_company_sid
	  FROM chain.company c
	  JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE ct.is_top_company = 1;

	property_pkg.CreateProperty(
		in_company_sid				=> v_company_sid,
		in_description				=> 'Test Property', 
		in_country_code				=> 'gb',
		in_property_type_id			=> v_property_type_id,
		out_region_sid				=> v_region_sid_1
	);

	property_pkg.AddToFlow(v_region_sid_1, v_flow_item_id);

	
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	 
	 UPDATE csr.role SET is_property_manager = 1 WHERE name = 'Property Manager';

	SELECT role_sid
	  INTO v_role_sid
	  FROM csr.role
	 WHERE app_sid = security.security_pkg.getApp
	   AND is_property_manager = 1;

	INSERT INTO csr.region_role_member (user_sid, region_sid, role_sid, inherited_from_sid)
	VALUES (security.security_pkg.GetSid, v_region_sid_1, v_role_sid, v_region_root_sid);

	RETURN v_region_sid_1;
END;


/* Tests */
/* Certificates */
PROCEDURE TestGetCertificatesByTypeLookup AS
	v_certs							SYS_REFCURSOR;

	v_cert_id						NUMBER;
	v_certification_type_id 		NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
BEGIN
	region_certificate_pkg.GetCertificatesByTypeLookup(
		in_type_lookup_key	=>	'TEST_CERT_TYPE',
		out_cur				=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_cert_id, v_certification_type_id, v_external_id, v_name;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99990, 'Unexpected certificate id.');
		ELSIF m_count = 2 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99991, 'Unexpected certificate id.');
		ELSIF m_count = 5 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99999, 'Unexpected certificate id.');
		END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(5, m_count, 'Failed to get certificates by type lookup');
END;

PROCEDURE TestAddCertificateForRegion AS
	v_region_sid_1		security.security_pkg.T_SID_ID;
	
	v_level_name					VARCHAR2(255);
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAddCertificateForRegion');

	region_certificate_pkg.AddCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);
	
	SELECT floor_area, expiry_dtm, issued_dtm, note, submit_to_gresb
	  INTO v_floor_area, v_expiry_dtm, v_issued_dtm, v_note, v_submit_to_gresb
	  FROM region_certificate
	 WHERE region_sid = v_region_sid_1
	   AND certification_id = 99999
	   AND certification_level_id = 99997
	   AND app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertAreEqual(100, v_floor_area, 'Floor area failed to update.');
	unit_test_pkg.AssertAreEqual(TO_DATE('01-JAN-02'), v_expiry_dtm, 'Expiry date failed to update.');
	unit_test_pkg.AssertAreEqual(TO_DATE('01-JAN-01'), v_issued_dtm, 'Issued date failed to update.');
	unit_test_pkg.AssertAreEqual('NOTE', v_note, 'Note failed to update.');
	unit_test_pkg.AssertAreEqual(1, v_submit_to_gresb, 'Submit to GRESB failed to update.');
END;

PROCEDURE TestGetCertificatesForRegionSid AS
	v_certs							SYS_REFCURSOR;

	v_region_certificate_id			NUMBER;
	v_region_sid					NUMBER;
	v_certification_id				NUMBER;
	v_external_id					NUMBER;
	v_cert_name						VARCHAR2(255);
	v_certification_level			NUMBER;
	v_level_name					VARCHAR2(255);
	v_certificate_number			NUMBER;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_external_certificate_id		NUMBER;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetCertificatesForRegionSid');

	INSERT INTO region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, note)
	VALUES (security.security_pkg.getApp, csr.region_certificate_id_seq.NEXTVAL, v_region_sid_1, 99999, 99999, 1, 100, '01-JAN-01', '01-JAN-02', 'NOTE');

	region_certificate_pkg.GetCertificatesForRegionSid(
		in_region_sid	=>	v_region_sid_1,
		out_cur			=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_certification_id, v_external_id, v_cert_name, v_certification_level,
			v_level_name, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		unit_test_pkg.AssertIsTrue(v_certification_id = 99999, 'Unexpected certificate id.');
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to get certificates for region');
END;

PROCEDURE TestGetDeletedCertificatesForRegionSid AS
	v_certs							SYS_REFCURSOR;

	v_region_certificate_id			NUMBER;
	v_region_sid					NUMBER;
	v_certification_id				NUMBER;
	v_external_id					NUMBER;
	v_cert_name						VARCHAR2(255);
	v_certification_level			NUMBER;
	v_level_name					VARCHAR2(255);
	v_certificate_number			NUMBER;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_external_certificate_id		NUMBER;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetDeletedCertificatesForRegionSid');

	INSERT INTO region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, deleted)
	VALUES (security.security_pkg.getApp, csr.region_certificate_id_seq.NEXTVAL, v_region_sid_1, 99999, 99999, 1, 100, '01-JAN-01', '01-JAN-02', 1);

	region_certificate_pkg.GetCertificatesForRegionSid(
		in_region_sid	=>	v_region_sid_1,
		out_cur			=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_certification_id, v_external_id, v_cert_name, v_certification_level,
			v_level_name, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		unit_test_pkg.AssertIsTrue(v_certification_id = 99999, 'Unexpected certificate id.');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected certificates for region');

	region_certificate_pkg.GetDeletedCertificatesForRegionSid(
		in_region_sid	=>	v_region_sid_1,
		out_cur			=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_certification_id, v_external_id, v_cert_name, v_certification_level,
			v_level_name, v_certificate_number, v_floor_area, v_issued_dtm, v_expiry_dtm,
			v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		unit_test_pkg.AssertIsTrue(v_certification_id = 99999, 'Unexpected certificate id.');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to get deleted certificates for region');


	region_certificate_pkg.SetExternalCertificateId(
		in_region_sid					=>	v_region_sid_1,
		in_external_certification_id	=>	99999,
		in_certification_level_name		=>	'Platinum',
		in_floor_area					=>	100,
		in_external_certificate_id		=>	123456
	);

	region_certificate_pkg.GetDeletedCertificatesForRegionSid(
		in_region_sid	=>	v_region_sid_1,
		out_cur			=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_certification_id, v_external_id, v_cert_name, v_certification_level,
			v_level_name, v_certificate_number, v_floor_area, v_issued_dtm, v_expiry_dtm, 
			v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		unit_test_pkg.AssertIsTrue(v_certification_id = 99999, 'Unexpected certificate id.');
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to get deleted certificates for region');
END;

PROCEDURE TestUpdateCertificateForRegion AS
	v_certificate_number			NUMBER;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestUpdateCertificateForRegion');

	INSERT INTO region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm)
	VALUES (security.security_pkg.getApp, csr.region_certificate_id_seq.NEXTVAL, v_region_sid_1, 99999, 99999, 1, 100, '01-JAN-01', '01-JAN-02');

	region_certificate_pkg.UpdateCertificateForRegion(
		in_region_certificate_id	=>	csr.region_certificate_id_seq.CURRVAL,
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>	99999,
		in_certification_level_id	=>	99999,
		in_certificate_number		=>	2,
		in_floor_area				=>	500,
		in_expiry_dtm				=>  '01-JAN-03',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT certificate_number, floor_area, expiry_dtm, issued_dtm, note, submit_to_gresb
	  INTO v_certificate_number, v_floor_area, v_expiry_dtm, v_issued_dtm, v_note, v_submit_to_gresb
	  FROM region_certificate
	 WHERE region_sid = v_region_sid_1
	   AND certification_id = 99999
	   AND certification_level_id = 99999
	   AND app_sid = security.security_pkg.getApp;
	   
	unit_test_pkg.AssertAreEqual(2, v_certificate_number, 'Certificate number failed to update.');
	unit_test_pkg.AssertAreEqual(500, v_floor_area, 'Floor area failed to update.');
	unit_test_pkg.AssertAreEqual(TO_DATE('01-JAN-03'), v_expiry_dtm, 'Expiry date failed to update.');
	unit_test_pkg.AssertAreEqual(TO_DATE('01-JAN-01'), v_issued_dtm, 'Issued date failed to update.');
	unit_test_pkg.AssertAreEqual('NOTE', v_note, 'Note failed to update.');
	unit_test_pkg.AssertAreEqual(1, v_submit_to_gresb, 'Submit to GRESB failed to update.');
END;

PROCEDURE TestDeleteCertificateForRegion AS
	v_region_sid_1		security.security_pkg.T_SID_ID;
	v_cert1_id			NUMBER;
	v_cert2_id			NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestDeleteCertificateForRegion');

	SELECT csr.region_certificate_id_seq.NEXTVAL
	  INTO v_cert1_id
	  FROM DUAL;

	INSERT INTO region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (security.security_pkg.getApp, v_cert1_id, v_region_sid_1, 99999, 99999, 1, 100, '01-JAN-01', '01-JAN-02', 'NOTE', 1);

	SELECT csr.region_certificate_id_seq.NEXTVAL
	  INTO v_cert2_id
	  FROM DUAL;

	INSERT INTO region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, external_certificate_id, note, submit_to_gresb)
	VALUES (security.security_pkg.getApp, v_cert2_id, v_region_sid_1, 99999, 99999, 1, 100, '01-JAN-02', '01-JAN-03', 12345, 'NOTE', 0);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(2, m_count, 'Failed to add certificate to delete');

	region_certificate_pkg.DeleteCertificateForRegion(
		in_region_certificate_id				=> v_cert1_id
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND deleted = 1;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to harddelete certificate with no external_certificate_id');

	region_certificate_pkg.DeleteCertificateForRegion(
		in_region_certificate_id				=> v_cert2_id
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND deleted = 1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to softdelete certificate with external_certificate_id');
END;

/* 
Ratings
*/
PROCEDURE TestGetEnergyRatingByTypeLookup AS
	v_ratings						SYS_REFCURSOR;

	v_energy_rating_id				NUMBER;
	v_certification_type_id 		NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
BEGIN
	region_certificate_pkg.GetEnergyRatingsByTypeLookup(
		in_type_lookup_key	=>	'TEST_CERT_TYPE',
		out_cur				=>	v_ratings
	);

	m_count := 0;
	LOOP
		FETCH v_ratings INTO
			v_energy_rating_id, v_certification_type_id, v_external_id, v_name;
		EXIT WHEN v_ratings%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_energy_rating_id = 99997, 'Unexpected energy rating id '||v_energy_rating_id);
		ELSIF m_count = 2 THEN
			unit_test_pkg.AssertIsTrue(v_energy_rating_id = 99998, 'Unexpected energy rating id '||v_energy_rating_id);
		ELSIF m_count = 3 THEN
			unit_test_pkg.AssertIsTrue(v_energy_rating_id = 99999, 'Unexpected energy rating id '||v_energy_rating_id);
		END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(3, m_count, 'Failed to get energy ratings by type lookup');
END;

PROCEDURE TestAddEnergyRatingForRegion AS
	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAddEnergyRatingForRegion');

	region_certificate_pkg.AddEnergyRatingForRegion(
		in_region_sid			=>	v_region_sid_1,
		in_energy_rating_id		=>  99999,
		in_floor_area			=>  100,
		in_expiry_dtm			=>  '01-JAN-02',
		in_issued_dtm			=>  '01-JAN-01',
		in_note					=>  'NOTE',
		in_submit_to_gresb		=>  0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to set region energy ratings');
END;

PROCEDURE TestAddEnergyRatingForRegionSingleGresbRecord AS
	v_region_sid_1		security.security_pkg.T_SID_ID;
	v_region_sid_2		security.security_pkg.T_SID_ID;
	v_test_result		NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAddEnergyRatingForRegion');
	v_region_sid_2 := CreateTestRegion(in_name => 'Test_RegCert_TestAddEnergyRatingForRegion2');

	-- all fields
	region_certificate_pkg.AddEnergyRatingForRegion(
		in_region_sid			=>	v_region_sid_1,
		in_energy_rating_id		=>  99999,
		in_floor_area			=>  100,
		in_expiry_dtm			=>  '01-JAN-02',
		in_issued_dtm			=>  '01-JAN-01',
		in_note					=>  'NOTE',
		in_submit_to_gresb		=>  1
	);

	BEGIN
		-- all fields, dupe
		region_certificate_pkg.AddEnergyRatingForRegion(
			in_region_sid			=>	v_region_sid_1,
			in_energy_rating_id		=>  99999,
			in_floor_area			=>  100,
			in_expiry_dtm			=>  '01-JAN-02',
			in_issued_dtm			=>  '01-JAN-01',
			in_note					=>  'NOTE',
			in_submit_to_gresb		=>  1
		);
		v_test_result := 0;
	EXCEPTION
		WHEN OTHERS THEN
			v_test_result := 1;
	END;

	unit_test_pkg.AssertAreEqual(1, v_test_result, 'Multiple Energy Ratings have been added that are marked for GRESB submission.');

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to set region energy ratings');

	-- null exp date
	region_certificate_pkg.AddEnergyRatingForRegion(
		in_region_sid			=>	v_region_sid_2,
		in_energy_rating_id		=>  99998,
		in_floor_area			=>  100,
		in_expiry_dtm			=>  NULL,
		in_issued_dtm			=>  '01-JAN-02',
		in_note					=>  'NOTE',
		in_submit_to_gresb		=>  0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_2;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add region energy ratings');

END;

PROCEDURE TestGetEnergyRatingForRegionSid AS
	v_ratings						SYS_REFCURSOR;

	v_region_energy_rating_id		NUMBER;
	v_region_sid					NUMBER;
	v_energy_rating_id				NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;
	
	v_region_sid_1					security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetEnergyRatingForRegionSid');

	INSERT INTO region_energy_rating (app_sid, region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (security.security_pkg.getApp, csr.region_energy_rating_id_seq.nextval, v_region_sid_1, 99999, 100, '01-JAN-01', '01-JAN-02', 'NOTE', 0);

	region_certificate_pkg.GetEnergyRatingsForRegionSid(
		in_region_sid	=>	v_region_sid_1,
		out_cur			=>	v_ratings
	);

	m_count := 0;
	LOOP
		FETCH v_ratings INTO
			v_region_energy_rating_id, v_region_sid, v_energy_rating_id, v_external_id, v_name, v_floor_area, v_issued_dtm, v_expiry_dtm, v_note, v_submit_to_gresb;
		EXIT WHEN v_ratings%NOTFOUND;
		m_count := m_count + 1;
		unit_test_pkg.AssertIsTrue(v_energy_rating_id = 99999, 'Unexpected energy rating id.');
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to get energy ratings for region');
END;

PROCEDURE TestUpdateRegionEnergyRating AS
	v_region_energy_rating_id		NUMBER := csr.region_energy_rating_id_seq.nextval;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;
	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestUpdateRegionEnergyRating');

	INSERT INTO region_energy_rating (app_sid, region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (security.security_pkg.getApp, v_region_energy_rating_id, v_region_sid_1, 99999,100, '01-JAN-01', '01-JAN-02', 'NOTE', 0);

	region_certificate_pkg.UpdateEnergyRatingForRegion(
		in_region_energy_rating_id	=>	v_region_energy_rating_id,
		in_region_sid				=>	v_region_sid_1,
		in_energy_rating_id			=>	99999,
		in_floor_area				=>	500,
		in_expiry_dtm				=>  '01-JAN-03',
		in_issued_dtm				=>  '01-JAN-02',
		in_note						=>  'NOTE UPDATED',
		in_submit_to_gresb			=>  1
	);

	SELECT floor_area, expiry_dtm, issued_dtm, note, submit_to_gresb
	  INTO v_floor_area, v_expiry_dtm, v_issued_dtm, v_note, v_submit_to_gresb
	  FROM region_energy_rating
	 WHERE region_sid = v_region_sid_1
	   AND region_energy_rating_id = v_region_energy_rating_id
	   AND app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertIsTrue(v_floor_area = 500, 'Floor area failed to update.');
	unit_test_pkg.AssertIsTrue(v_expiry_dtm = '01-JAN-03', 'Expiry date failed to update.');
	unit_test_pkg.AssertIsTrue(v_issued_dtm = '01-JAN-02', 'Issued date failed to update.');
	unit_test_pkg.AssertIsTrue(v_note = 'NOTE UPDATED', 'Note failed to update.');
	unit_test_pkg.AssertIsTrue(v_submit_to_gresb = 1, 'GRESB submission flag failed to update.');
END;

PROCEDURE TestDeleteEnergyRatingForRegion AS
	v_region_energy_rating_id		NUMBER := csr.region_energy_rating_id_seq.nextval;
	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestDeleteEnergyRatingForRegion');

	INSERT INTO region_energy_rating (app_sid, region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (security.security_pkg.getApp, v_region_energy_rating_id, v_region_sid_1, 99999, 100, '01-JAN-01', '01-JAN-02', 'NOTE', 0);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add energy rating to delete');

	region_certificate_pkg.DeleteEnergyRatingForRegion(
		in_region_sid					=>	v_region_sid_1,
		in_region_energy_rating_id		=>	v_region_energy_rating_id
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND region_energy_rating_id = v_region_energy_rating_id;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to add delete energy rating');
END;


PROCEDURE TestGetCertificatesByRegion AS
	v_region_sid_1					NUMBER;
	v_certs							SYS_REFCURSOR;

	v_region_certificate_id			NUMBER;
	v_region_sid					NUMBER;
	v_cert_id						NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
	v_certification_level_id		NUMBER;
	v_level							VARCHAR2(255);
	v_certificate_number			NUMBER;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_external_certificate_id		NUMBER;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_user_act_id					security.security_pkg.T_ACT_ID;
	
BEGIN
	region_certificate_pkg.GetCertificatesByRegion(
		out_cur				=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_cert_id, v_external_id, v_name,
			v_certification_level_id, v_level, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
	END LOOP;
	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected certificates by region');


	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetCertificatesByRegion');

	region_certificate_pkg.AddCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	region_certificate_pkg.GetCertificatesByRegion(
		out_cur				=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_cert_id, v_external_id, v_name,
			v_certification_level_id, v_level, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99999, 'Unexpected certificate id.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected certificates by region');

	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.GetCertificatesByRegion(
			out_cur				=>	v_certs
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);
END;


PROCEDURE TestGetDeletedCertificatesByRegion AS
	v_region_sid_1					NUMBER;
	v_certs							SYS_REFCURSOR;

	v_region_certificate_id			NUMBER;
	v_region_sid					NUMBER;
	v_cert_id						NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
	v_certification_level_id		NUMBER;
	v_level							VARCHAR2(255);
	v_certificate_number			NUMBER;
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_external_certificate_id		NUMBER;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_user_act_id					security.security_pkg.T_ACT_ID;
	
	m_count_orig					NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetDeletedCertificatesByRegion');

	region_certificate_pkg.AddCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	region_certificate_pkg.GetCertificatesByRegion(
		out_cur				=>	v_certs
	);

	region_certificate_pkg.SetExternalCertificateId(
		in_region_sid					=>	v_region_sid_1,
		in_external_certification_id	=>	99999,
		in_certification_level_name		=>	'Silver',
		in_floor_area					=>	100,
		in_external_certificate_id		=>	123456
	);

	m_count_orig := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_cert_id, v_external_id, v_name,
			v_certification_level_id, v_level, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count_orig := m_count_orig + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(m_count_orig > 0, 'Expected at least one certificate by region, got '||m_count_orig);


	region_certificate_pkg.DeleteCertificateForRegion(
		in_region_certificate_id			=>	v_region_certificate_id
	);

	region_certificate_pkg.GetCertificatesByRegion(
		out_cur				=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_cert_id, v_external_id, v_name,
			v_certification_level_id, v_level, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99999, 'Unexpected certificate id.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertAreEqual(m_count_orig - 1, m_count, 'Expected original count less 1 for certificates by region');


	region_certificate_pkg.GetDeletedCertificatesByRegion(
		out_cur				=>	v_certs
	);

	m_count := 0;
	LOOP
		FETCH v_certs INTO
			v_region_certificate_id, v_region_sid, v_cert_id, v_external_id, v_name,
			v_certification_level_id, v_level, v_certificate_number, v_floor_area,
			v_issued_dtm, v_expiry_dtm, v_external_certificate_id, v_note, v_submit_to_gresb;
		EXIT WHEN v_certs%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_cert_id = 99999, 'Unexpected certificate id.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected count for deleted certificates by region: '||m_count);
END;


PROCEDURE TestGetCertificateLevels AS
	v_user_act_id					security.security_pkg.T_ACT_ID;
	v_levels						SYS_REFCURSOR;

	v_certification_level_id		NUMBER;
	v_certification_id				NUMBER;
	v_position						NUMBER;
	v_name							VARCHAR2(255);
BEGIN
	region_certificate_pkg.GetCertificateLevels(
		out_cur				=>	v_levels
	);

	m_count := 0;
	LOOP
		FETCH v_levels INTO
			v_certification_level_id, v_certification_id, v_position, v_name;
		EXIT WHEN v_levels%NOTFOUND;
		m_count := m_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(m_count > 0, 'No levels found');

	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.GetCertificateLevels(
			out_cur				=>	v_levels
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TestUpsertCertificateForRegion AS
	v_user_act_id					security.security_pkg.T_ACT_ID;
	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAdminUpsertCertificateForRegion');

	region_certificate_pkg.AdminUpsertCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add region certificate');

	-- update existing
	region_certificate_pkg.AdminUpsertCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  2,
		in_floor_area				=>  101,
		in_expiry_dtm				=>  '02-JAN-02',
		in_issued_dtm				=>  '02-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to update region certificate');

	-- Add another
	region_certificate_pkg.AdminUpsertCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99998,
		in_certificate_number		=>  2,
		in_floor_area				=>  101,
		in_expiry_dtm				=>  '01-JAN-04',
		in_issued_dtm				=>  '01-JAN-03',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	unit_test_pkg.AssertAreEqual(2, m_count, 'Failed to add new region certificate');


	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.AdminUpsertCertificateForRegion(
			in_region_sid				=>	v_region_sid_1,
			in_certification_id			=>  99999,
			in_certification_level_id	=>  99996,
			in_certificate_number		=>  2,
			in_floor_area				=>  101,
			in_expiry_dtm				=>  '01-JAN-03',
			in_issued_dtm				=>  '01-JAN-02',
			in_note						=>	'NOTE',
			in_submit_to_gresb			=>	1
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TestDeleteCertificatesForRegion AS
	v_user_act_id		security.security_pkg.T_ACT_ID;
	v_region_sid_1		security.security_pkg.T_SID_ID;
	v_rc_id				NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAdminDeleteCertificateForRegion');

	region_certificate_pkg.AdminUpsertCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;

	SELECT region_certificate_id
	  INTO v_rc_id
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add region certificate');


	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.AdminDeleteCertificatesForRegion(
			in_region_sid				=>	v_region_sid_1,
			in_region_certificate_id	=>  v_rc_id
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);

	-- delete
	region_certificate_pkg.AdminDeleteCertificatesForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_region_certificate_id	=>  v_rc_id
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND deleted = 1;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to delete region certificate');

END;

PROCEDURE TestAdminCleanupDeletedCertificates AS
	v_region_sid_1		security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAdminCleanupDeletedCertificates');

	region_certificate_pkg.AdminUpsertCertificateForRegion(
		in_region_sid				=>	v_region_sid_1,
		in_certification_id			=>  99999,
		in_certification_level_id	=>  99997,
		in_certificate_number		=>  1,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>	'NOTE',
		in_submit_to_gresb			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add region certificate');

	-- delete
	region_certificate_pkg.AdminCleanupDeletedCertificatesForRegion(
		in_region_sid			=>	v_region_sid_1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_certificate
	 WHERE app_sid = security.security_pkg.getApp
	   AND deleted = 1;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to cleanup region certificate');

END;


PROCEDURE TestGetEnergyRatingsByRegion AS
	v_region_sid_1					NUMBER;
	v_ratings						SYS_REFCURSOR;

	v_region_energy_rating_id		NUMBER;
	v_region_sid					NUMBER;
	v_rating_id						NUMBER;
	v_external_id					NUMBER;
	v_name							VARCHAR2(255);
	v_floor_area					NUMBER;
	v_issued_dtm					DATE;
	v_expiry_dtm					DATE;
	v_note							VARCHAR2(2048);
	v_submit_to_gresb				NUMBER;

	v_user_act_id					security.security_pkg.T_ACT_ID;
	
BEGIN
	region_certificate_pkg.GetEnergyRatingsByRegion(
		out_cur				=>	v_ratings
	);

	m_count := 0;
	LOOP
		FETCH v_ratings INTO
			v_region_energy_rating_id, v_region_sid, v_rating_id, v_external_id, v_name,
			v_floor_area, v_issued_dtm, v_expiry_dtm, v_note, v_submit_to_gresb;
		EXIT WHEN v_ratings%NOTFOUND;
		m_count := m_count + 1;
	END LOOP;
	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected ratings by region');


	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestGetEnergyRatingsByRegion');

	region_certificate_pkg.AddEnergyRatingForRegion(
		in_region_sid			=>	v_region_sid_1,
		in_energy_rating_id		=>  99999,
		in_floor_area			=>  100,
		in_expiry_dtm			=>  '01-JAN-02',
		in_issued_dtm			=>  '01-JAN-01',
		in_note					=>  'NOTE',
		in_submit_to_gresb		=>  0
	);

	region_certificate_pkg.GetEnergyRatingsByRegion(
		out_cur				=>	v_ratings
	);

	m_count := 0;
	LOOP
		FETCH v_ratings INTO
			v_region_energy_rating_id, v_region_sid, v_rating_id, v_external_id, v_name,
			v_floor_area, v_issued_dtm, v_expiry_dtm, v_note, v_submit_to_gresb;
		EXIT WHEN v_ratings%NOTFOUND;
		m_count := m_count + 1;
		IF m_count = 1 THEN
			unit_test_pkg.AssertIsTrue(v_rating_id = 99999, 'Unexpected rating id.');
		END IF;
	END LOOP;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected ratings by region');

	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.GetEnergyRatingsByRegion(
			out_cur				=>	v_ratings
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TestUpsertEnergyRatingForRegion AS
	v_user_act_id					security.security_pkg.T_ACT_ID;
	v_region_sid_1					security.security_pkg.T_SID_ID;
	v_region_energy_rating_id		NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAdminUpsertEnergyRatingForRegion');

	-- create new
	region_certificate_pkg.AdminUpsertEnergyRatingForRegion(
		in_region_energy_rating_id	=>	0,
		in_region_sid				=>	v_region_sid_1,
		in_energy_rating_id			=>  99999,
		in_floor_area				=>  100,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>  'NOTE',
		in_submit_to_gresb			=>  0
	);

	SELECT COUNT(region_energy_rating_id), region_energy_rating_id
	  INTO m_count, v_region_energy_rating_id
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	 GROUP BY region_energy_rating_id;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add EnergyRating');

	-- update existing
	region_certificate_pkg.AdminUpsertEnergyRatingForRegion(
		in_region_energy_rating_id	=>	v_region_energy_rating_id,
		in_region_sid				=>	v_region_sid_1,
		in_energy_rating_id			=>  99999,
		in_floor_area				=>  101,
		in_expiry_dtm				=>  '01-JAN-02',
		in_issued_dtm				=>  '01-JAN-01',
		in_note						=>  'NOTE',
		in_submit_to_gresb			=>  0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND region_energy_rating_id = v_region_energy_rating_id;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to update EnergyRating');

	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.AdminUpsertEnergyRatingForRegion(
			in_region_energy_rating_id	=>	0,
			in_region_sid				=>	v_region_sid_1,
			in_energy_rating_id			=>  99999,
			in_floor_area				=>  101,
			in_expiry_dtm				=>  '01-JAN-03',
			in_issued_dtm				=>  '01-JAN-02',
			in_note						=>  'NOTE',
			in_submit_to_gresb			=>  0
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TestDeleteEnergyRatingsForRegion AS
	v_user_act_id					security.security_pkg.T_ACT_ID;
	v_region_sid_1					security.security_pkg.T_SID_ID;
	v_region_energy_rating_id		NUMBER;
BEGIN
	v_region_sid_1 := CreateTestRegion(in_name => 'Test_RegCert_TestAdminDeleteEnergyRatingForRegion');

	region_certificate_pkg.AddEnergyRatingForRegion(
		in_region_sid			=>	v_region_sid_1,
		in_energy_rating_id		=>  99999,
		in_floor_area			=>  100,
		in_expiry_dtm			=>  '01-JAN-02',
		in_issued_dtm			=>  '01-JAN-01',
		in_note					=>  'NOTE',
		in_submit_to_gresb		=>  0
	);

	SELECT COUNT(region_energy_rating_id), region_energy_rating_id
	  INTO m_count, v_region_energy_rating_id
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	 GROUP BY region_energy_rating_id;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to add EnergyRating');

	-- logon as user that cannot access
	security.user_pkg.LogonAuthenticated(v_unauthed_user_sid, 60, v_user_act_id);

	BEGIN
		region_certificate_pkg.AdminDeleteEnergyRatingForRegion(
			in_region_sid					=>	v_region_sid_1,
			in_region_energy_rating_id		=>  v_region_energy_rating_id
		);
		unit_test_pkg.TestFail('Should throw exception');
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN NULL;
		WHEN OTHERS THEN unit_test_pkg.TestFail('Unexpected exception');
	END;

	security.user_pkg.LogonAdmin(v_site_name);

	-- delete
	region_certificate_pkg.AdminDeleteEnergyRatingForRegion(
		in_region_sid					=>	v_region_sid_1,
		in_region_energy_rating_id		=>  v_region_energy_rating_id
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM region_energy_rating
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = v_region_sid_1
	   AND region_energy_rating_id = v_region_energy_rating_id;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to delete EnergyRating');

END;

END test_region_certificate_pkg;
/
