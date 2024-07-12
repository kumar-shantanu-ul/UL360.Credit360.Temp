CREATE OR REPLACE PACKAGE BODY chain.company_filter_pkg
IS

-- private field filter units
PROCEDURE FilterCountry					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCountryRiskLevel		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterName					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompanySid				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompanyTypeId			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterReference				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSector					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterBusinessUnit			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCity					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterState					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAddress					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPostcode				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPhone					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFax						(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterWebsite					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDtm				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivatedDtm			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInvitationStatus		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInvitationSentDtm		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInvitationSentFrom		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFollowers				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSuppByScoreLastChangedOn(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSuppByScoreLastChangedBy(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowState				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCanSeeAllCompanies		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSupplierOf				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER,  in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAudits					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterBusinessRelationships	(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCertifications			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_cert_type_id IN VARCHAR2, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRelationshipStatus		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActive					(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProducts				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSuppliersBySupRelScore	(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE Search						(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPrimaryPurchaser		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInd						(in_filter_id IN  filter.filter_id%TYPE, in_filter_field_id IN  NUMBER, in_filter_field_name IN  filter_field.name%TYPE, in_show_all IN  NUMBER, in_ids IN  T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE UNSEC_RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
	v_company_col_sid				security_pkg.T_SID_ID;
	v_stripped_name					VARCHAR2(256);
	v_applies_to_relationships		NUMBER;
BEGIN
	IF in_name LIKE 'CmsFilter%' THEN
		v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
		cms.filter_pkg.FilterColumnIds(in_filter_id, in_filter_field_id, v_compound_filter_id, in_column_sid, in_sids, out_sids);
	ELSIF in_column_sid IS NOT NULL THEN 
		v_company_col_sid := substr(in_name, 0, instr(in_name, '.') - 1);
		v_stripped_name := substr(in_name, length(v_company_col_sid) + 2);
		cms.filter_pkg.FilterEmbeddedField(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_comparator, v_company_col_sid, v_stripped_name, in_column_sid, in_sids, out_sids);
	ELSIF in_name = 'CountryCode' THEN
		FilterCountry(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CountryRiskLevel' THEN
		FilterCountryRiskLevel(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Name' THEN
		FilterName(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'companysid' THEN
		FilterCompanySid(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CompanyTypeId' THEN
		FilterCompanyTypeId(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'ReferenceLabel.%' THEN
		FilterReference(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Sector' THEN
		FilterSector(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'BusinessUnit' THEN
		FilterBusinessUnit(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'City' THEN
		FilterCity(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'State' THEN
		FilterState(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Address' THEN
		FilterAddress(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Postcode' THEN
		FilterPostcode(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Phone' THEN
		FilterPhone(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Fax' THEN
		FilterFax(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Website' THEN
		FilterWebsite(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CreatedDtm' THEN
		FilterCreatedDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ActivatedDtm' THEN
		FilterActivatedDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'InvitationStatusId' THEN
		FilterInvitationStatus(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'InvitationSentDtm' THEN
		FilterInvitationSentDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'InvitationSentFrom' THEN
		FilterInvitationSentFrom(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Followers' THEN
		FilterFollowers(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'ScoreThreshold.%' THEN
		SELECT applies_to_supp_rels
			INTO v_applies_to_relationships
			FROM csr.score_type s
			WHERE in_name = 'ScoreThreshold.'||s.score_type_id;
			 
		IF v_applies_to_relationships = 1 THEN
			FilterSuppliersBySupRelScore(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
		ELSE
			csr.supplier_pkg.FilterSuppliersByScore(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
		END IF;
	ELSIF in_name LIKE 'ScoreLastChangedOn.%' THEN
		FilterSuppByScoreLastChangedOn(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'ScoreLastChangedBy.%' THEN
		FilterSuppByScoreLastChangedBy(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Search' THEN
		Search(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'TagGroup.ProductTypeTag.%' THEN
		product_pkg.FilterCompaniesByProdTypeTags(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'TagGroup.%' THEN
		csr.supplier_pkg.FilterCompaniesByTags(in_filter_id, in_filter_field_id, in_name, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'FlowState' THEN
		FilterFlowState(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'RelStatusId' THEN
		FilterCanSeeAllCompanies(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ProductType' THEN
		product_pkg.FilterCompaniesByProductType(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'SupplierOf' THEN
		FilterSupplierOf(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'savedfilter' THEN
		FilterSavedFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_comparator, in_sids, out_sids);
	ELSIF in_name = 'AuditFilter' THEN
		FilterAudits(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'BusinessRelationshipFilter' THEN
		FilterBusinessRelationships(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'RelationshipStatus' THEN
		FilterRelationshipStatus(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Active' THEN
		FilterActive(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'CompanyCertificationFilter%' THEN
		FilterCertifications(in_filter_id, in_filter_field_id, REPLACE(in_name, 'CompanyCertificationFilter.', ''), in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ProductFilter' THEN
		FilterProducts(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'PrimaryPurchaser' THEN
		FilterPrimaryPurchaser(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'FilterPageIndInterval%' THEN
		FilterInd(in_filter_id, in_filter_field_id, in_name, in_show_all, in_sids, out_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_sids							chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	GetInitialIds(
		in_search					=> NULL,
		in_group_key				=> NULL,
		in_pre_filter_sid			=> NULL,
		in_region_sids				=> NULL,
		in_start_dtm				=> NULL,
		in_end_dtm					=> NULL,
		in_region_col_type			=> NULL,
		in_date_col_type			=> NULL,
		in_id_list					=> in_sids,
		out_id_list					=> v_sids
	);

	UNSEC_RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> in_column_sid,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_sids						=> v_sids,
		out_sids					=> out_sids
	);
END;

PROCEDURE FilterCompanySids (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_sids							IN  T_FILTERED_OBJECT_TABLE,
	out_sids						OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_value_id						NUMBER;
	v_starting_sids					T_FILTERED_OBJECT_TABLE;
	v_result_sids					T_FILTERED_OBJECT_TABLE;
	cert_group_key					VARCHAR2(256);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_inner_log_id					debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_sids := in_sids;

	IF in_parallel = 0 THEN
		out_sids := in_sids;
	ELSE
		out_sids := T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.FilterCompanySids', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.FilterCompanySids.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		UNSEC_RunSingleUnit(
			in_name				=> r.name,
			in_comparator		=> r.comparator,
			in_column_sid		=> r.column_sid,
			in_filter_id		=> in_filter_id,
			in_filter_field_id	=> r.filter_field_id,
			in_group_by_index	=> r.group_by_index,
			in_show_all			=> r.show_all,
			in_sids				=> v_starting_sids,
			out_sids			=> v_result_sids
		);
		
		filter_pkg.EndDebugLog(v_inner_log_id);

		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN 
			chain.filter_pkg.InvertFilterSet(v_starting_sids, v_result_sids, v_result_sids);
		END IF;
		
		IF in_parallel = 0 THEN
			v_starting_sids := v_result_sids;
			out_sids := v_result_sids;
		ELSE
			out_sids := out_sids MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CopyFilter (
	in_from_filter_id			IN	filter.filter_id%TYPE,
	in_to_filter_id				IN	filter.filter_id%TYPE
)
AS
BEGIN
	filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_parallel					IN	NUMBER,
	in_max_group_by				IN	NUMBER,
	in_company_sid_list			IN	T_FILTERED_OBJECT_TABLE,
	out_company_sid_list		OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	filter_pkg.RunCompoundFilter('FilterCompanySids', in_compound_filter_id, in_parallel, in_max_group_by, in_company_sid_list, out_company_sid_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_company_sid_list		IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM tt_filter_object_data;
	
	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN SUPPLIER_COUNT THEN filter_pkg.AFUNC_COUNT
			END,
			CASE a.column_value
				WHEN SUPPLIER_COUNT THEN l.object_id
			END
	  FROM /*company c
	  JOIN*/ TABLE(in_company_sid_list) l /*ON c.company_sid = l.object_id*/
	  CROSS JOIN TABLE(in_aggregation_types) a
	;
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sids					security.T_SID_TABLE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
	v_tmp_id_list					chain.T_FILTERED_OBJECT_TABLE;
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_can_see_all_companies			company.can_see_all_companies%TYPE;
	v_no_rel_permissions			T_PERMISSIBLE_TYPES_TABLE;
	v_supplier_sids					security.T_SID_TABLE;
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetInitialIds');

	v_company_sids := company_pkg.GetVisibleCompanySids;
	IF in_id_list IS NULL THEN
		SELECT T_FILTERED_OBJECT_ROW(column_value, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM TABLE(v_company_sids);
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(a.column_value, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM TABLE(v_company_sids) a
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) b ON b.object_id = a.column_value;
	END IF;	 

	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = v_company_sid;
	
	IF v_can_see_all_companies = 0 THEN

		v_supplier_sids := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);
		v_no_rel_permissions := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.SUPPLIER_NO_RELATIONSHIP, security_pkg.PERMISSION_READ);
	
		SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
		  BULK COLLECT INTO v_tmp_id_list
		  FROM TABLE(v_id_list) t
		  JOIN (
				SELECT v_company_sid company_sid
				  FROM dual
				 UNION
				SELECT c.company_sid
				  FROM company c
				  JOIN TABLE(v_supplier_sids) sups ON sups.column_value = c.company_sid
				 WHERE c.deleted = 0
				   AND c.pending = 0
				 UNION
				SELECT c.company_sid
				  FROM company c
				  JOIN TABLE(v_no_rel_permissions) no_rel ON no_rel.secondary_company_type_id = c.company_type_id
				 WHERE c.deleted = 0
				   AND c.pending = 0
				 UNION
				SELECT i.to_company_sid company_sid
				  FROM company c
				  JOIN invitation i ON i.to_company_sid = c.company_sid
				 WHERE c.deleted = 0
				   AND c.pending = 0
				   AND c.active = 0
				   AND (i.from_company_sid = v_company_sid OR i.on_behalf_of_company_sid = v_company_sid)
		  ) c ON c.company_sid = t.object_id;
			
		v_id_list := v_tmp_id_list;
	END IF;
	
	filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	IF v_has_regions = 1 THEN
		SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
		  BULK COLLECT INTO v_tmp_id_list
		  FROM TABLE(v_id_list) t
		  JOIN csr.supplier s ON t.object_id = s.company_sid
		  JOIN csr.temp_region_sid r ON s.region_sid = r.region_sid;
	
		v_id_list := v_tmp_id_list;
	END IF;
	
	IF in_search IS NOT NULL THEN
		Search(in_search, v_id_list, v_id_list);
	END IF;
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			IF r.search_text IS NOT NULL THEN
				Search(r.search_text, v_id_list, v_id_list);
			END IF;

			IF NVL(r.compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
				RunCompoundFilter(r.compound_filter_id, 0, NULL, v_id_list, v_id_list);
			END IF;
		END LOOP;
	END IF;
	  
	out_id_list := v_id_list;

	aspen2.request_queue_pkg.AssertRequestStillActive;
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN  compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_can_see_all_companies			company.can_see_all_companies%TYPE;
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
	v_tmp_id_list					chain.T_FILTERED_OBJECT_TABLE;
	v_supplier_sids					security.T_SID_TABLE;
	v_no_rel_permissions			T_PERMISSIBLE_TYPES_TABLE;
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE;
	v_sub_permissions				T_PERMISSIBLE_TYPES_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetFilteredIds');
	
	SELECT MIN(can_see_all_companies)
	  INTO v_can_see_all_companies
	  FROM company
	 WHERE company_sid = v_company_sid;
	
	IF in_id_list_populated = 0 THEN
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_region_sids, in_start_dtm, in_end_dtm,
			in_region_col_type, in_date_col_type, in_id_list, v_id_list);
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM chain.tt_filter_id;
	END IF;

	IF in_parent_id = v_company_sid THEN

		-- If you've got can_see_all_companies, then we regard all companies as your 'supplier's, no matter what the relationships say,
		-- so we can leave the ID list alone.  Otherwise, we need to do some filtering.

		IF v_can_see_all_companies = 0 THEN
			v_supplier_sids := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);
			v_no_rel_permissions := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.SUPPLIER_NO_RELATIONSHIP, security_pkg.PERMISSION_READ);
			
			SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
			  BULK COLLECT INTO v_tmp_id_list
			  FROM TABLE(v_id_list) ids
			  JOIN (
					SELECT sc.company_sid
					  FROM supplier_relationship sr
					  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
					  JOIN TABLE(v_supplier_sids) sups ON sc.company_sid = sups.column_value
					 WHERE sr.purchaser_company_sid = v_company_sid
					   AND sr.deleted = 0
					   AND sc.deleted = 0
					 UNION
					SELECT c.company_sid
					  FROM company c
					  JOIN TABLE(v_no_rel_permissions) no_rel ON no_rel.secondary_company_type_id = c.company_type_id
					 WHERE c.deleted = 0
					   AND c.pending = 0
					 UNION
					SELECT i.to_company_sid company_sid
					  FROM invitation i
					  JOIN company c ON i.to_company_sid = c.company_sid
					 WHERE c.deleted = 0
					   AND c.pending = 0
					   AND c.active = 0
					   AND (i.from_company_sid = v_company_sid OR i.on_behalf_of_company_sid = v_company_sid)
			  ) t on t.company_sid = ids.object_id;
			
			v_id_list := v_tmp_id_list;

		END IF;

	ELSIF in_parent_id IS NOT NULL THEN
	
		IF v_can_see_all_companies = 1 THEN
		
			SELECT T_FILTERED_OBJECT_ROW(t.company_sid, NULL, NULL)
			  BULK COLLECT INTO v_tmp_id_list
			  FROM TABLE(v_id_list) ids
			  JOIN (
					SELECT sc.company_sid
					  FROM supplier_relationship sr
					  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
					 WHERE sc.deleted = 0
					   AND sc.pending = 0
					   AND sr.deleted = 0
					   AND sr.active = 1
					   AND sr.purchaser_company_sid = in_parent_id
					UNION
					SELECT i.to_company_sid
					  FROM invitation i
					  JOIN company c ON i.to_company_sid = c.company_sid
					 WHERE c.deleted = 0
					   AND c.pending = 0
					   AND c.active = 0
					   AND (i.from_company_sid = in_parent_id OR i.on_behalf_of_company_sid = in_parent_id)
			  ) t on t.company_sid = ids.object_id;
			
			v_id_list := v_tmp_id_list;

		ELSE
		
			IF NOT capability_pkg.CheckCapability(in_parent_id, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_parent_id);
			END IF;

			v_rel_permissions := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.VIEW_RELATIONSHIPS);
			v_sub_permissions := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);
	
			SELECT T_FILTERED_OBJECT_ROW(t.company_sid, NULL, NULL)
			  BULK COLLECT INTO v_tmp_id_list
			  FROM TABLE(v_id_list) ids
			  JOIN (
				SELECT sc.company_sid
				  FROM supplier_relationship sr
				  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
				  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
				  JOIN TABLE(v_rel_permissions) ct ON pc.company_type_id = ct.secondary_company_type_id AND sc.company_type_id = ct.tertiary_company_type_id
				 WHERE sr.deleted = 0
				   AND sr.active = 1
				   AND sc.deleted = 0
				   AND sc.pending = 0
				   AND pc.deleted = 0
				   AND pc.pending = 0
				   AND pc.company_sid = in_parent_id
				 UNION
				SELECT sc.company_sid
				  FROM company pc
				  JOIN company sc ON sc.parent_sid = pc.company_sid
				  JOIN TABLE(v_sub_permissions) ct ON pc.company_type_id = ct.secondary_company_type_id AND sc.company_type_id = ct.tertiary_company_type_id
				 WHERE sc.deleted = 0
				   AND sc.pending = 0
				   AND pc.deleted = 0
				   AND pc.pending = 0
				   AND pc.company_sid = in_parent_id
			  ) t on t.company_sid = ids.object_id;
			
			v_id_list := v_tmp_id_list;

		END IF;

	END IF;
		
	aspen2.request_queue_pkg.AssertRequestStillActive;
	filter_pkg.EndDebugLog(v_log_id);
	
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;
	
	out_id_list := v_id_list;
END;

PROCEDURE ConvertIdsToRegionSids(
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_region_sids					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(s.region_sid, t.group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_region_sids
	  FROM TABLE(in_id_list) t
	  JOIN csr.supplier s ON s.company_sid = t.object_id;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.ApplyBreadcrumb');
	
	out_id_list := in_id_list;

	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN

		v_field_compound_filter_id := filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);
	
		RunCompoundFilter(v_field_compound_filter_id, 1, v_breadcrumb_count, out_id_list, out_id_list);
		
		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN
			-- Use the aggregation type for drilldowns on "other"
			-- If not supplied, use count
			SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;

			GetFilterObjectData (v_aggregation_types, out_id_list);
			
			-- apply top n
			v_top_n_values := filter_pkg.FindTopN(v_field_compound_filter_id, NVL(in_aggregation_type, 1), out_id_list, in_breadcrumb);
			
			-- update any rows that aren't in top N to -group_by_index, indicating they're "other"
			SELECT T_FILTERED_OBJECT_ROW (l.object_id, l.group_by_index, CASE WHEN t.pos IS NOT NULL THEN l.group_by_value ELSE -ff.filter_field_id END)
			  BULK COLLECT INTO v_temp
			  FROM TABLE(out_id_list) l
			  JOIN v$filter_field ff ON l.group_by_index = ff.group_by_index AND ff.compound_filter_id = v_field_compound_filter_id
			  LEFT JOIN TABLE(v_top_n_values) t ON l.group_by_value = t.pos;
		ELSE
			v_temp := out_id_list;
		END IF;
		
		-- apply breadcrumb
		filter_pkg.ApplyBreadcrumb(v_temp, in_breadcrumb, out_id_list);
	END IF;
	
	filter_pkg.EndDebugLog(v_log_id);
END;

 -- Before: invitation_sent_dtm and invitation status did not always refer to the same invitation
 -- Get the primary company contacts by the most significant invitation (invitation_status_id, invitation_sent_dtm)
 -- If there is no invitation get the chain_company_user admin by csr_user creation dtm (this is just a convention because csr_user is not chain_company specific)
 -- Moved from report_pkg
FUNCTION GetPrimaryContacts(
	in_company_sid_page			IN  security.T_ORDERED_SID_TABLE
) RETURN T_PRIMARY_CONTACT_TABLE
AS v_primary_contacts	T_PRIMARY_CONTACT_TABLE;
BEGIN

	SELECT CHAIN.T_PRIMARY_CONTACT_ROW(company_id, user_id)
	  BULK COLLECT INTO v_primary_contacts 
	  FROM (
		
		--Get the user from most significant invitation per company
		SELECT inv.company_id, inv.user_id
		  FROM (
				SELECT 
					c.company_sid company_id,
					cuis.user_sid user_id, 			
					ROW_NUMBER() OVER (PARTITION BY c.company_sid ORDER BY DECODE (cuis.invitation_status_id, 
							chain_pkg.ACCEPTED,  1,
							chain_pkg.ACTIVE,    2, 
							chain_pkg.EXPIRED,   3,
							chain_pkg.CANCELLED, 3) NULLS LAST,

							cuis.invitation_sent_dtm 
						)rn 
				  FROM company c
				  JOIN TABLE(in_company_sid_page) f ON (c.company_sid = f.sid_id)  
				  JOIN v$chain_user_invitation_status cuis ON (cuis.company_sid = c.company_sid)
				 WHERE c.deleted = 0
				   AND c.pending = 0
				) inv
		 WHERE inv.rn = 1
				
		UNION
		
		--In case there is no invitation for the company, return the chain_company_user (if exists)
		SELECT usr.company_id, usr.user_id
		  FROM (
			SELECT c.company_sid company_id, gm.member_sid_id user_id,
				   ROW_NUMBER() OVER (PARTITION BY c.company_sid ORDER BY ca.user_sid NULLS LAST, gm.member_sid_id) rn
			  FROM security.group_members gm
			  JOIN v$company_user_group cug on cug.user_group_sid = gm.group_sid_id
			  JOIN company c ON cug.company_sid = c.company_sid
			  JOIN TABLE(in_company_sid_page) f ON (c.company_sid = f.sid_id)  
			  LEFT JOIN (
				SELECT gm2.member_sid_id user_sid, cag.company_sid
				  FROM security.group_members gm2
				  JOIN v$company_admin_group cag on gm2.group_sid_id = cag.admin_group_sid
			   ) ca ON gm.member_sid_id = ca.user_sid AND ca.company_sid = cug.company_sid
			 WHERE c.deleted = 0
			   AND c.pending = 0
			   AND NOT EXISTS (
				SELECT 1
				  FROM v$chain_user_invitation_status cuis
				 WHERE cuis.company_sid = c.company_sid
			 )
		  ) usr
		 WHERE usr.rn = 1
	);
	  
	RETURN v_primary_contacts;
END;

PROCEDURE CollectSearchResults (
	in_company_sid_page				IN	security.T_ORDERED_SID_TABLE,
	out_cur							OUT SYS_REFCURSOR,
	out_scores_cur					OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT	SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_score_perm_sids_table			security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_page, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
	v_score_log_perm_sids_table		security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_page, chain_pkg.VIEW_COMPANY_SCORE_LOG);
	v_tags_perm_sids_table			security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_page, chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ);
	v_deactivate_perm_sids_table	security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_page, chain_pkg.DEACTIVATE_COMPANY);
	v_cert_perm_sids_table			security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_page, chain_pkg.VIEW_CERTIFICATIONS);
	v_view_crl						NUMBER(1);
	v_primary_contacts				T_PRIMARY_CONTACT_TABLE := GetPrimaryContacts(in_company_sid_page);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_audits_for_user_table			security.T_SID_TABLE;
	v_audits_sid					security.security_pkg.T_SID_ID;
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_reference_perms				T_REF_PERM_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.CollectSearchResults');

	capability_pkg.CheckCapability(chain_pkg.VIEW_COUNTRY_RISK_LEVELS, v_view_crl);

	OPEN out_cur FOR
		SELECT c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm, c.address_1, c.address_2, c.address_3,
			   c.address_4, c.state, c.city, c.postcode, c.country_code, c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid,
			   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, c.user_level_messaging,
			   c.sector_id, c.country_name, c.sector_description, c.can_see_all_companies, c.company_type_id,
			   c.company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand, c.parent_sid, c.parent_name,
			   c.parent_country_code, c.parent_country_name, c.country_is_hidden, c.region_sid,
			   NVL(sr.active, chain_pkg.inactive) active_supplier, 
		       CASE WHEN sr.primary_follower_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 END is_primary_follower, 
			   sr.supp_rel_code, c.company_type_description, 
			   CASE sr.active WHEN 0 THEN chain_pkg.PENDING_RELATIONSHIP_DESC WHEN 1 THEN chain_pkg.ACTIVE_RELATIONSHIP_DESC ELSE chain_pkg.NO_RELATIONSHIP_DESC END relationship_status,
			   fs.label flow_state_label, fs.state_colour flow_state_colour, tu.full_name || DECODE(tcu.deleted, 1, ' (deleted)') first_contact_name,
		       tu.email first_contact_email, tu.job_title first_contact_job_title, tu.phone_number first_contact_phone_number,
		       fu.full_name || DECODE(fcu.deleted, 1, ' (deleted)') invitation_sent_from, cuis.invitation_sent_dtm invitation_sent_date,
		       NVL(ins.description, 'Not invited') invitation_status, r.geo_longitude longitude, r.geo_latitude latitude,
		       CASE WHEN deact.column_value IS NOT NULL THEN 1 ELSE 0 END is_permissible_to_deactivate,
			   CASE WHEN v_view_crl = 1 THEN crl.label ELSE null END country_risk_level
		  FROM v$company c
		  JOIN TABLE(in_company_sid_page) fil_list ON fil_list.sid_id = c.company_sid
		  LEFT JOIN TABLE(v_primary_contacts) pc ON pc.company_id = c.company_sid
		  LEFT JOIN v$chain_user_invitation_status cuis ON cuis.user_sid = pc.user_id AND cuis.company_sid = c.company_sid --get primary contact's most significant invitation data
		  LEFT JOIN csr.csr_user tu ON tu.csr_user_sid = pc.user_id
		  LEFT JOIN chain_user tcu ON tu.csr_user_sid = tcu.user_sid
		  LEFT JOIN csr.csr_user fu ON fu.csr_user_sid = cuis.from_user_sid
		  LEFT JOIN chain_user fcu ON fu.csr_user_sid = fcu.user_sid
		  LEFT JOIN invitation_status ins ON (cuis.invitation_status_id = ins.invitation_status_id)
		  LEFT JOIN (
				 SELECT sr.*, sf.user_sid primary_follower_user_sid
				  FROM supplier_relationship sr, (
						SELECT * 
						  FROM supplier_follower 
						 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
						   AND is_primary IS NOT NULL
					   ) sf
				 WHERE sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				   AND sr.purchaser_company_sid = sf.purchaser_company_sid(+)
				   AND sr.supplier_company_sid = sf.supplier_company_sid(+)
			) sr ON c.app_sid = sr.app_sid AND c.company_sid = sr.supplier_company_sid
		  LEFT JOIN csr.flow_item fi ON sr.app_sid = fi.app_sid AND sr.flow_item_id = fi.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr.region r ON c.app_sid = r.app_sid AND c.region_sid = r.region_sid
		  LEFT JOIN TABLE(v_deactivate_perm_sids_table) deact ON deact.column_value = c.company_sid
		  LEFT JOIN v$current_country_risk_level crl ON c.country_code = crl.country
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY fil_list.pos;

	OPEN out_scores_cur FOR
		--supplier scores
		SELECT s.company_sid, s.score, s.score_type_id, s.score_threshold_id, s.format_mask, s.valid_until_dtm, s.valid,
			   s.score_threshold_description description, sth.text_colour, sth.background_colour, sth.bar_colour,
			   NVL2(slp.column_value, s.score_last_changed, NULL) last_changed_on,
			   NVL2(slp.column_value, s.changed_by_user_full_name, NULL) last_changed_by
		  FROM csr.v$supplier_score s
		  JOIN csr.score_type st ON s.score_type_id = st.score_type_id
		  JOIN (SELECT column_value FROM TABLE(v_score_perm_sids_table) ORDER BY column_value) cts ON s.company_sid = cts.column_value
		  LEFT JOIN (SELECT column_value FROM TABLE(v_score_log_perm_sids_table) ORDER BY column_value) slp ON s.company_sid = slp.column_value
		  LEFT JOIN csr.score_threshold sth on s.score_threshold_id = sth.score_threshold_id
		  JOIN (SELECT DISTINCT sid_id FROM TABLE(in_company_sid_page)) f ON s.company_sid = f.sid_id
		 WHERE (s.valid = 1 OR st.show_expired_scores = 1)
		 UNION
		--relationship scores against context company
		SELECT srs.supplier_company_sid company_sid, srs.score, srs.score_type_id, srs.score_threshold_id, st.format_mask, srs.valid_until_dtm, srs.valid,
			   sth.description, sth.text_colour, sth.background_colour, sth.bar_colour, NULL last_changed_on, NULL last_changed_by
		  FROM v$current_sup_rel_score srs
		  JOIN csr.score_type st ON srs.score_type_id = st.score_type_id
		  JOIN (SELECT column_value FROM TABLE(v_score_perm_sids_table) ORDER BY column_value) cts ON srs.supplier_company_sid = cts.column_value AND srs.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  LEFT JOIN csr.score_threshold sth on srs.score_threshold_id = sth.score_threshold_id
		  JOIN (SELECT DISTINCT sid_id FROM TABLE(in_company_sid_page)) f ON srs.supplier_company_sid = f.sid_id
		  WHERE (srs.valid = 1 OR st.show_expired_scores = 1);

	OPEN out_tags_cur FOR
		SELECT s.company_sid, rt.region_sid, rt.tag_id, tag.tag, tg.tag_group_id, tg.name tag_group_name
		  FROM csr.supplier s
		  JOIN company c ON s.company_sid = c.company_sid AND s.app_sid = c.app_sid
		  JOIN TABLE(in_company_sid_page) t ON t.sid_id = s.company_sid
		  JOIN TABLE(v_tags_perm_sids_table) ps ON s.company_sid = ps.column_value
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
		  JOIN csr.tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
		  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		  JOIN csr.v$tag tag ON rt.tag_id = tag.tag_id AND rt.app_sid = tag.app_sid
		 WHERE tg.applies_to_suppliers = 1
		 ORDER BY tgm.Pos ASC;

	IF (NVL(SYS_CONTEXT('SECURITY', 'SID'),-1) = security_pkg.SID_BUILTIN_ADMINISTRATOR) THEN

		OPEN out_refs_cur FOR
			SELECT cr.company_sid, r.lookup_key, cr.value, cr.reference_id
			  FROM company_reference cr
			  JOIN TABLE(in_company_sid_page) t ON t.sid_id = cr.company_sid
			  JOIN reference r ON cr.reference_id = r.reference_id;

	ELSE

		v_reference_perms:= helper_pkg.GetRefPermsByType;
		
		OPEN out_refs_cur FOR
			SELECT cr.company_sid, r.lookup_key, cr.value, cr.reference_id
			  FROM company_reference cr
			  JOIN TABLE(in_company_sid_page) t ON t.sid_id = cr.company_sid
			  JOIN company c ON c.company_sid = cr.company_sid
			  JOIN reference r ON cr.reference_id = r.reference_id
			  JOIN TABLE(v_reference_perms) rp ON rp.reference_id = cr.reference_id  AND ((
						c.company_sid = v_company_sid AND rp.primary_company_type_id = c.company_type_id AND rp.secondary_company_type_id IS NULL
				   ) OR (
						c.company_sid != v_company_sid AND rp.secondary_company_type_id = c.company_type_id
				   ))
			 WHERE rp.permission_set > 0;

	END IF;

	OPEN out_bus_cur FOR
		SELECT bu.business_unit_id, bu.description, bus.is_primary_bu, bus.supplier_company_sid
		  FROM business_unit bu
		  JOIN business_unit_supplier bus ON bu.business_unit_id = bus.business_unit_id AND bu.app_sid = bus.app_sid
		  JOIN TABLE(in_company_sid_page) t ON t.sid_id = bus.supplier_company_sid
		 ORDER BY bus.supplier_company_sid, LOWER(bu.description);

	OPEN out_followers_cur FOR 
		SELECT su.supplier_company_sid company_sid, cu.user_sid user_sid, cu.full_name user_full_name
		  FROM supplier_follower su
		  JOIN TABLE(in_company_sid_page) t ON t.sid_id = su.supplier_company_sid
		  JOIN v$chain_user cu on cu.user_sid = su.user_sid
		 WHERE su.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND cu.account_enabled = 1
		 ORDER BY su.supplier_company_sid, cu.user_sid;

	BEGIN
		v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL; --It's ok if audits are not enabled
	END;

	IF v_audits_sid IS NOT NULL THEN
		v_audits_for_user_table := csr.audit_pkg.GetAuditsForUserAsTable;
		
		OPEN out_certifications_cur FOR
			SELECT c.certification_id, c.certification_type_id, c.company_sid, iat.label certification_type_label, c.valid_from_dtm, c.expiry_dtm, act.label result, 
				   ia.internal_audit_sid, ia.label internal_audit_label
			  FROM TABLE(v_cert_perm_sids_table) cps
			  JOIN (
					SELECT sc.certification_id, sc.certification_type_id, sc.internal_audit_sid, sc.company_sid, sc.internal_audit_type_id , sc.valid_from_dtm, sc.expiry_dtm,
						sc.audit_closure_type_id, ROW_NUMBER() over(PARTITION BY sc.company_sid, sc.certification_type_id ORDER BY sc.valid_from_dtm DESC) rn
					FROM v$supplier_certification sc 
					JOIN TABLE(in_company_sid_page) t on t.sid_id = sc.company_sid
					) c ON c.company_sid = cps.column_value
			  JOIN csr.internal_audit_type iat ON iat.internal_audit_type_id = c.internal_audit_type_id
			  LEFT JOIN csr.audit_closure_type act ON act.audit_closure_type_id = c.audit_closure_type_id
			  LEFT JOIN (SELECT column_value FROM TABLE(v_audits_for_user_table) ORDER BY column_value) so ON c.internal_audit_sid = so.column_value
			  LEFT JOIN csr.internal_audit ia ON ia.internal_audit_sid = so.column_value
			 WHERE rn = 1;
	ELSE 
		OPEN out_certifications_cur FOR
			SELECT NULL certification_id, NULL certification_type_id, NULL company_sid, NULL certification_type_label, NULL valid_from_dtm, NULL expiry_dtm, NULL result, 
				   NULL internal_audit_sid, NULL internal_audit_label
			  FROM dual 
			 WHERE 1 = 0;
	END IF;


	OPEN out_prim_purchsr_cur FOR
		SELECT sr.supplier_company_sid company_sid, sr.purchaser_company_sid, c.name purchaser_company_name, c.company_type_id purchaser_type_id
		  FROM supplier_relationship sr
		  JOIN company c ON c.company_sid = sr.purchaser_company_sid
		  JOIN TABLE(in_company_sid_page) t ON t.sid_id = sr.supplier_company_sid
		 WHERE sr.is_primary =1
		 ORDER BY c.company_type_id;

	 OPEN out_inds_cur FOR
		SELECT ti.filter_page_ind_interval_id, ti.ind_sid, s.company_sid, ti.period_start_dtm, ti.period_end_dtm, ti.val_number, ti.error_code, ti.note
		  FROM chain.tt_filter_ind_val ti
		  JOIN csr.supplier s ON s.region_sid = ti.region_sid
		  JOIN TABLE(in_company_sid_page) t ON t.sid_id = s.company_sid;

	filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredCompanySids (
	in_company_sid_list				IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_company_sid_list			OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_score_perm_sids_table			security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_list, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
	v_tags_perm_sids_table			security.T_SID_TABLE := type_capability_pkg.FilterPermissibleCompanySids(in_company_sid_list, chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ);
	v_reference_perms				T_REF_PERM_TABLE := helper_pkg.GetRefPermsByType;
	v_order_by						VARCHAR2(255);
	v_order_param	 				NUMBER;
	v_order_by_inner				VARCHAR2(255);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_audits_for_user_table			security.T_SID_TABLE;
	v_audits_sid					security.security_pkg.T_SID_ID;
	v_ord_in_company_sid_list		security.T_ORDERED_SID_TABLE;
	v_cert_perm_sids_table			security.T_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.PageFilteredCompanySids');
	
	IF in_order_by = 'name' AND in_order_dir = 'ASC' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(company_sid, rn)
		  BULK COLLECT INTO out_company_sid_list
		  FROM (
			SELECT x.company_sid, ROWNUM rn
			  FROM (
				SELECT c.company_sid
				  FROM company c
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_company_sid_list)) fil_list ON fil_list.object_id = c.company_sid
				 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.deleted = 0
				   AND c.pending = 0
				 ORDER BY LOWER(name)
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSIF INSTR(in_order_by, '~', 1) > 0 THEN
		filter_pkg.SortExtension(
			'company', 
			in_company_sid_list,
			in_start_row,
			in_end_row,
			in_order_by,
			in_order_dir,
			out_company_sid_list);
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_inner:= regexp_substr(in_order_by,'[A-Z,a-z]+', 1 , 2);
		v_order_param := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		BEGIN
			v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL; --It's ok if audits are not enabled
		END;

		v_audits_for_user_table := csr.audit_pkg.GetAuditsForUserAsTable;

		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO v_ord_in_company_sid_list
		  FROM (SELECT object_id, ROWNUM rn
			FROM TABLE(in_company_sid_list));

		v_cert_perm_sids_table := type_capability_pkg.FilterPermissibleCompanySids(v_ord_in_company_sid_list, chain_pkg.VIEW_CERTIFICATIONS);

		SELECT security.T_ORDERED_SID_ROW(company_sid, rn)
		  BULK COLLECT INTO out_company_sid_list
			  FROM (
				SELECT x.company_sid, ROWNUM rn
				  FROM (
					SELECT c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm, c.address_1, c.address_2, c.address_3,
						   c.address_4, c.state, c.city, c.postcode, c.country_code, c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid,
						   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, c.user_level_messaging,
						   c.sector_id, c.country_name, c.sector_description, c.can_see_all_companies, c.company_type_id,
						   c.company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand, c.parent_sid, c.parent_name,
						   c.parent_country_code, c.parent_country_name, c.country_is_hidden, c.region_sid,
						   NVL(sr.active, chain_pkg.inactive) active_supplier, 
						   CASE WHEN sr.primary_follower_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 END is_primary_follower, 
						   sr.supp_rel_code, c.company_type_description, 
						   CASE sr.active WHEN 0 THEN chain_pkg.PENDING_RELATIONSHIP_DESC WHEN 1 THEN chain_pkg.ACTIVE_RELATIONSHIP_DESC ELSE chain_pkg.NO_RELATIONSHIP_DESC END relationship_status,
						   fs.label flow_state_label,
                           CASE srp.is_primary WHEN 1 THEN cpc.name ELSE NULL END primary_supplier
					  FROM v$company c
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_company_sid_list)) fil_list ON fil_list.object_id = c.company_sid
					  LEFT JOIN (
							 SELECT sr.*, sf.user_sid primary_follower_user_sid
							  FROM supplier_relationship sr, (
									SELECT * 
									  FROM supplier_follower 
									 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
									   AND is_primary IS NOT NULL
								   ) sf
							 WHERE sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
							   AND sr.purchaser_company_sid = sf.purchaser_company_sid(+)
							   AND sr.supplier_company_sid = sf.supplier_company_sid(+)
						) sr ON c.app_sid = sr.app_sid AND c.company_sid = sr.supplier_company_sid
                      LEFT JOIN supplier_relationship srp ON c.company_sid = srp.supplier_company_sid
                      AND srp.is_primary = 1
                      AND c.app_sid = srp.app_sid
                      LEFT JOIN v$company cpc ON srp.purchaser_company_sid = cpc.company_sid
                      AND cpc.app_sid = srp.app_sid
					  LEFT JOIN csr.flow_item fi ON sr.app_sid = fi.app_sid AND sr.flow_item_id = fi.flow_item_id
					  LEFT JOIN csr.flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
					  LEFT JOIN (
						SELECT s.score, s.company_sid, s.app_sid, s.score_type_id, s.score_threshold_description
						  FROM csr.v$supplier_score s
						  JOIN (SELECT column_value FROM TABLE(v_score_perm_sids_table) ORDER BY column_value) cts ON s.company_sid = cts.column_value
						) ss ON c.company_sid = ss.company_sid AND c.app_sid = ss.app_sid AND ss.score_type_id = v_order_param
					  LEFT JOIN (
						SELECT ort.app_sid, ort.company_sid, ort.tag_group_id, csr.stragg(ort.tag) tags
						  FROM (
							SELECT s.app_sid, s.company_sid, tgm.tag_group_id, t.tag
							  FROM csr.supplier s
							  JOIN TABLE(v_tags_perm_sids_table) ps ON s.company_sid = ps.column_value
							  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
							  JOIN csr.tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
							  JOIN csr.v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_param
							 ORDER BY tgm.app_sid, tgm.tag_group_id, tgm.pos
						  ) ort
						 GROUP BY ort.app_sid, ort.company_sid, ort.tag_group_id
						) rt ON c.company_sid = rt.company_sid AND c.app_sid = rt.app_sid
					  LEFT JOIN (
						SELECT cr.app_sid, cr.company_sid, cr.reference_id, cr.value
						  FROM company_reference cr
						  JOIN company c ON cr.company_sid = c.company_sid
						  JOIN TABLE(v_reference_perms) rp ON rp.reference_id = cr.reference_id  AND ((
									c.company_sid = v_company_sid AND rp.primary_company_type_id = c.company_type_id AND rp.secondary_company_type_id IS NULL
							   ) OR (
									c.company_sid != v_company_sid AND rp.secondary_company_type_id = c.company_type_id
							   ))
						 WHERE rp.permission_set > 0
						) cr ON c.company_sid = cr.company_sid AND c.app_sid = cr.app_sid AND cr.reference_id = v_order_param
					  LEFT JOIN csr.supplier s ON s.company_sid = c.company_sid
					  LEFT JOIN (
						SELECT fiv.region_sid, NVL(TO_CHAR(fiv.val_number, '000000000000000000000000.0000000000'), LOWER(fiv.note)) str_val
						  FROM chain.tt_filter_ind_val fiv
						 WHERE fiv.filter_page_ind_interval_id = v_order_param
					  ) im ON s.region_sid = im.region_sid
					  LEFT JOIN (
						SELECT distinct sc.company_sid, ia.label audit_label, sc.valid_from_dtm, sc.expiry_dtm, iat.label type_label, act.label result
						  FROM TABLE(v_cert_perm_sids_table) cps
						  JOIN (
								SELECT sc.certification_id, sc.certification_type_id, sc.internal_audit_sid, sc.company_sid, sc.internal_audit_type_id , sc.valid_from_dtm, sc.expiry_dtm, sc.audit_closure_type_id, 
								ROW_NUMBER() over(PARTITION BY sc.company_sid, sc.certification_type_id ORDER BY sc.valid_from_dtm DESC) rn
								FROM v$supplier_certification sc 
								JOIN TABLE(in_company_sid_list) t on t.object_id = sc.company_sid
								) sc ON sc.company_sid = cps.column_value and sc.certification_type_id = v_order_param
						  JOIN csr.internal_audit_type iat ON iat.internal_audit_type_id = sc.internal_audit_type_id
						  LEFT JOIN csr.audit_closure_type act ON act.audit_closure_type_id = sc.audit_closure_type_id
						  LEFT JOIN (SELECT column_value FROM TABLE(v_audits_for_user_table) ORDER BY column_value) so ON sc.internal_audit_sid = so.column_value
						  LEFT JOIN csr.internal_audit ia ON ia.internal_audit_sid = so.column_value
						 WHERE rn = 1 AND v_audits_sid IS NOT NULL
                        UNION ALL
                        SELECT  NULL company_sid, NULL audit_label, NULL valid_from_dtm, NULL expiry_dtm, NULL type_label, NULL result
						FROM dual 
						WHERE 1 = 0
					  ) cert ON c.company_sid = cert.company_sid
					 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'companySid' THEN TO_CHAR(c.company_sid, '0000000000')
									WHEN 'regionSid' THEN TO_CHAR(c.region_sid, '0000000000')
									WHEN 'name' THEN LOWER(c.name)
									WHEN 'country' THEN LOWER(c.country_name)
									WHEN 'state' THEN LOWER(c.state)
									WHEN 'city' THEN LOWER(c.city)
									WHEN 'sectorDescription' THEN LOWER(c.sector_description)
									WHEN 'companyTypeDescription' THEN LOWER(c.company_type_description)
									WHEN 'phone' THEN LOWER(c.phone)
									WHEN 'fax' THEN LOWER(c.fax)
									WHEN 'website' THEN LOWER(c.website)
									WHEN 'email' THEN LOWER(c.email)
									WHEN 'activatedDate' THEN TO_CHAR(c.activated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDate' THEN TO_CHAR(c.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'score' THEN NVL(CASE WHEN ss.score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ ss.score, 10), '0000000000.0000000000') ELSE TO_CHAR(ss.score, '0000000000.0000000000') END, LOWER(ss.score_threshold_description))
									WHEN 'tagGroup' THEN rt.tags
									WHEN 'relationshipStatus' THEN LOWER(relationship_status)
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'primaryPurchaser' THEN LOWER(primary_supplier)
									WHEN 'ref' THEN LOWER(cr.value)
									WHEN 'ind' THEN NVL(im.str_val, ' ')
									WHEN 'certification' THEN
										CASE (v_order_by_inner)
											WHEN 'auditSid' THEN cert.audit_label
											WHEN 'from' THEN TO_CHAR(cert.valid_from_dtm, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'to' THEN TO_CHAR(cert.expiry_dtm, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'type' THEN TO_CHAR(cert.type_label, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'result' THEN cert.result
										END
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'companySid' THEN TO_CHAR(c.company_sid, '0000000000')
									WHEN 'regionSid' THEN TO_CHAR(c.region_sid, '0000000000')
									WHEN 'name' THEN LOWER(c.name)
									WHEN 'country' THEN LOWER(c.country_name)
									WHEN 'state' THEN LOWER(c.state)
									WHEN 'city' THEN LOWER(c.city)
									WHEN 'sectorDescription' THEN LOWER(c.sector_description)
									WHEN 'companyTypeDescription' THEN LOWER(c.company_type_description)
									WHEN 'phone' THEN LOWER(c.phone)
									WHEN 'fax' THEN LOWER(c.fax)
									WHEN 'website' THEN LOWER(c.website)
									WHEN 'email' THEN LOWER(c.email)
									WHEN 'activatedDate' THEN TO_CHAR(c.activated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDate' THEN TO_CHAR(c.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'score' THEN NVL(CASE WHEN ss.score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ ss.score, 10), '0000000000.0000000000') ELSE TO_CHAR(ss.score, '0000000000.0000000000') END, LOWER(ss.score_threshold_description))
									WHEN 'tagGroup' THEN rt.tags
									WHEN 'relationshipStatus' THEN LOWER(relationship_status)
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'primaryPurchaser' THEN LOWER(primary_supplier)
									WHEN 'ref' THEN LOWER(cr.value)
									WHEN 'ind' THEN NVL(im.str_val, ' ')
									WHEN 'certification' THEN
										CASE (v_order_by_inner)
											WHEN 'auditSid' THEN cert.audit_label
											WHEN 'from' THEN TO_CHAR(cert.valid_from_dtm, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'to' THEN TO_CHAR(cert.expiry_dtm, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'type' THEN TO_CHAR(cert.type_label, 'YYYY-MM-DD HH24:MI:SS')
											WHEN 'result' THEN cert.result
										END
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN c.company_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN c.company_sid END ASC
					) x
					WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_CoSidsToBsciSupIds(
	in_sids					IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO temp_grid_extension_map gem (source_id, linked_type, linked_id)
		SELECT DISTINCT ids.sid_id, filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS, bs.bsci_supplier_id
		  FROM TABLE (in_sids) ids
		  JOIN v$bsci_supplier bs ON ids.sid_id = bs.company_sid;
END;

PROCEDURE INTERNAL_PopGridExtTempTable(
	in_id_page						IN security.T_ORDERED_SID_TABLE
)
AS 
	v_enabled_extensions			SYS_REFCURSOR;
	v_name							chain.grid_extension.record_name%TYPE;
	v_extension_id					chain.grid_extension.extension_card_group_id%TYPE;
BEGIN
	DELETE FROM chain.temp_grid_extension_map;

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_COMPANIES, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS THEN
			INTERNAL_CoSidsToBsciSupIds(in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Company -> '||v_name);
		END IF;

	END LOOP;
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_bounds_north					IN	NUMBER,
	in_bounds_east					IN	NUMBER,
	in_bounds_south					IN	NUMBER,
	in_bounds_west					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_session_prefix				IN	VARCHAR2 DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_geo_filtered_list				chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetList', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		in_id_list_populated	=> in_id_list_populated,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);

	-- Filter by map bounds if appropriate
	IF in_bounds_north IS NOT NULL AND in_bounds_east IS NOT NULL AND in_bounds_south IS NOT NULL AND in_bounds_west IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_geo_filtered_list
		  FROM csr.supplier s
		  JOIN csr.region r ON s.region_sid = r.region_sid
		  JOIN TABLE(v_id_list) t ON s.company_sid = t.object_id
		 WHERE r.geo_longitude-in_bounds_west-360*FLOOR((r.geo_longitude-in_bounds_west)/360) BETWEEN 0 AND in_bounds_east-in_bounds_west
		   AND r.geo_latitude BETWEEN in_bounds_south AND in_bounds_north;

		v_id_list := v_geo_filtered_list;
	END IF;
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredCompanySids(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetReportData(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_aggregation_types			IN	security.T_SID_TABLE DEFAULT NULL,
	in_show_totals					IN	NUMBER DEFAULT NULL,
	in_breadcrumb					IN	security.T_SID_TABLE DEFAULT NULL,
	in_max_group_by					IN	NUMBER DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := SUPPLIER_COUNT;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> in_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);
	
	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_COMPANIES, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
	filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	
	OPEN out_cur FOR
		SELECT t.object_id, c.company_sid, c.company_type_description company_type_label,
			   c.name, c.country_name, c.city city_name, c.address_1, c.address_2
		  FROM v$company c 
		  JOIN TABLE(in_id_list) t ON c.company_sid = t.object_id;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT	SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	-- This line requires code on another branch, but will be required to handle permissions properly when merged
	--v_user_perm_cts					T_CAPABILITY_CHECK_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(chain_pkg.COMPANY_USERS, security_pkg.PERMISSION_READ);
BEGIN
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);
	
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);
	
	INTERNAL_PopGridExtTempTable(v_id_page);
	
	CollectSearchResults(v_id_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
END;

PROCEDURE GetCompanyExportUsers(
	in_sids							IN security_pkg.T_SID_IDS,
	out_cur_company_users			OUT	SYS_REFCURSOR,
	out_cur_company_user_roles		OUT	SYS_REFCURSOR
)
AS
	v_company_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_sids);
BEGIN

	OPEN out_cur_company_users FOR
		SELECT DISTINCT c.company_sid, c.name company_name, ccu.full_name user_full_name, 
			   DECODE(ca.user_sid, NULL, 'No', 'Yes') is_administrator, ccu.email user_email, 
			   ccu.job_title user_job_title, ccu.phone_number user_phone_number,
			   ins.description invitation_status, cuis.invitation_sent_dtm, ccu.user_sid
		  FROM v$chain_company_user ccu
		  JOIN TABLE(v_company_sids) f ON (ccu.company_sid = f.column_value)
		  JOIN company c ON (ccu.company_sid = c.company_sid)
		  LEFT JOIN v$company_admin ca ON (ccu.user_sid = ca.user_sid AND ccu.company_sid = ca.company_sid)
		  LEFT JOIN v$chain_user_invitation_status cuis ON (cuis.user_sid = ccu.user_sid AND cuis.company_sid = c.company_sid)
		  LEFT JOIN invitation_status ins ON (cuis.invitation_status_id = ins.invitation_status_id)
		 ORDER BY LOWER(company_name), is_administrator DESC, user_full_name;
	
	OPEN out_cur_company_user_roles FOR
		SELECT DISTINCT c.company_sid, ccu.user_sid, ctr.role_sid
		  FROM v$chain_company_user ccu
		  JOIN TABLE(v_company_sids) f ON (ccu.company_sid = f.column_value)
		  JOIN company c ON (ccu.company_sid = c.company_sid)
		  JOIN csr.supplier s ON c.company_sid = s.company_sid
		  JOIN company_type_role ctr ON c.company_type_id = ctr.company_type_id
		 WHERE EXISTS (
			SELECT *
			  FROM csr.region_role_member rrm
			 WHERE rrm.user_sid = ccu.user_sid
			   AND rrm.region_sid = s.region_sid
			   AND rrm.role_sid = ctr.role_sid
		 );
END;

/********************************************/
/*		Grid extension support				*/
/********************************************/

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_COMPANIES
	);

	--security trim the list of ids
	GetFilteredIds (
		in_compound_filter_id	=> 0, 
		in_id_list				=> v_id_list,
		out_id_list				=> v_id_list
	);

	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);

	CollectSearchResults(v_id_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE SortAuditSids (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_ordered_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN	
	-- TODO: This should security trim to allowable company sids, but left for now. 
	-- Sorting does not reveal the values only the order of them.
	SELECT T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM csr.internal_audit ia
	  JOIN csr.supplier s ON s.region_sid = ia.region_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = ia.internal_audit_sid;
	  
	-- filter companies
	PageFilteredCompanySids(
		in_company_sid_list				=> v_id_list,
		in_start_row					=> 0,
		in_end_row						=> in_end_row,
		in_order_by 					=> in_order_by,
		in_order_dir					=> in_order_dir,
		out_company_sid_list			=> v_ordered_id_list
	);
	
	SELECT security.T_ORDERED_SID_ROW(internal_audit_sid, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
			SELECT internal_audit_sid, ROWNUM rn
			FROM (
				SELECT internal_audit_sid
				  FROM csr.internal_audit ia
				  JOIN TABLE(in_id_list) iia ON ia.internal_audit_sid = iia.object_id
				  LEFT JOIN csr.supplier s ON s.region_sid = ia.region_sid
				  LEFT JOIN TABLE(v_ordered_id_list) x ON s.company_sid = x.sid_id
				  ORDER BY x.pos NULLS LAST
			 ) y
			 WHERE ROWNUM <= in_end_row
		)
	  WHERE rn > in_start_row;
END;


PROCEDURE SortNonCompIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_ordered_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN	
	-- TODO: This should security trim to allowable company sids, but left for now. 
	-- Sorting does not reveal the values only the order of them.
	SELECT T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM csr.audit_non_compliance anc
	  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
	  JOIN csr.supplier s ON s.region_sid = ia.region_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = anc.audit_non_compliance_id;
	  
	-- filter companies
	PageFilteredCompanySids(
		in_company_sid_list				=> v_id_list,
		in_start_row					=> 0,
		in_end_row						=> in_end_row,
		in_order_by 					=> in_order_by,
		in_order_dir					=> in_order_dir,
		out_company_sid_list			=> v_ordered_id_list
	);
	
	SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
			SELECT audit_non_compliance_id, ROWNUM rn
			FROM (
				SELECT anc.audit_non_compliance_id
				  FROM csr.audit_non_compliance anc
				  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
				  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
				  JOIN TABLE(in_id_list) inc ON anc.audit_non_compliance_id = inc.object_id
				  LEFT JOIN csr.supplier s ON s.region_sid = ia.region_sid
				  LEFT JOIN TABLE(v_ordered_id_list) x ON s.company_sid = x.sid_id
				  ORDER BY x.pos NULLS LAST
			 ) y
			 WHERE ROWNUM <= in_end_row
		)
	  WHERE rn > in_start_row;
END;

PROCEDURE SortActivityIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_ordered_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN	
	-- TODO: This should security trim to allowable company sids, but left for now. 
	-- Sorting does not reveal the values only the order of them.
	SELECT T_FILTERED_OBJECT_ROW(a.target_company_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM chain.activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = a.activity_id;
	  
	-- filter companies
	PageFilteredCompanySids(
		in_company_sid_list				=> v_id_list,
		in_start_row					=> 0,
		in_end_row						=> in_end_row,
		in_order_by 					=> in_order_by,
		in_order_dir					=> in_order_dir,
		out_company_sid_list			=> v_ordered_id_list
	);
	
	SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
			SELECT activity_id, ROWNUM rn
			FROM (
				SELECT a.activity_id
				  FROM chain.activity a
				  JOIN TABLE(in_id_list) inc ON a.activity_id = inc.object_id
				  LEFT JOIN TABLE(v_ordered_id_list) x ON a.target_company_sid = x.sid_id
				  ORDER BY x.pos NULLS LAST
			 ) y
			 WHERE ROWNUM <= in_end_row
		)
	  WHERE rn > in_start_row;
END;


PROCEDURE SortSurveyResponseIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_ordered_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_count							NUMBER;
BEGIN	
	-- TODO: This should security trim to allowable company sids, but left for now. 
	-- Sorting does not reveal the values only the order of them.
	
	SELECT T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT r.survey_response_id, ia.region_sid
		  FROM csr.quick_survey_response r
		  JOIN csr.internal_audit ia ON r.survey_response_id = ia.survey_response_id
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = r.survey_response_id
		 UNION
		SELECT r.survey_response_id, ia.region_sid
		  FROM csr.quick_survey_response r
		  JOIN csr.internal_audit_survey ias ON r.survey_response_id = ias.survey_response_id
		  JOIN csr.internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = r.survey_response_id
		 UNION
		SELECT r.survey_response_id, rsr.region_sid
		  FROM csr.quick_survey_response r
		  JOIN csr.region_survey_response rsr ON rsr.survey_response_id = r.survey_response_id
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = r.survey_response_id
	  ) reg
	  JOIN csr.supplier s ON s.region_sid = reg.region_sid;
	  
	-- filter companies
	PageFilteredCompanySids(
		in_company_sid_list				=> v_id_list,
		in_start_row					=> 0,
		in_end_row						=> in_end_row,
		in_order_by 					=> in_order_by,
		in_order_dir					=> in_order_dir,
		out_company_sid_list			=> v_ordered_id_list
	);
	
	SELECT security.T_ORDERED_SID_ROW(survey_response_id, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
			SELECT survey_response_id, ROWNUM rn
			  FROM (
				SELECT survey_response_id, x.pos
				  FROM (
					SELECT r.survey_response_id, ia.region_sid
					  FROM csr.quick_survey_response r
					  JOIN TABLE(in_id_list) inc ON r.survey_response_id = inc.object_id
					  JOIN csr.internal_audit ia ON r.survey_response_id = ia.survey_response_id
					  UNION
					SELECT r.survey_response_id, ia.region_sid
					  FROM csr.quick_survey_response r
					  JOIN TABLE(in_id_list) inc ON r.survey_response_id = inc.object_id
					  JOIN csr.internal_audit_survey ias ON r.survey_response_id = ias.survey_response_id
					  JOIN csr.internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
					  UNION
					SELECT r.survey_response_id, rsr.region_sid
					  FROM csr.quick_survey_response r
					  JOIN TABLE(in_id_list) inc ON r.survey_response_id = inc.object_id
					  JOIN csr.region_survey_response rsr ON rsr.survey_response_id = r.survey_response_id
					)  z
				  LEFT JOIN csr.supplier s ON s.region_sid = z.region_sid
				  LEFT JOIN TABLE(v_ordered_id_list) x ON s.company_sid = x.sid_id
				 ORDER BY x.pos NULLS LAST
			 ) y
			 WHERE ROWNUM <= in_end_row
		)
	  WHERE rn > in_start_row;
	  
END;


/********************************************/
/*		Filter field units					*/
/********************************************/

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate issue IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate issue IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */

PROCEDURE FilterCountry (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, c.country_code, co.name
		  FROM (SELECT DISTINCT country_code FROM company) c
		  JOIN postcode.country co ON c.country_code = co.country
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = c.country_code
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON c.country_code = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCountryRiskLevel (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	IF NOT capability_pkg.CheckCapability(chain_pkg.VIEW_COUNTRY_RISK_LEVELS) THEN
		out_ids:= T_FILTERED_OBJECT_TABLE();
		RETURN;
	END IF;

	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, rc.risk_level_id, rc.label
		  FROM risk_level rc
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = rc.risk_level_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN v$current_country_risk_level crl ON c.country_code = crl.country
	  JOIN filter_value fv ON crl.risk_level_id = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterName (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(c.name) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCompanySid (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON c.company_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPrimaryPurchaser (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(supplier_company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM supplier_relationship sr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON sr.supplier_company_sid = t.object_id
	  JOIN filter_value fv ON sr.purchaser_company_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND sr.is_primary = 1;
END;

PROCEDURE FilterCompanyTypeId (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, ct.company_type_id, ct.singular
		  FROM company_type ct
		  JOIN company_type_relationship ctr ON ct.app_sid = ctr.app_sid AND ct.company_type_id = ctr.secondary_company_type_id
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctr.primary_company_type_id = company_type_pkg.GetCompanyTypeId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = ct.company_type_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON c.company_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterReference (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS	
	v_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_reference_id		reference.reference_id%TYPE;
	v_reference_perms	T_REF_PERM_TABLE := helper_pkg.GetRefPermsByType;
BEGIN
	SELECT r.reference_id
	  INTO v_reference_id
	  FROM reference r
	  JOIN filter_field ff ON r.lookup_key = REPLACE(ff.name, 'ReferenceLabel.','')
	 WHERE ff.filter_id = in_filter_id 
	   AND ff.filter_field_id = in_filter_field_id;
	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT cr.company_sid
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
		  JOIN company_reference cr ON cr.company_sid = t.object_id
		  JOIN company c ON c.company_sid = cr.company_sid
		  JOIN TABLE(v_reference_perms) rp ON rp.reference_id = cr.reference_id  AND ((
					c.company_sid = v_company_sid AND rp.primary_company_type_id = c.company_type_id AND rp.secondary_company_type_id IS NULL
			   ) OR (
					c.company_sid != v_company_sid AND rp.secondary_company_type_id = c.company_type_id
			   ))
		  JOIN filter_value fv ON RTRIM(LTRIM(LOWER(cr.value))) LIKE '%'||RTRIM(LTRIM(LOWER(fv.str_value)))||'%'
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND rp.permission_set > 0
		   AND cr.reference_id = v_reference_id
	  );
END;

PROCEDURE FilterSector (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT company_sid
		  FROM company c
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
		  JOIN filter_value fv ON fv.filter_field_id = in_filter_field_id
		 WHERE (fv.null_filter = filter_pkg.NULL_FILTER_REQUIRE_NULL AND c.sector_id IS NULL)
			OR (fv.null_filter = filter_pkg.NULL_FILTER_ALL AND c.sector_id IN (
					SELECT sector_id
					  FROM sector
					 START WITH sector_id = fv.num_value
					CONNECT BY PRIOR sector_id = parent_sector_id)
			   )
		   );
END;

PROCEDURE FilterBusinessUnit (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(supplier_company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT supplier_company_sid
		  FROM business_unit_supplier bus
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON bus.supplier_company_sid = t.object_id
		 WHERE bus.business_unit_id IN (
			SELECT business_unit_id
			  FROM business_unit
			 START WITH business_unit_id IN (
				SELECT ff.num_value
				  FROM filter_value ff
				 WHERE ff.filter_field_id = in_filter_field_id
				)
			CONNECT BY PRIOR business_unit_id = parent_business_unit_id
			)
		);
END;

PROCEDURE FilterCity(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(c.city) = LOWER(fv.str_value) 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterState(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(c.state) = LOWER(fv.str_value) 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAddress( -- Address consists of address_1,address_2,address_3,address_4 - need to check them all
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
			 SELECT company_sid
			  FROM company c
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
			  JOIN filter_value fv ON LOWER(c.address_1) like '%'||LOWER(fv.str_value)||'%' 
			 WHERE fv.filter_field_id = in_filter_field_id
		UNION
			 SELECT company_sid
			  FROM company c
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
			  JOIN filter_value fv ON LOWER(c.address_2) like '%'||LOWER(fv.str_value)||'%' 
			 WHERE fv.filter_field_id = in_filter_field_id
		UNION
			SELECT company_sid
			  FROM company c
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
			  JOIN filter_value fv ON LOWER(c.address_3) like '%'||LOWER(fv.str_value)||'%' 
			 WHERE fv.filter_field_id = in_filter_field_id
		UNION
			SELECT company_sid
			  FROM company c
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
			  JOIN filter_value fv ON LOWER(c.address_4) like '%'||LOWER(fv.str_value)||'%' 
			 WHERE fv.filter_field_id = in_filter_field_id
		);
END;

PROCEDURE FilterPostcode(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(REPLACE(c.postcode, ' ', '')) LIKE '%'||LOWER(REPLACE(fv.str_value, ' ', ''))||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPhone (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(REPLACE(c.phone, ' ', '')) LIKE '%'||LOWER(REPLACE(fv.str_value, ' ', ''))||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterFax (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(REPLACE(c.fax, ' ', '')) LIKE '%'||LOWER(REPLACE(fv.str_value, ' ', ''))||'%'  
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterWebsite (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN filter_value fv ON LOWER(c.website) LIKE '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCreatedDtm (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(c.created_dtm), MAX(c.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM company c
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
		 WHERE c.created_dtm IS NOT NULL;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(c.company_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN tt_filter_date_range dr 
		ON (dr.null_filter = filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			c.created_dtm IS NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			c.created_dtm IS NOT NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_ALL AND 
			c.created_dtm IS NOT NULL AND
			c.created_dtm >= NVL(dr.start_dtm, c.created_dtm ) AND 
			(dr.end_dtm IS NULL OR c.created_dtm < dr.end_dtm));
END;

PROCEDURE FilterActivatedDtm (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(c.activated_dtm), MAX(c.activated_dtm)
		  INTO v_min_date, v_max_date
		  FROM company c
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
		 WHERE c.activated_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT T_FILTERED_OBJECT_ROW(c.company_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  JOIN tt_filter_date_range dr 
		ON (dr.null_filter = filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			c.activated_dtm IS NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			c.activated_dtm IS NOT NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_ALL AND 
			c.activated_dtm IS NOT NULL AND
			c.activated_dtm >= NVL(dr.start_dtm, c.activated_dtm ) AND 
			(dr.end_dtm IS NULL OR c.activated_dtm < dr.end_dtm));
END;

PROCEDURE FilterInvitationStatus (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, i.invitation_status_id, i.description
		  FROM invitation_status i
		 WHERE i.invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED, chain_pkg.CANCELLED, chain_pkg.ACCEPTED, chain_pkg.NOT_INVITED)
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = i.invitation_status_id
		 );
	END IF;

	-- Undoing the change made as part of FB29401. That change only considered the filter's use in one location
	-- and is generally misleading in all other situations. Generally an administrator will want to re-send
	-- invitations to all companies that haven't had an accepted invitation, not all companies that have at least
	-- one expired invitation (and maybe subsequent accepted invitations).
	SELECT T_FILTERED_OBJECT_ROW(company_sid, in_group_by_index, filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT c.company_sid, fv.filter_value_id
		  FROM company c
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON (c.company_sid = t.object_id)
		  JOIN v$company_invitation_status cis ON (c.company_sid = cis.company_sid)
		  JOIN filter_value fv ON (cis.invitation_status_id = fv.num_value)
		 WHERE fv.filter_field_id = in_filter_field_id
		);
END;

PROCEDURE FilterInvitationSentDtm (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
	v_company_sids		security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_primary_contacts	T_PRIMARY_CONTACT_TABLE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cuis.invitation_sent_dtm), MAX(cuis.invitation_sent_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$chain_user_invitation_status cuis
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cuis.company_sid = t.object_id
		 WHERE cuis.invitation_sent_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	SELECT security.T_ORDERED_SID_ROW(object_id, NULL)
	  BULK COLLECT INTO v_company_sids
	  FROM TABLE (in_ids);
	  
	v_primary_contacts := GetPrimaryContacts(v_company_sids);

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(c.company_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  LEFT JOIN TABLE(v_primary_contacts) pc ON pc.company_id = c.company_sid
	  LEFT JOIN v$chain_user_invitation_status cuis ON cuis.user_sid = pc.user_id AND cuis.company_sid = c.company_sid --get primary contact's most significant invitation data
	  JOIN tt_filter_date_range dr 
		ON (dr.null_filter = filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cuis.invitation_sent_dtm IS NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cuis.invitation_sent_dtm IS NOT NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_ALL AND 
			cuis.invitation_sent_dtm IS NOT NULL AND
			cuis.invitation_sent_dtm >= NVL(dr.start_dtm, cuis.invitation_sent_dtm ) AND 
			(dr.end_dtm IS NULL OR cuis.invitation_sent_dtm < dr.end_dtm));
END;

PROCEDURE FilterInvitationSentFrom (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
	v_company_sids		security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_primary_contacts	T_PRIMARY_CONTACT_TABLE;
BEGIN
	SELECT security.T_ORDERED_SID_ROW(object_id, NULL)
	  BULK COLLECT INTO v_company_sids
	  FROM TABLE (in_ids);
	  
	v_primary_contacts := GetPrimaryContacts(v_company_sids);
		 
	SELECT T_FILTERED_OBJECT_ROW(c.company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON c.company_sid = t.object_id
	  LEFT JOIN TABLE(v_primary_contacts) pc ON pc.company_id = c.company_sid
	  LEFT JOIN v$chain_user_invitation_status cuis ON cuis.user_sid = pc.user_id AND cuis.company_sid = c.company_sid --get primary contact's most significant invitation data
	  LEFT JOIN csr.csr_user fu ON fu.csr_user_sid = cuis.from_user_sid
	  JOIN filter_value fv ON LOWER(fu.full_name) LIKE '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterFollowers (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		INSERT INTO filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, sf.user_sid
		  FROM (
			SELECT DISTINCT user_sid
			  FROM supplier_follower sf
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON sf.supplier_company_sid = t.object_id
			 WHERE sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			  ) sf
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = sf.user_sid
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(sf.supplier_company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM supplier_follower sf
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON sf.supplier_company_sid = t.object_id
	  JOIN filter_value fv 
		ON fv.user_sid = sf.user_sid
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_ME AND sf.user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND sf.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE FilterSuppByScoreLastChangedOn(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_score_perm_sids			security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
	v_score_log_perm_sids		security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.VIEW_COMPANY_SCORE_LOG);
BEGIN
	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(ss.company_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM csr.v$supplier_score ss
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ss.company_sid = t.object_id
	  JOIN TABLE(v_score_perm_sids) sp ON ss.company_sid = sp.column_value
	  JOIN TABLE(v_score_log_perm_sids) slp ON ss.company_sid = slp.column_value
	  JOIN filter_field ff ON ff.name = 'ScoreLastChangedOn.' || ss.score_type_id
	  JOIN tt_filter_date_range dr 
		ON (dr.null_filter = filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			ss.score_last_changed IS NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			ss.score_last_changed IS NOT NULL)
		OR (dr.null_filter = filter_pkg.NULL_FILTER_ALL AND 
			ss.score_last_changed IS NOT NULL AND
			ss.score_last_changed >= NVL(dr.start_dtm, ss.score_last_changed ) AND 
			(dr.end_dtm IS NULL OR ss.score_last_changed < dr.end_dtm))
	 WHERE ff.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSuppByScoreLastChangedBy(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_score_perm_sids			security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
	v_score_log_perm_sids		security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.VIEW_COMPANY_SCORE_LOG);
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(ss.company_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM csr.v$supplier_score ss
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ss.company_sid = t.object_id
	  JOIN TABLE(v_score_perm_sids) sp ON ss.company_sid = sp.column_value
  	  JOIN TABLE(v_score_log_perm_sids) slp ON ss.company_sid = slp.column_value
	  JOIN v$filter_value fv ON ss.changed_by_user_sid = fv.num_value AND fv.name = 'ScoreLastChangedBy.'||ss.score_type_id
	  JOIN csr.score_type st ON st.score_type_id = ss.score_type_id
	 WHERE fv.filter_id = in_filter_id
	   AND fv.filter_field_id = in_filter_field_id
	   AND (ss.valid = 1 OR st.show_expired_scores = 1);
END;

PROCEDURE FilterFlowState (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description, pos)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, fs.flow_state_id, fs.label, fs.pos
		  FROM csr.flow_state fs
		 WHERE fs.flow_sid IN (
		   SELECT flow_sid
			 FROM company_type_relationship
			 )
		   AND fs.is_deleted = 0
		   AND NOT EXISTS ( -- exclude any we may have already
			 SELECT *
			   FROM filter_value fv
			  WHERE fv.filter_field_id = in_filter_field_id
				AND fv.num_value = fs.flow_state_id
			 );
	END IF;
	  
	SELECT T_FILTERED_OBJECT_ROW(company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company c
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
		ON c.company_sid = t.object_id
	  JOIN supplier_relationship sr
		ON sr.app_sid = c.app_sid
	   AND sr.supplier_company_sid = c.company_sid
	  JOIN csr.flow_item fi
		ON fi.flow_item_id = sr.flow_item_id
	  JOIN csr.flow_state fs
		ON fs.flow_state_id = fi.current_state_id
	  JOIN filter_value fv  
		ON fs.flow_state_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCanSeeAllCompanies (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT company_sid FROM v$company_relationship cr
		JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cr.company_sid = t.object_id
	);
END;

PROCEDURE FilterSupplierOf (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_relationships					T_COMPANY_REL_SIDS_TABLE := company_pkg.GetVisibleRelationships;
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, c.company_sid, c.name
			  FROM (
				SELECT s.company_sid, s.name
				  FROM company s
				  JOIN TABLE(v_relationships) r ON s.company_sid = r.primary_company_sid
				  JOIN company_type_relationship ctr ON s.company_type_id = ctr.primary_company_type_id  -- limit to company types that are purchasers
				 WHERE ctr.hidden = 0
				 GROUP BY s.company_sid, s.name
			   ) c
			 WHERE NOT EXISTS ( -- exclude any we may have already
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = c.company_sid
			 );	
	END IF;		
		
	SELECT T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN (
			SELECT CONNECT_BY_ROOT secondary_company_sid secondary_company_sid, primary_company_sid
			  FROM TABLE(v_relationships)
			 START WITH secondary_company_sid IN (SELECT object_id FROM TABLE(in_ids))
			CONNECT BY PRIOR primary_company_sid = secondary_company_sid 
		) r ON t.object_id = r.secondary_company_sid
	  JOIN filter_value fv ON r.primary_company_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_comparator					IN	chain.filter_field.comparator%TYPE, 
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_result_ids					T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	IF in_comparator = chain.filter_pkg.COMPARATOR_INTERSECT THEN
		v_result_ids := in_ids;

		IF in_group_by_index IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot group by intersected filters');
		END IF;

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM filter_value fv
			  JOIN saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_result_ids,
				out_id_list						=> v_result_ids
			);
		END LOOP;
		
		out_ids := v_result_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM filter_value fv
			  JOIN saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> in_ids,
				out_id_list						=> v_result_ids
			);

			SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, r.filter_value_id)
			  BULK COLLECT INTO v_temp_ids
			  FROM TABLE(v_result_ids) t;

			out_ids := out_ids MULTISET UNION v_temp_ids;
		END LOOP;
	END IF;
END;

PROCEDURE FilterAudits (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;	
	v_audit_ids						T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- get audits sids from company sids
		SELECT T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO v_audit_ids
		  FROM csr.supplier s
		  JOIN csr.internal_audit ia ON s.region_sid = ia.region_sid
		  JOIN TABLE(in_ids) t ON s.company_sid = t.object_id;
		  
		-- filter audits
		csr.audit_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_audit_ids,
			out_id_list						=> v_audit_ids
		);
		
		-- convert company sids from audits sids
		SELECT T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM csr.supplier s
		  JOIN csr.internal_audit ia ON s.region_sid = ia.region_sid
		  JOIN TABLE(v_audit_ids) t ON ia.internal_audit_sid = t.object_id;
	END IF;
END;

PROCEDURE FilterBusinessRelationships (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;	
	v_business_relationship_ids		T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(business_relationship_id, NULL, NULL)
		  BULK COLLECT INTO v_business_relationship_ids
		  FROM (
				SELECT DISTINCT brc.business_relationship_id
				  FROM business_relationship_company brc
				  JOIN TABLE(in_ids) t ON brc.company_sid = t.object_id
		  );
		  
		business_rel_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_business_relationship_ids,
			out_id_list						=> v_business_relationship_ids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
				SELECT DISTINCT brc.company_sid
				  FROM business_relationship_company brc
				  JOIN TABLE(in_ids) t ON brc.company_sid = t.object_id
				  JOIN TABLE(v_business_relationship_ids) ids ON brc.business_relationship_id = ids.object_id
		  );
	END IF;
END;

PROCEDURE FilterSuppliersBySupRelScore(
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_score_perm_sids	security.T_SID_TABLE DEFAULT chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description, colour)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, st.description, st.bar_colour
		  FROM csr.score_threshold st
		  JOIN filter_field ff ON ff.name = 'ScoreThreshold.'||st.score_type_id
		 WHERE ff.filter_field_id = in_filter_field_id
		   AND NOT EXISTS ( -- exclude any we may have already
				SELECT 1
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = st.score_threshold_id
		 );
	END IF;
	
	filter_pkg.SetThresholdColours(in_filter_field_id);

	filter_pkg.SortScoreThresholdValues(in_filter_field_id);

	SELECT T_FILTERED_OBJECT_ROW(supplier_company_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$current_sup_rel_score srs
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON srs.supplier_company_sid = t.object_id AND srs.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	  JOIN TABLE(v_score_perm_sids) cts ON srs.supplier_company_sid = cts.column_value
	  JOIN v$filter_value fv ON srs.score_threshold_id = fv.num_value AND fv.name = 'ScoreThreshold.'||srs.score_type_id
	  JOIN csr.score_type st ON st.score_type_id = srs.score_type_id
	 WHERE fv.filter_id = in_filter_id
	   AND fv.filter_field_id = in_filter_field_id
	   AND (srs.valid = 1 OR st.show_expired_scores = 1);
END;

PROCEDURE FilterCertifications (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_cert_type_id					IN  VARCHAR2,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_certification_ids				T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(certification_id, NULL, NULL)
		  BULK COLLECT INTO v_certification_ids
		  FROM (
			SELECT DISTINCT sc.certification_id
			  FROM v$supplier_certification sc
			  JOIN TABLE(in_ids) t ON sc.company_sid = t.object_id
		  );
	
		-- filter certications
		certification_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_cert_type_id					=> TO_NUMBER(in_cert_type_id),
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_certification_ids,
			in_id_list_populated			=> 1,
			out_id_list						=> v_certification_ids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT sc.company_sid
			  FROM v$supplier_certification sc
			  JOIN TABLE(in_ids) t ON sc.company_sid = t.object_id
			  JOIN TABLE(v_certification_ids) ids ON sc.certification_id = ids.object_id
		  );
	END IF;
END;

PROCEDURE FilterProducts(
	in_filter_id					IN filter.filter_id%TYPE,
	in_filter_field_id				IN NUMBER,
	in_show_all						IN NUMBER,
	in_ids							IN T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_product_ids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(cp.product_id, NULL, NULL)
		  BULK COLLECT INTO v_product_ids
		  FROM company_product cp
		  JOIN TABLE(in_ids) t ON t.object_id = cp.company_sid;
	
		product_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_product_ids,
			out_id_list						=> v_product_ids
		);
	
		SELECT T_FILTERED_OBJECT_ROW(cp.company_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM company_product cp
		  JOIN TABLE(in_ids) t ON t.object_id = cp.company_sid
		  JOIN TABLE(v_product_ids) p ON cp.product_id = p.object_id;
	END IF;
END;


PROCEDURE FilterRelationshipStatus (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, o.est_rel_only, o.description
		  FROM (
			SELECT 2 est_rel_only, chain_pkg.NO_RELATIONSHIP_DESC description FROM dual
			UNION ALL SELECT 0, chain_pkg.ACTIVE_RELATIONSHIP_DESC FROM dual
			UNION ALL SELECT 1, chain_pkg.PENDING_RELATIONSHIP_DESC FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.est_rel_only
		 );
		
	END IF;
	
	SELECT T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM TABLE(in_ids) t
	  LEFT JOIN supplier_relationship sr
		ON sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   AND sr.supplier_company_sid = t.object_id
	   AND sr.deleted = 0
	  JOIN filter_value fv ON 
	  ((fv.num_value = 1 AND sr.purchaser_company_sid IS NOT NULL AND sr.active = 0) 
		OR (fv.num_value = 0 AND sr.purchaser_company_sid IS NOT NULL AND sr.active = 1)
		OR (fv.num_value = 2 AND sr.purchaser_company_sid IS NULL))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;


PROCEDURE FilterActive (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, f.following, f.description
		  FROM (
			SELECT 1 following, 'Active' description FROM dual
			UNION ALL SELECT 0, 'Inactive' FROM dual
		  ) f
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = f.following
		 );		
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN company c ON c.company_sid = t.object_id
	  JOIN filter_value fv ON fv.num_value = c.active 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterInd (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_ids							T_FILTERED_OBJECT_TABLE;
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(s.region_sid, t.group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_ids
	  FROM TABLE(in_ids) t
	  JOIN csr.supplier s ON s.company_sid = t.object_id;

	filter_pkg.FilterInd(
		in_filter_id			=>	in_filter_id,
		in_filter_field_id		=>	in_filter_field_id,
		in_filter_field_name	=>	in_filter_field_name,
		in_show_all				=>	in_show_all,
		in_ids					=>	v_ids,
		out_ids					=>	v_ids
	);
	
	SELECT T_FILTERED_OBJECT_ROW(s.company_sid, t.group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM TABLE(v_ids) t
	  JOIN csr.supplier s ON s.region_sid = t.object_id;
END;

/********************************************/
/*		Other stuff					*/
/********************************************/


-- used as a 'filter' as well as from other sps here
PROCEDURE Search (
	in_search_term		IN  VARCHAR2,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_reference_perms				T_REF_PERM_TABLE := helper_pkg.GetRefPermsByType;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.Search');

	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT c.company_sid
		  FROM company c
		  JOIN TABLE(in_ids) t ON c.company_sid = t.object_id
		  LEFT JOIN alt_company_name acn ON c.company_sid = acn.company_sid
		  LEFT JOIN company_reference cr ON c.company_sid = cr.company_sid
		  LEFT JOIN TABLE(v_reference_perms) rp ON cr.reference_id = rp.reference_id AND ((
						c.company_sid = v_company_sid AND rp.primary_company_type_id = c.company_type_id AND rp.secondary_company_type_id IS NULL
					) OR (
						c.company_sid != v_company_sid AND rp.secondary_company_type_id = c.company_type_id
					))
		 WHERE LOWER(c.name) LIKE '%'||LOWER(TRIM(in_search_term))||'%'
		    OR CAST(c.company_sid AS VARCHAR2(20)) = TRIM(in_search_term)
			OR LOWER(acn.name) LIKE '%'||LOWER(TRIM(in_search_term))||'%'
		    OR (rp.permission_set > 0 AND LOWER(cr.value) LIKE '%'||LOWER(TRIM(in_search_term))||'%')
		);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

-- used as a 'filter' as well as from other sps here
PROCEDURE Search (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_phrase			VARCHAR2(4000);
BEGIN
	SELECT LISTAGG(ff.str_value, ' ') WITHIN GROUP (ORDER BY filter_value_id)
	  INTO v_phrase
	  FROM filter_value ff
	 WHERE ff.filter_field_id = in_filter_field_id;
	
	Search(v_phrase, in_ids, out_ids);
END;










-- Called from c# code
PROCEDURE CreateCompanySearchFilter (
	in_search_phrase			IN	filter_value.str_value%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_filter_id					filter.filter_id%TYPE;
	v_field_id					filter_field.filter_field_id%TYPE;
	v_value_id					filter_value.filter_value_id%TYPE;
BEGIN
	-- Shortcut to bypass cardmanager for starting a free text company search
	filter_pkg.CreateCompoundFilter(security_pkg.getAct, 23 /*Basic company filter*/, out_compound_filter_id);
	filter_pkg.AddCardFilter(out_compound_filter_id, 'Credit360.Chain.Cards.Filters.CompanyCore', 23, v_filter_id);
	filter_pkg.AddFilterField(v_filter_id, 'Search', 'search', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_field_id);
	filter_pkg.AddStringValue(v_field_id, in_search_phrase, NULL, 0, v_value_id);
END;

-- Called from c# code
PROCEDURE CreateQuestionnaireFilter (
	in_questionnaire_type_id	IN	filter_value.num_value%TYPE,
	in_status_id				IN	filter_value.num_value%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_filter_id					filter.filter_id%TYPE;
	v_field_id					filter_field.filter_field_id%TYPE;
	v_value_id					filter_value.filter_value_id%TYPE;
BEGIN
	filter_pkg.CreateCompoundFilter(security_pkg.getAct, 23 /*Basic company filter*/, out_compound_filter_id);
	filter_pkg.AddCardFilter(out_compound_filter_id, 'Credit360.Chain.Cards.Filters.SurveyQuestionnaire', 23, v_filter_id);	
	filter_pkg.AddFilterField(v_filter_id, 'QuestionnaireStatus.'||in_questionnaire_type_id, 'contains', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_field_id);
	filter_pkg.AddNumberValue(
		in_filter_field_id		=> v_field_id,
		in_value				=> in_status_id,
		in_description			=> NULL,
		out_filter_value_id		=> v_value_id
	);
END;


/**********************************************************************************/
/**********************   Filtering   *********************************************/
/**********************************************************************************/


-- Called as a helper from quick_survey_pkg
PROCEDURE FilterResponseIds (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_sids				IN  security.T_SID_TABLE,
	out_sids			OUT security.T_SID_TABLE
)
AS
	in_company_sids			T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	out_company_sids		T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
BEGIN

	--converts input response IDs to corresponding company SIDs
	SELECT T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
	  BULK COLLECT INTO in_company_sids
	  FROM (
		SELECT DISTINCT ssr.supplier_sid AS company_sid
		  FROM TABLE(in_sids) i
		  JOIN csr.supplier_survey_response ssr ON ssr.survey_response_id = i.column_value
	  );

	--apply company filter
	FilterCompanySids(in_filter_id, 0, NULL, in_company_sids, out_company_sids);

	--converts back (remaining company SIDs -> response IDs)
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT i.column_value AS survey_response_id
		  FROM TABLE(in_sids) i
		  JOIN csr.supplier_survey_response ssr ON ssr.survey_response_id = i.column_value
		  JOIN TABLE(out_company_sids) j ON j.object_id = ssr.supplier_sid
	  );
END;

-- called from c# code
PROCEDURE GetCompanyRegions (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_company_sid_list				T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
BEGIN
	GetFilteredIds (
		in_compound_filter_id	=> in_compound_filter_id, 
		in_id_list				=> NULL,
		out_id_list				=> v_company_sid_list
	);
	
	OPEN out_cur FOR
		SELECT c.company_sid, s.region_sid, c.name, cn.name country_name,
			   c.country_is_hidden
		  FROM company c
		  JOIN TABLE(v_company_sid_list) t ON c.company_sid = t.object_id
		  JOIN csr.supplier s ON c.app_sid = s.app_sid AND c.company_sid = s.company_sid
		  JOIN postcode.country cn ON c.country_code = cn.country
		 ORDER BY LOWER(c.name);
END;

-- called from c# code
PROCEDURE FilterCompaniesGraph(
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_search_term  				IN  VARCHAR2,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_bus_rel_type_id				IN  security_pkg.T_SID_ID,
	out_company_sids_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comps_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_relationships					T_COMPANY_REL_SIDS_TABLE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
	v_results						T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.company_filter_pkg.FilterCompaniesGraph', in_compound_filter_id);
	
	IF in_company_sid IS NOT NULL THEN
		v_company_sid := in_company_sid;
	END IF;
	
	v_relationships := company_pkg.GetConnectedRelationships(v_company_sid);

	SELECT T_FILTERED_OBJECT_ROW(company_sid, null, null)
	  BULK COLLECT INTO v_company_sids
	  FROM (
		SELECT v_company_sid company_sid
		  FROM dual
		 UNION
		SELECT primary_company_sid company_sid
		  FROM TABLE(v_relationships)
		 UNION		 
		SELECT secondary_company_sid company_sid
		  FROM TABLE(v_relationships)
	  )
	GROUP BY company_sid;

	GetFilteredIds(
		in_search => in_search_term,
		in_compound_filter_id => in_compound_filter_id,
		in_id_list => v_company_sids,
		out_id_list => v_results
	);
	
	OPEN out_company_sids_cur FOR
		SELECT r.object_id company_sid
		  FROM TABLE(v_results) r;
	
	business_relationship_pkg.GetGraphCompanies(in_bus_rel_type_id, v_company_sids, out_bus_rel_comps_cur);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetTagGroups (
	out_tag_groups					OUT	SYS_REFCURSOR,
	out_tag_group_members			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Same permissions as csr.tag_pkg.GetTagGroups
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, security_pkg.GetApp, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_tag_groups FOR
		SELECT tg.tag_group_id, tg.name, tg.applies_to_suppliers, tg.applies_to_chain_product_types
		  FROM csr.v$tag_group tg
		 WHERE (tg.applies_to_suppliers = 1 OR tg.applies_to_chain_product_types = 1)
		 ORDER BY tg.name;
	
	OPEN out_tag_group_members FOR
		SELECT t.tag_id id, t.tag label, tgm.tag_group_id
		  FROM csr.tag_group tg
		  JOIN csr.tag_group_member tgm ON tg.app_sid = tgm.app_sid AND tg.tag_group_id = tgm.tag_group_id
		  JOIN csr.v$tag t ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		 WHERE (tg.applies_to_suppliers = 1 OR tg.applies_to_chain_product_types = 1)
		 ORDER BY tgm.pos;
END;

PROCEDURE GetDirectSuppliers(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_supplier_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_page				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
BEGIN

	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	SELECT security.T_ORDERED_SID_ROW(supplier_company_sid, rownum)
	  BULK COLLECT INTO v_company_sid_page
	  FROM (
		SELECT DISTINCT(sr.supplier_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid
		  JOIN TABLE (v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.purchaser_company_sid = in_company_sid
		   AND sr.active = 1 AND sr.deleted = 0
	);

	CollectSearchResults(v_company_sid_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
END;


PROCEDURE GetSuppliersAsPrimaryPurchaser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_supplier_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_page				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
BEGIN

	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	SELECT security.T_ORDERED_SID_ROW(supplier_company_sid, rownum)
	  BULK COLLECT INTO v_company_sid_page
	  FROM (
		SELECT DISTINCT(sr.supplier_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid
		  JOIN TABLE(v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.purchaser_company_sid = in_company_sid
		   AND sr.is_primary = 1
		   AND sr.active = 1 AND sr.deleted = 0
	);

	CollectSearchResults(v_company_sid_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
END;


PROCEDURE GetSubsidiarySuppliers(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_supplier_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sid_page				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
	v_sub_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);
BEGIN

	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	SELECT security.T_ORDERED_SID_ROW(supplier_company_sid, rownum)
	  BULK COLLECT INTO v_company_sid_page
	  FROM (
		SELECT DISTINCT(sr.supplier_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid AND sc.parent_sid = pc.company_sid
		  JOIN TABLE (v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		  JOIN TABLE (v_sub_permissions) sp on sp.secondary_company_type_id = pc.company_type_id and sp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.purchaser_company_sid = in_company_sid
		   AND sr.active = 1 AND sr.deleted = 0
	);

	CollectSearchResults(v_company_sid_page, out_cur, out_scores_cur, out_tags_cur, out_refs_cur, out_bus_cur, out_followers_cur, out_certifications_cur, out_prim_purchsr_cur, out_inds_cur);
END;

PROCEDURE GetPrchasrWithDirectSuppliers(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR)
AS
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_company_sids);
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
BEGIN
	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	OPEN out_cur FOR
		SELECT DISTINCT(sr.purchaser_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN TABLE (v_company_sids) c ON sr.purchaser_company_sid = c.column_value
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid
		  JOIN TABLE (v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.deleted = 0;
END;

PROCEDURE GetPrimaryPurchasers(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR)
AS
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_company_sids);
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
BEGIN
	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	OPEN out_cur FOR
		SELECT DISTINCT(sr.purchaser_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN TABLE (v_company_sids) c ON sr.purchaser_company_sid = c.column_value
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid
		  JOIN TABLE (v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.deleted = 0
		   AND sr.is_primary = 1;
END;


PROCEDURE GetPrchasrWithSubsidiaries(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR)
AS
	v_company_sid_list				T_FILTERED_OBJECT_TABLE;
	v_company_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_company_sids);
	v_related_company_type_tab		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_related_company_type_ids);
	v_rel_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_RELATIONSHIPS);
	v_sub_permissions				T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF);
BEGIN
	GetFilteredIds(
		in_parent_id			=> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
		in_compound_filter_id	=> 0,
		out_id_list				=> v_company_sid_list
	);

	OPEN out_cur FOR
		SELECT DISTINCT(sr.purchaser_company_sid)
		  FROM supplier_relationship sr
		  JOIN TABLE (v_company_sid_list) t ON sr.supplier_company_sid = t.object_id
		  JOIN company pc on pc.company_sid = sr.purchaser_company_sid
		  JOIN company sc on sc.company_sid = sr.supplier_company_sid
		  JOIN TABLE (v_company_sids) c ON sr.purchaser_company_sid = c.column_value AND c.column_value = sc.parent_sid
		  JOIN TABLE (v_related_company_type_tab) rct on rct.column_value = sc.company_type_id
		  JOIN TABLE (v_rel_permissions) rp on rp.secondary_company_type_id = pc.company_type_id and rp.tertiary_company_type_id = sc.company_type_id
		  JOIN TABLE (v_sub_permissions) sp on sp.secondary_company_type_id = pc.company_type_id and sp.tertiary_company_type_id = sc.company_type_id
		 WHERE sr.deleted = 0;
END;

END company_filter_pkg;
/
