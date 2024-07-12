CREATE OR REPLACE PACKAGE BODY csr.test_credential_management_pkg AS

PROCEDURE Trace(in_msg VARCHAR2)
AS
BEGIN
	dbms_output.put_line(in_msg);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_label					VARCHAR2(255);
	v_count					NUMBER;
BEGIN
	security.user_pkg.logonadmin(in_site_name);

	DELETE FROM credential_management
	 WHERE label LIKE 'TestCredentialManagement_%';
END;

PROCEDURE TestAddCredential AS
	v_old_count			NUMBER;
	v_new_count			NUMBER;
	v_label				VARCHAR2(255) := 'TestCredentialManagement_AddCredential';
BEGIN

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM credential_management
	 WHERE label = v_label;

	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM credential_management
	 WHERE label = v_label;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');


	v_label := v_label || 'a';
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM credential_management
	 WHERE label = v_label;

	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 2,
		in_auth_scope_id => NULL
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM credential_management
	 WHERE label = v_label;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');
END;

PROCEDURE TestUpdateCredential AS
	v_credential_id			NUMBER;
	v_label					VARCHAR2(255) := 'TestCredentialManagement_UpdateCredential';
	v_label_updated			VARCHAR2(255) := 'TestCredentialManagement_UpdateCredential_Updated';
	v_result_label			VARCHAR2(255);
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	  WHERE label = v_label;

	credentials_pkg.UpdateCredential(
		in_credential_id => v_credential_id,
		in_label => v_label_updated,
		in_cache_key => null,
		in_login_hint => null
	);

	SELECT label
	  INTO v_result_label
	  FROM credential_management
	  WHERE credential_id = v_credential_id;

	unit_test_pkg.AssertAreEqual(v_label_updated, v_result_label, 'Updated Label should match');
END;

