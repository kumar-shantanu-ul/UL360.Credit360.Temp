CREATE OR REPLACE PACKAGE BODY CHAIN.company_score_pkg
IS

PROCEDURE GetCompanyTypeScoreCalcs (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE DEFAULT NULL,
	in_score_type_id				IN	chain.company_type_score_calc.score_type_id%TYPE DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_types_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security needed

	OPEN out_cur FOR
		SELECT company_type_id, score_type_id,
			   calc_type, operator_type,
			   supplier_score_type_id, active_suppliers_only
		  FROM company_type_score_calc
		 WHERE company_type_id = NVL(in_company_type_id, company_type_id)
		   AND score_type_id = NVL(in_score_type_id, score_type_id)
		 ORDER BY company_type_id, score_type_id;

	OPEN out_comp_types_cur FOR
		SELECT company_type_id, score_type_id,
			   supplier_company_type_id
		  FROM comp_type_score_calc_comp_type
		 WHERE company_type_id = NVL(in_company_type_id, company_type_id)
		   AND score_type_id = NVL(in_score_type_id, score_type_id)
		 ORDER BY company_type_id, score_type_id, supplier_company_type_id;
END;

PROCEDURE SetCompanyTypeScoreCalc (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE,
	in_score_type_id				IN	chain.company_type_score_calc.score_type_id%TYPE,
	in_calc_type					IN	chain.company_type_score_calc.calc_type%TYPE,
	in_operator_type				IN	chain.company_type_score_calc.operator_type%TYPE,
	in_supplier_score_type_id		IN	chain.company_type_score_calc.supplier_score_type_id%TYPE,
	in_active_suppliers_only		IN	chain.company_type_score_calc.active_suppliers_only%TYPE,
	in_sup_cmp_type_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_calc_type						chain.company_type_score_calc.calc_type%TYPE := LOWER(in_calc_type);
	v_operator_type					chain.company_type_score_calc.operator_type%TYPE := LOWER(in_operator_type);
	v_sup_cmp_type_ids				security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveCompanyTypeScoreCalc can only be run as BuiltIn/Administrator or a superadmin');
	END IF;

	BEGIN
		INSERT INTO company_type_score_calc (
			company_type_id, score_type_id,
			calc_type, operator_type,
			supplier_score_type_id, active_suppliers_only
		) VALUES (
			in_company_type_id, in_score_type_id,
			v_calc_type, v_operator_type,
			in_supplier_score_type_id, in_active_suppliers_only
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE company_type_score_calc
			   SET calc_type = v_calc_type,
				   operator_type = v_operator_type,
				   supplier_score_type_id = in_supplier_score_type_id,
				   active_suppliers_only = in_active_suppliers_only
			 WHERE company_type_id = in_company_type_id
			   AND score_type_id = in_score_type_id;
	END;

	DELETE FROM comp_type_score_calc_comp_type
	 WHERE company_type_id = in_company_type_id
	   AND score_type_id = in_score_type_id;

	IF in_sup_cmp_type_ids IS NULL OR (in_sup_cmp_type_ids.COUNT = 1 AND in_sup_cmp_type_ids(1) IS NULL) THEN
		NULL;
	ELSE
		v_sup_cmp_type_ids := security_pkg.SidArrayToTable(in_sup_cmp_type_ids);

		INSERT INTO comp_type_score_calc_comp_type (
			   company_type_id, 
			   score_type_id, 
			   supplier_company_type_id
		)
		SELECT in_company_type_id company_type_id,
			   in_score_type_id score_type_id,
			   column_value supplier_company_type_id
		  FROM TABLE(v_sup_cmp_type_ids);
	END IF;
END;

PROCEDURE DeleteCompanyTypeScoreCalcs (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE,
	in_keep_score_type_ids			IN	security_pkg.T_SID_IDS
)
AS
	v_keep_score_type_ids		security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveCompanyTypeScoreCalc can only be run as BuiltIn/Administrator or a superadmin');
	END IF;

	IF in_keep_score_type_ids IS NULL OR (in_keep_score_type_ids.COUNT = 1 AND in_keep_score_type_ids(1) IS NULL) THEN
		DELETE FROM comp_type_score_calc_comp_type
		 WHERE company_type_id = in_company_type_id;

		DELETE FROM company_type_score_calc
		 WHERE company_type_id = in_company_type_id;
	ELSE
		v_keep_score_type_ids := security_pkg.SidArrayToTable(in_keep_score_type_ids);
		
		DELETE FROM comp_type_score_calc_comp_type
		 WHERE company_type_id = in_company_type_id
		   AND score_type_id NOT IN (
			SELECT column_value FROM TABLE(v_keep_score_type_ids)
		   );

		DELETE FROM company_type_score_calc
		 WHERE company_type_id = in_company_type_id
		   AND score_type_id NOT IN (
			SELECT column_value FROM TABLE(v_keep_score_type_ids)
		   );
	END IF;
END;

PROCEDURE INTERNAL_RecalcCompanyScore (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE,
	in_score_source_type			IN	csr.supplier_score_log.score_source_type%TYPE,
	in_score_source_id				IN	csr.supplier_score_log.score_source_id%TYPE
)
AS
	v_company_type_id				chain.company_type_score_calc.company_type_id%TYPE;
	v_calc_type						chain.company_type_score_calc.calc_type%TYPE;
	v_operator_type					chain.company_type_score_calc.operator_type%TYPE;
	v_supplier_score_type_id		chain.company_type_score_calc.supplier_score_type_id%TYPE;
	v_active_suppliers_only			chain.company_type_score_calc.active_suppliers_only%TYPE;

	v_score							csr.supplier_score_log.score%TYPE;
	v_score_threshold_id			csr.supplier_score_log.score_threshold_id%TYPE;

BEGIN
	BEGIN
		SELECT ctsc.company_type_id, ctsc.calc_type, ctsc.operator_type,
			   ctsc.supplier_score_type_id, ctsc.active_suppliers_only
		  INTO v_company_type_id, v_calc_type, v_operator_type,
			   v_supplier_score_type_id, v_active_suppliers_only
		  FROM company_type_score_calc ctsc
		  JOIN company c ON c.company_type_id = ctsc.company_type_id
		 WHERE c.company_sid = in_company_sid
		   AND ctsc.score_type_id = in_score_type_id;
	EXCEPTION
		WHEN no_data_found THEN
			RETURN;
	END;

	IF v_calc_type = csr.csr_data_pkg.SCORE_CALC_TYPE_SUPPLIER_SCORE THEN
		BEGIN
			SELECT CASE v_operator_type
					WHEN 'sum' THEN SUM(ssl.score)
					WHEN 'avg' THEN AVG(ssl.score)
					WHEN 'min' THEN MIN(ssl.score)
					WHEN 'max' THEN MAX(ssl.score)
				   END aggregate_score
			  INTO v_score
			  FROM csr.current_supplier_score css
			  JOIN csr.supplier_score_log ssl ON ssl.supplier_score_id = css.last_supplier_score_id
			  JOIN chain.supplier_relationship sr ON sr.supplier_company_sid = css.company_sid
			  JOIN chain.company sc ON sc.company_sid = sr.supplier_company_sid
			  JOIN chain.comp_type_score_calc_comp_type ctscct ON ctscct.supplier_company_type_id = sc.company_type_id
			 WHERE css.score_type_id = v_supplier_score_type_id
			   AND ctscct.company_type_id = v_company_type_id
			   AND ctscct.score_type_id = in_score_type_id
			   AND sr.purchaser_company_sid = in_company_sid
			   AND sr.deleted = chain_pkg.NOT_DELETED
			   AND sr.active = chain_pkg.ACTIVE
			   AND sc.deleted = chain_pkg.NOT_DELETED
			   AND (sc.active = chain_pkg.ACTIVE OR v_active_suppliers_only = 0)
			 GROUP BY sr.purchaser_company_sid;
		EXCEPTION
			WHEN no_data_found THEN
				v_score := NULL;
		END;
	END IF;

	v_score_threshold_id := csr.quick_survey_pkg.GetThresholdFromScore(in_score_type_id, v_score);

	csr.supplier_pkg.UNSEC_UpdateSupplierScore(
		in_supplier_sid				=> in_company_sid,
		in_score_type_id			=> in_score_type_id,
		in_score					=> v_score,
		in_threshold_id				=> v_score_threshold_id,
		in_as_of_date				=> in_set_dtm,
		in_comment_text				=> 'Score automatically recalculated',
		in_valid_until_dtm			=> in_valid_until_dtm,
		in_score_source_type		=> in_score_source_type,
		in_score_source_id			=> in_score_source_id,
		in_propagate_scores			=> 0
	);
END;

PROCEDURE RecalculateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access for scores denied to company with sid '||in_company_sid);
	END IF;

	UNSEC_RecalculateCompanyScores(
		in_company_sid				=>	in_company_sid,
		in_score_type_id			=>	in_score_type_id,
		in_set_dtm					=>	in_set_dtm,
		in_valid_until_dtm			=>	in_valid_until_dtm
	);
END;

PROCEDURE UNSEC_RecalculateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
)
AS
	v_company_type_id				company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_company_sid);
BEGIN
	FOR r IN (
		SELECT score_type_id
		  FROM company_type_score_calc
		 WHERE company_type_id = v_company_type_id
		   AND score_type_id = NVL(in_score_type_id, score_type_id)
	) LOOP
		INTERNAL_RecalcCompanyScore(
			in_company_sid			=> in_company_sid, 
			in_score_type_id		=> r.score_type_id,
			in_set_dtm				=> in_set_dtm,
			in_valid_until_dtm		=> in_valid_until_dtm,
			in_score_source_type	=> csr.csr_data_pkg.SCORE_SOURCE_TYPE_SCORE_CALC,
			in_score_source_id		=> in_company_sid
		);
	END LOOP;

	UNSEC_PropagateCompanyScores(
		in_company_sid			=> in_company_sid, 
		in_score_type_id		=> in_score_type_id,
		in_set_dtm				=> in_set_dtm,
		in_valid_until_dtm		=> in_valid_until_dtm
	);
END;

PROCEDURE UNSEC_PropagateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	FOR r IN (
		WITH company_dependencies AS (
			SELECT sr.supplier_company_sid source_company_sid, ctsc.supplier_score_type_id source_score_type_id,
				   sr.purchaser_company_sid dest_company_sid, ctsc.score_type_id dest_score_type_id
			  FROM supplier_relationship sr
			  JOIN company pc ON sr.purchaser_company_sid = pc.company_sid
			  JOIN company sc ON sr.supplier_company_sid = sc.company_sid
			  JOIN company_type_score_calc ctsc ON ctsc.company_type_id = pc.company_type_id
			  JOIN comp_type_score_calc_comp_type ctscct ON ctscct.company_type_id = ctsc.company_type_id 
														 AND ctscct.score_type_id = ctsc.score_type_id
														 AND ctscct.supplier_company_type_id = sc.company_type_id
			 WHERE pc.deleted = chain_pkg.NOT_DELETED -- We don't check the supplier or the relationship, because we might be propagating a deletion or deactivation
			   AND ctsc.calc_type = csr.csr_data_pkg.SCORE_CALC_TYPE_SUPPLIER_SCORE
		)
		SELECT company_sid, score_type_id FROM (
			SELECT company_sid, score_type_id, MAX(lvl) max_lvl FROM (
				SELECT cd.dest_company_sid company_sid, cd.dest_score_type_id score_type_id, LEVEL lvl
				  FROM company_dependencies cd
				 START WITH cd.source_company_sid = in_company_sid
						AND (in_score_type_id IS NULL OR cd.source_score_type_id = in_score_type_id)
				 CONNECT BY cd.source_company_sid = PRIOR cd.dest_company_sid
						AND cd.source_score_type_id = PRIOR cd.dest_score_type_id
			)
			GROUP BY company_sid, score_type_id
		)
		ORDER BY max_lvl ASC
	) LOOP
		INTERNAL_RecalcCompanyScore(
			in_company_sid			=> r.company_sid, 
			in_score_type_id		=> r.score_type_id,
			in_set_dtm				=> in_set_dtm,
			in_valid_until_dtm		=> in_valid_until_dtm,
			in_score_source_type	=> csr.csr_data_pkg.SCORE_SOURCE_TYPE_SCORE_CALC,
			in_score_source_id		=> in_company_sid
		);
	END LOOP;
END;

END company_score_pkg;
/
