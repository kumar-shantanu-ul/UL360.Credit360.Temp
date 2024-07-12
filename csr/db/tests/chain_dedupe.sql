set serveroutput on
set echo off

exec dbms_output.put_line('chain_dedupe started on '||:bv_site_name);

@@chain_dedupe\cleanup

--todo: move following ddl into the test specific create-schema script
DECLARE
	v_count number;
BEGIN
	SELECT COUNT(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE LOWER(table_name) = 'temp_pp_rule'
	   AND LOWER(owner) = 'chain';	
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE chain.temp_pp_rule (pattern VARCHAR2(10), replacement VARCHAR2(10), apply_to_field	NUMBER(10), apply_to_country VARCHAR(2))';
	END IF;

	SELECT COUNT(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE LOWER(table_name) = 'temp_city_matching'
	   AND LOWER(owner) = 'chain';	
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE chain.temp_city_matching (id NUMBER(10), staging_city VARCHAR2(100), record_city VARCHAR2(100))';
	END IF;
END;
/

-- in case didn't tear down
DELETE FROM chain.temp_pp_rule;
-- in case didn't tear down
DELETE FROM chain.temp_city_matching;
	
exec dbms_output.put_line('chain_dedupe build_dedupe');
@@chain_dedupe\build_dedupe

exec security.user_pkg.logonadmin(:bv_site_name);
@@create_rag_user

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	--we need to tear down everything in case the previous execution failed
	chain.test_chain_dedupe_pkg.SetSite(:bv_site_name);
	chain.test_chain_dedupe_pkg.TearDown;
	chain.test_chain_dedupe_pkg.TearDownFixture;

	chain.test_chain_cms_dedupe_pkg.SetSite(:bv_site_name);
	chain.test_chain_cms_dedupe_pkg.TearDown;
	chain.test_chain_cms_dedupe_pkg.TearDownFixture;

	chain.test_chain_user_dedupe_pkg.SetSite(:bv_site_name);
	chain.test_chain_user_dedupe_pkg.TearDown;
	chain.test_chain_user_dedupe_pkg.TearDownFixture;

	chain.test_dedupe_partial_pkg.SetSite(:bv_site_name);
	chain.test_dedupe_partial_pkg.TearDown;
	chain.test_dedupe_partial_pkg.TearDownFixture;
	
	chain.test_chain_substitution_pkg.SetSite(:bv_site_name);
	chain.test_chain_substitution_pkg.TearDown;
	chain.test_chain_substitution_pkg.TearDownFixture;
	
	chain.test_dedupe_multisource_pkg.SetSite(:bv_site_name);
	chain.test_dedupe_multisource_pkg.TearDown;
	chain.test_dedupe_multisource_pkg.TearDownFixture;

	chain.test_dedupe_purchaser_pkg.SetSite(:bv_site_name);
	chain.test_dedupe_purchaser_pkg.TearDown;
	chain.test_dedupe_purchaser_pkg.TearDownFixture;

	chain.test_dedupe_imp_src_active_pkg.SetSite(:bv_site_name);
	chain.test_dedupe_imp_src_active_pkg.TearDown;
	chain.test_dedupe_imp_src_active_pkg.TearDownFixture;
END;
/

----------------------------------
--chain company core data tests
exec dbms_output.put_line('chain_dedupe create_chain_dedupe_staging');
@@chain_dedupe\create_chain_dedupe_staging

grant all on rag.sap_company_staging to chain;
grant all on rag.bsci_company_staging to chain;
grant all on rag.tertiary_company_staging to chain;

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	csr.enable_pkg.enablePortal;
END;
/

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_chain_dedupe_pkg', csr.unit_test_pkg.T_TESTS(
		'TestMatch_NameCountryRule', 'TestMatch_RefRule', 'TestMatch_TypePostDateRule', 'TestMatch_AllRules',
		'TestMatch_SectorAddress','TestMatch_AddressTagGroup', 'TestNoMatch_CreateCompany', 'TestMatch_MergeCompanyData', 'Test_DataMergedFromHigherPrior',
		'TestManualReview_Create', 'TestRuleManualReview_Merge', 'TestAuto_MultipleMatches', 'TestMatch_AltNameCountryRule', 'TestFlagFillNullsUnderUI'),
		:bv_site_name
	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_chain_dedupe_pkg;

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	-- Unregister table if there is one
	FOR r IN (
		SELECT oracle_table
		  FROM cms.tab
		 WHERE oracle_schema = 'RAG'
		   AND oracle_table IN ('SAP_COMPANY_STAGING','BSCI_COMPANY_STAGING','TERTIARY_COMPANY_STAGING')
	)
	LOOP
		cms.tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table => r.oracle_table
		);
	END LOOP;

	-- Drop table if there is one
	FOR r IN (
		SELECT table_name
		  FROM ALL_TABLES
		 WHERE OWNER = 'RAG'
		   AND TABLE_NAME IN ('SAP_COMPANY_STAGING','BSCI_COMPANY_STAGING','TERTIARY_COMPANY_STAGING')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.'||r.TABLE_NAME;
	END LOOP;
END;
/

--------------------------
--CMS merging unit tests
exec dbms_output.put_line('chain_dedupe create_cms_dedupe_staging');
@@chain_dedupe\create_cms_dedupe_staging

grant all on rag.CMS_COMPANY_STAGING to chain;

-- force compile as for some reason I am getting "existing state of package body...has been invalidated"
@@chain_dedupe\test_chain_cms_dedupe_pkg
@@chain_dedupe\test_chain_cms_dedupe_body
BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_chain_cms_dedupe_pkg', csr.unit_test_pkg.T_TESTS(
		'Test_ParseCmsData', 'Test_ParseEnumData', 'Test_ProcessRecord', 'Test_TwoSourcesSameDest',
		'Test_TwoSourcesDiffDest', 'Test_ProcessWithMissingMand', 'Test_ChildCmsDataCreate',
		'Test_ChildCmsDataCreateUpdate', 'Test_ChildCmsDataUpdate', 
		'Test_CmsDataAnotherCmpnyCreate', 'Test_CmsDataAnotherCmpnyUpdate', 'Test_TwoCmsChildTab',
		'Test_ChildCmsDataMultipleComp'),
		:bv_site_name
	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_chain_cms_dedupe_pkg;

DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(30); --table names
	v_list t_tabs := t_tabs(
		'CMS_COMPANY_STAGING',
		'CMS_COMPANY_STAGING_2',
		'COMPANY_DATA',
		'COMPANY_DATA_2',
		'COMPANY_DATA_4',
		'SCORE_BAND_MAP',
		'SCORE_BAND',
		'MERCH_CAT',
		'SALES_ORG',
		'COMPANY_SALES_ORG',
		'CHILD_CMS_COMPANY_STAGING',
		'CHILD_CMS_COMPANY_STAGING_1',
		'CHILD_CMS_COMPANY_STAGING_4',
		'CMS_COMPANY_STAGING_3',
		'CMS_COMPANY_STAGING_4'
	);
BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	-- Unregister table if there is one
	FOR i IN 1 .. v_list.COUNT
	LOOP
		FOR r IN (
			SELECT oracle_table
			  FROM cms.tab
			 WHERE oracle_schema = 'RAG'
			   AND oracle_table = v_list(i)
		)
		LOOP
			cms.tab_pkg.UnregisterTable(
				in_oracle_schema => 'RAG',
				in_oracle_table	 => r.oracle_table
			);
		END LOOP;
	END LOOP;

	FOR i IN 1 .. v_list.COUNT
	LOOP
		cms.tab_pkg.DropTable('RAG', v_list(i), true);
	END LOOP;
END;
/

--------------------------
--User merging unit tests
exec dbms_output.put_line('chain_dedupe create_user_dedupe_staging');
@@chain_dedupe\create_user_dedupe_staging

