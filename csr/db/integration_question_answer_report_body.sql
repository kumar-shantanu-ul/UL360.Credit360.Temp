CREATE OR REPLACE PACKAGE BODY CSR.integration_question_answer_report_pkg
IS

-- private field filter units

PROCEDURE INTERNAL_OrderFilterByNumValue(
	in_filter_field_id				IN  NUMBER
)
AS
BEGIN
	UPDATE chain.filter_value
	   SET pos = num_value
	 WHERE filter_field_id = in_filter_field_id;
END;

PROCEDURE INTERNAL_OrderFilterByDesc(
	in_filter_field_id				IN  NUMBER
)
AS
BEGIN
	MERGE INTO chain.filter_value fv
	USING (
		SELECT ROWNUM rn, x.* 
		  FROM (
		  	SELECT filter_value_id, description
		  	  FROM chain.filter_value
		  	 WHERE filter_field_id = in_filter_field_id
		  	 ORDER BY LOWER(description)
		  ) x
	) ord
	ON (fv.filter_value_id = ord.filter_value_id)
	WHEN MATCHED THEN 
		UPDATE SET fv.pos = ord.rn;
END;

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */

PROCEDURE FilterParentRef (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, src.parent_ref, src.parent_ref
		  FROM (
			  SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/DISTINCT parent_ref
				FROM integration_question_answer src
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON src.id = t.object_id
		) src
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND LOWER(fv.str_value) = LOWER(src.parent_ref)
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	BULK COLLECT INTO out_ids
	FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	JOIN integration_question_answer iqa ON iqa.id = t.object_id
	JOIN chain.filter_value fv ON LOWER(iqa.parent_ref) = LOWER(fv.str_value) 
	WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterQuestionRef (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, src.question_ref, src.question_ref
		  FROM (
			  SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/DISTINCT question_ref
				FROM integration_question_answer src
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON src.id = t.object_id
		) src
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND LOWER(fv.str_value) = LOWER(src.question_ref)
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	BULK COLLECT INTO out_ids
	FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	JOIN integration_question_answer iqa ON iqa.id = t.object_id
	JOIN chain.filter_value fv ON LOWER(iqa.question_ref) = LOWER(fv.str_value) 
	WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterQuestionnaireName (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN csr.integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.questionnaire_name) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, src.internal_audit_sid, src.internal_audit_sid
		  FROM (
			  SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/DISTINCT ia.internal_audit_sid
				FROM integration_question_answer iqa
				JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iqa.id = t.object_id
		) src
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = src.internal_audit_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
	  JOIN chain.filter_value fv 
	    ON fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(ia.internal_audit_sid, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterSectionName (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.section_name) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSectionCode (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.section_code) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSubSectionName (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.subsection_name) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSubSectionCode (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.subsection_code) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterScore (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, src.section_score, src.section_score
		  FROM (
			  SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/DISTINCT section_score
				FROM integration_question_answer src
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON src.id = t.object_id
		) src
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = src.section_score
		 );
	END IF;
	
	SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/chain.T_FILTERED_OBJECT_ROW(src.id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM integration_question_answer src
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t 
	    ON src.id = t.object_id
	  JOIN chain.filter_value fv 
	    ON fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(src.section_score, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterRating (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, src.rating, src.rating
		  FROM (
			  SELECT /*+ USE_NL(t src) INDEX(src UK_INTEGRATION_QUESTION_ANSWER_ID)*/DISTINCT rating
				FROM integration_question_answer src
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON src.id = t.object_id
		) src
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND LOWER(fv.str_value) = LOWER(src.rating)
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN chain.filter_value fv ON LOWER(iqa.rating) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLastUpdated (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(iqa.last_updated), MAX(iqa.last_updated)
		  INTO v_min_date, v_max_date
		  FROM integration_question_answer iqa
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iqa.id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(iqa.id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM integration_question_answer iqa
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iqa.id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON iqa.last_updated >= NVL(dr.start_dtm, iqa.last_updated)
	   AND (dr.end_dtm IS NULL OR iqa.last_updated < dr.end_dtm)
	 WHERE iqa.last_updated IS NOT NULL;
END;

PROCEDURE FilterSupplierName (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN csr.integration_question_answer iqa ON iqa.id = t.object_id
	  JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
	  LEFT JOIN csr.supplier sup on sup.region_sid = ia.region_sid
	  LEFT JOIN chain.company comp on comp.company_sid = sup.company_sid
	  JOIN chain.filter_value fv ON LOWER(comp.name) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSupplier (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_company_ids					chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- get company sids from iqa parent ref
		SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_ids
		  FROM csr.integration_question_answer iqa
		  JOIN csr.internal_audit ia ON iqa.parent_ref = ia.external_audit_ref
		  JOIN csr.supplier s ON s.region_sid = ia.region_sid
		  JOIN TABLE(in_ids) t ON iqa.id = t.object_id;
		 
		 -- filter companies
		chain.company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_ids,
			out_id_list						=> v_company_ids
		);
				
		-- convert iqa ids from company sids
		SELECT chain.T_FILTERED_OBJECT_ROW(iqa.id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM csr.integration_question_answer iqa
		  JOIN csr.internal_audit ia ON iqa.parent_ref = ia.external_audit_ref
		  JOIN csr.supplier s ON s.region_sid = ia.region_sid
		  JOIN TABLE(v_company_ids) t ON s.company_sid = t.object_id
		  JOIN TABLE(in_ids) iiqa ON iqa.id = iiqa.object_id;
	END IF;
END;

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
) AS
BEGIN
	IF LOWER(in_name) = 'parentref' THEN
		FilterParentRef(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'questionref' THEN
		FilterQuestionRef(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'questionnairename' THEN
		FilterQuestionnaireName(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'internalauditsid' THEN
		FilterAuditId(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'sectionname' THEN
		FilterSectionName(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'sectioncode' THEN
		FilterSectionCode(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'sectionscore' THEN
		FilterScore(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'subsectionname' THEN
		FilterSubSectionName(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'subsectioncode' THEN
		FilterSubSectionCode(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'rating' THEN
		FilterRating(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'lastupdated' THEN
		FilterLastUpdated(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'suppliername' THEN
		FilterSupplierName(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'companyfilter' THEN
		FilterSupplier(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE FilterIQAIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.FilterIQAIds', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, comparator, column_sid
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.FilterIQAIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		RunSingleUnit(r.name, r.column_sid, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);

		chain.filter_pkg.EndDebugLog(v_inner_log_id);

		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN
			chain.filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;

		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_ids := v_result_ids;
		ELSE
			out_ids := out_ids MULTISET UNION v_result_ids;
		END IF;
	END LOOP;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CopyFilter (
	in_from_filter_id				IN	chain.filter.filter_id%TYPE,
	in_to_filter_id					IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	chain.filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	chain.filter_pkg.RunCompoundFilter('FilterIQAIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id,
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM integration_question_answer iqa
	  JOIN TABLE(in_id_list) l ON iqa.id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

FUNCTION INTERNAL_IsInRequiredGroup RETURN BOOLEAN
AS
BEGIN
	RETURN (user_pkg.IsUserInGroup(
		security_pkg.GetAct,
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp(), 'Groups/Audit Administrators')) = 1);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_parent_ref					VARCHAR2(255);
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_ainswer_report_pkg.GetInitialIds');
	
	IF NOT (
		csr_user_pkg.IsSuperAdmin = 1 OR 
		INTERNAL_IsInRequiredGroup = TRUE
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on IQA');
	END IF;

	-- Refactor if this ever gets used for something other than audits. 
	SELECT MIN(external_audit_ref)
	  INTO v_parent_ref
	  FROM csr.internal_audit
	 WHERE internal_audit_sid = in_parent_id;
	
	-- Start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(r.id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT iqa.parent_ref, iqa.questionnaire_name, iqa.question_ref, ia.internal_audit_sid,
			   iqa.section_name, iqa.section_code, iqa.section_score,
			   iqa.subsection_name, iqa.subsection_code, iqa.question_text, iqa.rating, iqa.conclusion, iqa.answer,
			   iqa.data_points, iqa.last_updated, iqa.id, comp.name supplier_name
		  FROM csr.integration_question_answer iqa
		  JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
		  LEFT JOIN csr.supplier sup on sup.region_sid = ia.region_sid
		  LEFT JOIN chain.company comp on comp.company_sid = sup.company_sid
		 WHERE (in_parent_id IS NULL OR iqa.internal_audit_sid = in_parent_id OR parent_ref = v_parent_ref)
		 ORDER BY id DESC
	  ) r
	 WHERE (in_search IS NULL 
		OR LOWER(r.parent_ref) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.question_ref) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.questionnaire_name) LIKE '%'||LOWER(in_search)||'%'
		OR TO_CHAR(r.internal_audit_sid) = in_search
		OR LOWER(r.section_name) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.section_code) LIKE '%'||LOWER(in_search)||'%'
		OR TO_CHAR(r.section_score) = in_search
		OR LOWER(r.subsection_name) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.subsection_code) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.question_text) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.rating) LIKE '%'||LOWER(in_search)||'%'
		OR DBMS_LOB.INSTR( r.conclusion, in_search ) > 0
		OR LOWER(r.answer) LIKE '%'||LOWER(in_search)||'%'
		OR DBMS_LOB.INSTR( r.data_points, in_search ) > 0
		OR TO_CHAR(r.id) = in_search
		OR LOWER(r.supplier_name) LIKE '%'||LOWER(in_search)||'%'
		)
	;
	
	out_id_list := v_id_list;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_is_priority_filtered			NUMBER(1);
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.GetFilteredIds');
	
	IF in_id_list_populated = 0 THEN
		-- Step 1, get initial set of ids
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_parent_id, in_start_dtm, in_end_dtm, in_region_col_type, in_date_col_type, in_id_list, v_id_list);
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM chain.tt_filter_id;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
	

	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_id_list,
				out_id_list						=> v_id_list
			);
		END LOOP;
	END IF;

	IF NVL(in_compound_filter_id, 0) > 0 THEN
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;

	out_id_list := v_id_list;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;
	
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);		
		
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
 			v_top_n_values := chain.filter_pkg.FindTopN(v_field_compound_filter_id, NVL(in_aggregation_type, 1), out_id_list, in_breadcrumb);  
			
			-- update any rows that aren't in top N to -group_by_index, indicating they're "other"
			SELECT chain.T_FILTERED_OBJECT_ROW (l.object_id, l.group_by_index, CASE WHEN t.pos IS NOT NULL THEN l.group_by_value ELSE -ff.filter_field_id END)
			  BULK COLLECT INTO v_temp
			  FROM TABLE(out_id_list) l
			  JOIN chain.v$filter_field ff ON l.group_by_index = ff.group_by_index AND ff.compound_filter_id = v_field_compound_filter_id
			  LEFT JOIN TABLE(v_top_n_values) t ON l.group_by_value = t.pos;
		ELSE
			v_temp := out_id_list;
		END IF;
		
		-- apply breadcrumb
		chain.filter_pkg.ApplyBreadcrumb(v_temp, in_breadcrumb, out_id_list);
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CollectSearchResults (
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_cur 						OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT iqa.parent_ref, iqa.questionnaire_name, iqa.question_ref, ia.internal_audit_sid,
			   iqa.section_name, iqa.section_code, iqa.section_score,
			   iqa.subsection_name, iqa.subsection_code, iqa.question_text, iqa.rating, iqa.conclusion, iqa.answer,
			   iqa.data_points, iqa.last_updated, iqa.id, comp.name supplier_name
		  FROM csr.integration_question_answer iqa
		  JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
		  LEFT JOIN csr.supplier sup on sup.region_sid = ia.region_sid
		  LEFT JOIN chain.company comp on comp.company_sid = sup.company_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = iqa.id
		ORDER BY id DESC;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredIds (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.PageFilteredIds');	

	IF in_order_by = 'id' AND in_order_dir='DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.object_id, ROWNUM rn
				  FROM (
					SELECT object_id
					  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list))
					 ORDER BY object_id DESC
					) x 
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
		
		SELECT security.T_ORDERED_SID_ROW(id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.id, ROWNUM rn
				  FROM (
					SELECT iqa.id, comp.name supplier_name
					  FROM integration_question_answer iqa --join to just the tables needed for sorting
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = iqa.id
					  JOIN csr.internal_audit ia on ia.external_audit_ref = iqa.parent_ref
					  LEFT JOIN csr.supplier sup on sup.region_sid = ia.region_sid
					  LEFT JOIN chain.company comp on comp.company_sid = sup.company_sid
					 ORDER BY
							-- To avoid dynamic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'id' THEN TO_CHAR(id, '0000000000')
									WHEN 'parentRef' THEN LOWER(parent_ref)
									WHEN 'questionRef' THEN LOWER(question_ref)
									WHEN 'questionnaireName' THEN LOWER(question_ref)
									WHEN 'internalAuditSid' THEN TO_CHAR(ia.internal_audit_sid, '0000000000')
									WHEN 'sectionName' THEN LOWER(section_name)
									WHEN 'sectionCode' THEN LOWER(section_code)
									WHEN 'sectionScore' THEN TO_CHAR(section_score, '0000000000')
									WHEN 'subSectionName' THEN LOWER(subsection_name)
									WHEN 'subSectionCode' THEN LOWER(subsection_code)
									WHEN 'questionText' THEN LOWER(question_text)
									WHEN 'rating' THEN LOWER(rating)
									WHEN 'conclusion' THEN LOWER(DBMS_LOB.SUBSTR(conclusion, 1000, 1))
									WHEN 'answer' THEN LOWER(DBMS_LOB.SUBSTR(answer, 1000, 1))
									WHEN 'dataPoints' THEN LOWER(DBMS_LOB.SUBSTR(data_points, 1000, 1))
									WHEN 'lastUpdatedFormatted' THEN TO_CHAR(last_updated, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'supplierName' THEN LOWER(supplier_name)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'id' THEN TO_CHAR(id, '0000000000')
									WHEN 'parentRef' THEN LOWER(parent_ref)
									WHEN 'questionRef' THEN LOWER(question_ref)
									WHEN 'questionnaireName' THEN LOWER(question_ref)
									WHEN 'internalAuditSid' THEN TO_CHAR(ia.internal_audit_sid, '0000000000')
									WHEN 'sectionName' THEN LOWER(section_name)
									WHEN 'sectionCode' THEN LOWER(section_code)
									WHEN 'sectionScore' THEN TO_CHAR(section_score, '0000000000')
									WHEN 'subSectionName' THEN LOWER(subsection_name)
									WHEN 'subSectionCode' THEN LOWER(subsection_code)
									WHEN 'questionText' THEN LOWER(question_text)
									WHEN 'rating' THEN LOWER(rating)
									WHEN 'conclusion' THEN LOWER(DBMS_LOB.SUBSTR(conclusion, 1000, 1))
									WHEN 'answer' THEN LOWER(DBMS_LOB.SUBSTR(answer, 1000, 1))
									WHEN 'dataPoints' THEN LOWER(DBMS_LOB.SUBSTR(data_points, 1000, 1))
									WHEN 'lastUpdatedFormatted' THEN TO_CHAR(last_updated, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'supplierName' THEN LOWER(supplier_name)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN iqa.id END DESC,
							CASE WHEN in_order_dir='DESC' THEN iqa.id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
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
	out_cur 						OUT  SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.GetList', in_compound_filter_id);
	
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
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);	

	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	--INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
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
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_SUM;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search						=> in_search,
		in_group_key					=> in_group_key,
		in_pre_filter_sid				=> in_pre_filter_sid,
		in_parent_type					=> in_parent_type,
		in_parent_id					=> in_parent_id,
		in_compound_filter_id			=> in_compound_filter_id,
		in_region_sids					=> in_region_sids,
		in_start_dtm					=> in_start_dtm,
		in_end_dtm						=> in_end_dtm,
		in_region_col_type				=> in_region_col_type,
		in_date_col_type				=> in_date_col_type,
		in_grp_by_compound_filter_id	=> in_grp_by_compound_filter_id,
		out_id_list						=> v_id_list
	);
			
	IF in_grp_by_compound_filter_id IS NOT NULL THEN	
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER, in_grp_by_compound_filter_id,
		in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	OPEN out_cur FOR
		SELECT fil_list.object_id
		  FROM TABLE(in_id_list) fil_list;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
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
	out_cur 						OUT  SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);
	
	-- Group by thing to ensure correct ordering on export
	SELECT security.T_ORDERED_SID_ROW(object_id, MAX(rn))
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT object_id, ROWNUM rn
		  FROM TABLE(v_id_list)
	)
	GROUP BY object_id;

	--INTERNAL_PopGridExtTempTable(v_id_page);
	
	CollectSearchResults(v_id_page, out_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.integration_question_answer_report_pkg.GetListAsExtension', in_compound_filter_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER
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
	
	CollectSearchResults(
		in_id_list					=> v_id_page,
		out_cur 					=> out_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

END integration_question_answer_report_pkg;
/