PROCEDURE TestDeleteCredential AS
	v_credential_id			NUMBER;
	v_count					NUMBER;
	v_label					VARCHAR2(255) := 'TestCredentialManagement_DeleteCredential';
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	 WHERE label = v_label;

	credentials_pkg.DeleteCredential(
		in_credential_id => v_credential_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM credential_management
	 WHERE credential_id = v_credential_id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');
END;

PROCEDURE TestGetSelectedCredential AS
	v_credential_id			NUMBER;
	v_label					VARCHAR2(255) := 'TestCredentialManagement_GetSelectedCredential';
	v_auth_type_id			NUMBER;
	v_auth_type_name		VARCHAR2(255);
	v_auth_scope_id			NUMBER;
	v_auth_scope_name		VARCHAR2(255);
	v_auth_scope			VARCHAR2(4000);
	v_created_dtm			DATE;
	v_updated_dtm			DATE;
	v_cache_key				VARCHAR2(1024);
	v_login_hint			VARCHAR2(1024);
	v_has_key				NUMBER(1);
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;

BEGIN
	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	 WHERE label = v_label;

	credentials_pkg.GetSelectedCredential(
		in_credential_id => v_credential_id,
		out_cur 		 => v_out_cur
	);

  	LOOP
    	FETCH v_out_cur INTO
			v_credential_id, v_label, v_auth_type_id, v_auth_type_name,
			v_created_dtm, v_updated_dtm, v_cache_key, v_login_hint,
			v_has_key, v_auth_scope_id, v_auth_scope_name, v_auth_scope;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
  	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Only single record must be returned');
END;

PROCEDURE TestGetCredentials AS
	v_baselabel				VARCHAR2(255) := 'TestCredentialManagement_GetCredentials';
	v_credential_id			NUMBER;
	v_label					VARCHAR2(255);
	v_auth_type_id			NUMBER;
	v_auth_type_name		VARCHAR2(255);
	v_auth_scope_id			NUMBER;
	v_auth_scope_name		VARCHAR2(255);
	v_auth_scope			VARCHAR2(4000);
	v_created_dtm			DATE;
	v_updated_dtm			DATE;
	v_has_key				NUMBER(1);
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_index_1				NUMBER;
	v_index_2				NUMBER;
	
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_baselabel||'_002',
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);
	credentials_pkg.AddCredential(
		in_label => v_baselabel||'_001',
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	credentials_pkg.GetCredentials(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO
			v_credential_id, v_label, v_auth_type_id, v_auth_type_name,
			v_created_dtm, v_updated_dtm, v_has_key, v_auth_scope_id, v_auth_scope_name, v_auth_scope;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
		
		--dbms_output.put_line('found '||v_label||' at '||v_count);
		IF v_label = v_baselabel||'_001' THEN
			v_index_1 := v_count;
		END IF;
		IF v_label = v_baselabel||'_002' THEN
			v_index_2 := v_count;
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_index_1 < v_index_2, 'Sort order should be correct.');
	unit_test_pkg.AssertIsTrue(v_count >=1, 'Number of saved credentials should be more than one');
END;

PROCEDURE TestGetActiveCredentials AS
	v_baselabel				VARCHAR2(255) := 'TestCredentialManagement_GetActiveCredentials';
	v_app_sid				NUMBER;
	v_credential_id			NUMBER;
	v_label					VARCHAR2(255);
	v_auth_type_id			NUMBER;
	v_auth_type_name		VARCHAR2(255);
	v_cache_key				VARCHAR2(255);
	v_login_hint			VARCHAR2(255);
	v_auth_scope_id			NUMBER;
	v_auth_scope_name		VARCHAR2(255);
	v_auth_scope			VARCHAR2(4000);
	v_created_dtm			DATE;
	v_updated_dtm			DATE;
	v_has_key				NUMBER(1);
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_index_1				NUMBER;
	v_index_2				NUMBER;
	
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_baselabel||'_002',
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);
	credentials_pkg.AddCredential(
		in_label => v_baselabel||'_001',
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);
	credentials_pkg.AddCredential(
		in_label => v_baselabel||'_003',
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	-- add cache/login to 2 of them
	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	  WHERE label = v_baselabel||'_001';

	credentials_pkg.UpdateCredentialCacheKey(
		in_credential_id => v_credential_id,
		in_cache_key => 'UpdatedCacheKey'||'_001',
		in_login_hint => 'UpdatedLoginHint'||'_001'
	);

	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	  WHERE label = v_baselabel||'_002';

	credentials_pkg.UpdateCredentialCacheKey(
		in_credential_id => v_credential_id,
		in_cache_key => 'UpdatedCacheKey'||'_002',
		in_login_hint => 'UpdatedLoginHint'||'_002'
	);


	credentials_pkg.GetActiveCredentials(
		in_auth_type_id	=> NULL,
		out_cur 		=> v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO
			v_app_sid, v_credential_id, v_label, v_auth_type_id, 
			v_created_dtm, v_updated_dtm, v_cache_key, v_login_hint, v_auth_scope_id, v_auth_scope_name, v_auth_scope;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
		
		--dbms_output.put_line('found '||v_label||' at '||v_count);
		IF v_label = v_baselabel||'_001' THEN
			unit_test_pkg.AssertIsTrue(v_cache_key = 'UpdatedCacheKey'||'_001', 'unexpected cache_key.');
			unit_test_pkg.AssertIsTrue(v_login_hint = 'UpdatedLoginHint'||'_001', 'unexpected login_hint.');
			v_index_1 := v_count;
		END IF;
		IF v_label = v_baselabel||'_002' THEN
			unit_test_pkg.AssertIsTrue(v_cache_key = 'UpdatedCacheKey'||'_002', 'unexpected cache_key.');
			unit_test_pkg.AssertIsTrue(v_login_hint = 'UpdatedLoginHint'||'_002', 'unexpected login_hint.');
			v_index_2 := v_count;
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_index_1 < v_index_2, 'Sort order should be correct.');
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Number of saved credentials should be 2');
END;

PROCEDURE TestUpdateCredentialCacheKey AS
	v_credential_id			NUMBER;
	v_label					VARCHAR2(255) := 'TestCredentialManagement_UpdateCredentialCacheKey';
	v_cache_key				VARCHAR2(255);
	v_login_hint			VARCHAR2(255);
	v_result_label			VARCHAR2(255);
BEGIN
	credentials_pkg.AddCredential(
		in_label => v_label,
		in_auth_type_id => 1,
		in_auth_scope_id => 1
	);

	SELECT credential_id
	  INTO v_credential_id
	  FROM credential_management
	  WHERE label = v_label;

	credentials_pkg.UpdateCredentialCacheKey(
		in_credential_id => v_credential_id,
		in_cache_key => 'UpdatedCacheKey',
		in_login_hint => 'UpdatedLoginHint'
	);

	SELECT cache_key, login_hint
	  INTO v_cache_key, v_login_hint
	  FROM credential_management
	  WHERE credential_id = v_credential_id;

	unit_test_pkg.AssertAreEqual(v_cache_key, 'UpdatedCacheKey', 'Updated Cache Key should match');
	unit_test_pkg.AssertAreEqual(v_login_hint, 'UpdatedLoginHint', 'Updated Login Hint should match');
END;


PROCEDURE TestGetAuthenticationTypes AS
	v_out_cur				SYS_REFCURSOR;
	v_count					NUMBER := 0;
	v_auth_type_id			NUMBER;
	v_auth_type_name		VARCHAR2(255);

BEGIN
	
	credentials_pkg.GetAuthenticationTypes(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_auth_type_id,v_auth_type_name;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_count = 2, 'There should be 2 Authentication types');
END;

PROCEDURE TestGetAuthenticationScopes AS
	v_out_cur				SYS_REFCURSOR;
	v_count					NUMBER := 0;
	v_auth_scope_id			NUMBER;
	v_auth_type_id			NUMBER;
	v_auth_scope_name		VARCHAR2(255);
	v_auth_scope			VARCHAR2(255);
	v_hidden				NUMBER;

BEGIN
	
	credentials_pkg.GetAuthenticationScopes(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_auth_scope_id, v_auth_type_id, v_auth_scope_name, v_auth_scope, v_hidden;
		EXIT WHEN v_out_cur%NOTFOUND;
		--Trace('sc:'||v_auth_scope_id||', at:'||v_auth_type_id||', sn:'||v_auth_scope_name||/*', as:'||v_auth_scope||*/', sh:'||v_hidden);
		v_count := v_count +1;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_count = 4, 'There should be 4 Authentication scopes');
END;




PROCEDURE TearDownFixture 
AS
	v_count				NUMBER;
	v_label				VARCHAR2(255);
	v_updated_label		VARCHAR2(255);

BEGIN
	DELETE FROM credential_management
	 WHERE label LIKE 'TestCredentialManagement_%';
END;

END test_credential_management_pkg;
/