grant all on rag.USER_STAGING to chain;

-- force compile as for some reason I am getting "existing state of package body...has been invalidated"
@@chain_dedupe\test_chain_user_dedupe_pkg
@@chain_dedupe\test_chain_user_dedupe_body
BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_chain_user_dedupe_pkg', csr.unit_test_pkg.T_TESTS('Test_UserImport',
	'Test_ImportExistingUser', 'Test_MandatoryFields', 'Test_CmsAndUserImport', 'Test_CmsAndUserImportManual',
	'Test_PriorityFullFriendly', 'Test_CTRoles','Test_CTRoles2', 'Test_ImportUserNowAnonymised'),
	:bv_site_name);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_chain_user_dedupe_pkg;

DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(30); --table names
	v_list t_tabs := t_tabs(
		'CMS_COMPANY_STAGING',
		'CMS_COMPANY_STAGING_2',
		'COMPANY_DATA',
		'COMPANY_DATA_2',
		'SCORE_BAND_MAP',
		'SCORE_BAND',
		'MERCH_CAT',
		'SALES_ORG',
		'COMPANY_SALES_ORG',
		'CHILD_CMS_COMPANY_STAGING',
		'CHILD_CMS_COMPANY_STAGING_1',
		'CMS_COMPANY_STAGING_3',
		'USER_STAGING',
		'USER_COMPANY_STAGING'
	);
BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	-- Unregister table if there is one
	FOR i IN 1 .. v_list.COUNT
	LOOP
		FOR r IN (
			SELECT oracle_table
			  FROM cms.tab
			 WHERE oracle_schema = 'RAG'
			   AND oracle_table = v_list(i)
		)
		LOOP
			cms.tab_pkg.UnregisterTable(
				in_oracle_schema => 'RAG',
				in_oracle_table	 => r.oracle_table
			);
		END LOOP;
	END LOOP;

	FOR i IN 1 .. v_list.COUNT
	LOOP
		cms.tab_pkg.DropTable('RAG', v_list(i), true);
	END LOOP;
END;
/

----------------------------------
--preprocessing tests
exec dbms_output.put_line('chain_dedupe preprocessing');

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_chain_preprocess_pkg', csr.unit_test_pkg.T_TESTS('Test_Output'), :bv_site_name);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_chain_preprocess_pkg;

--------------------------
--Partial matching unit tests

@@chain_dedupe\create_shared_staging

-- force compile as for some reason I am getting "existing state of package body...has been invalidated"
@@chain_dedupe\test_dedupe_partial_pkg
@@chain_dedupe\test_dedupe_partial_body
BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_dedupe_partial_pkg',
		csr.unit_test_pkg.T_TESTS(
			'TestMatch_PartialNameCntryPost', 'TestProcess_AutoRuleSet', 'TestProcess_ManualRuleSet',
			'TestNoMatchAutoCreate', 'TestNoMatchPark', 'TestNoMatchManualReview','TestNormalisedValsMatching',
			'TestNormalisedValsNOMatching', 'TestRuleTypeContains', 'TestMultFldMatchUsingPreproc',
			'TestMultipleMatchAutoRuleSet', 'TestMatchAddressMultiColumns', 'TestMatchAddressSingleColumn',
			'TestPotentialAddressNoMatch', 'TestPartAddNameExactPCCntry', 'TestAutoAddrNamePCCntryMatch', 'TestMergeAltCompNameAddress'
		),
		:bv_site_name
	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_dedupe_partial_pkg;
@@chain_dedupe\destroy_shared_staging

----------------------------------
--substitution tests
exec dbms_output.put_line('chain_dedupe substitution');

@@chain_dedupe\create_shared_staging

@@chain_dedupe\test_chain_substitution_pkg
@@chain_dedupe\test_chain_substitution_body

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests(
		'chain.test_chain_substitution_pkg', 
		csr.unit_test_pkg.T_TESTS(
			'Test_SingleMatchNoSubNoPP', 'Test_SingleMatchNoSubWithPP', 'Test_NoMatch', 
			'Test_SingleMatchWithSubNoPP', 'Test_SingleMatchWithSubWithPP', 'Test_MultiMatchWithWithoutSub'
		),
		:bv_site_name
	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_chain_substitution_pkg;

@@chain_dedupe\destroy_shared_staging

DROP TABLE chain.temp_pp_rule PURGE;
DROP TABLE chain.temp_city_matching PURGE;

@@chain_dedupe\create_multisource_staging

@@chain_dedupe\test_dedupe_multisource_pkg
@@chain_dedupe\test_dedupe_multisource_body

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests(
		'chain.test_dedupe_multisource_pkg', csr.unit_test_pkg.T_TESTS('Test_merge', 'TestMultiSrcAltCompNameMerge','Test_Relationship_Merge'),
		:bv_site_name
	);
END;
/

DROP PACKAGE chain.test_dedupe_multisource_pkg;


exec dbms_output.put_line('chain_dedupe purchaser');
@@chain_dedupe\create_purchaser_company_dedupe_staging

@@chain_dedupe\test_dedupe_purchaser_pkg
@@chain_dedupe\test_dedupe_purchaser_body

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests(
		'chain.test_dedupe_purchaser_pkg',
		csr.unit_test_pkg.T_TESTS(
			'TestNoMatchAutoCreate', 'TestOneMatchAutoMerge', 'TestNoMatchManualCreate', 'TestMatchManualMerge',
			'TestNoMatchCreateCompFailRel', 'TestOneMatchMergeCompFailRel', 'TestLoopRelMerge', 'TestIndirectLoopRelMerge'			
		),
		:bv_site_name
	);
END;
/

DROP PACKAGE chain.test_dedupe_purchaser_pkg;

exec dbms_output.put_line('chain_dedupe pending');
@@chain_dedupe\test_dedupe_pending_pkg
@@chain_dedupe\test_dedupe_pending_body

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests(
		'chain.test_dedupe_pending_pkg', csr.unit_test_pkg.T_TESTS('TestMatchesDefaultSet', 
		'TestDedupeNewCompanyMatches', 'TestMultipleMatchTypeNameCntr',
		'TestRequestExactMatchRef', 'TestRequestExactMatchNameCnt', 'TestRequestSuggMatchNameAddr',
		'TestLevenshteinEmailMatch','TestExactMatchEmail','TestJarowinklerMatchEmail', 'TestContainsMatchEmail','TestBlackListedEmail',
		'TestRequestExactMatchWebsite', 'TestRequestHttpWebsite','TestRequestRestriDomainSite', 'TestRequestPartMatchWebsite',
		'TestRequestExactMatchPhone', 'TestRequestPartMatchPhone', 'TestRequestNonNumericPhone', 'TestRequestContainsPhone'),
		:bv_site_name
	);
END;
/

DROP PACKAGE chain.test_dedupe_pending_pkg;

exec dbms_output.put_line('chain_dedupe imp_source_active');
@@chain_dedupe\create_imp_source_active_staging :bv_site_name

@@chain_dedupe\test_dedupe_imp_src_active_pkg
@@chain_dedupe\test_dedupe_imp_src_active_body

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests(
		'chain.test_dedupe_imp_src_active_pkg', csr.unit_test_pkg.T_TESTS(
			'TestImpSrcActiveNoNoMatch', 'TestImpSrcActiveYesNoMatch',
			'TestImpSrcActiveNoMatch', 'TestImpSrcActiveYesMatch',
			'TestImpSrcNoNoMatchActDeactDtm', 'TestImpSrcYsNoMatchActDeactDtm',
			'TestImpSrcNoMatchActDeactDtm', 
			'TestImpSrcYesMatchActDeactDtm'
		),
		:bv_site_name
	);
END;
/

DROP PACKAGE chain.test_dedupe_imp_src_active_pkg;

@@chain_dedupe\cleanup

set echo on
