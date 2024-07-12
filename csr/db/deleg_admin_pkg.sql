CREATE OR REPLACE PACKAGE csr.deleg_admin_pkg AS


PROCEDURE SetIndTags(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tags				IN	security_pkg.T_VARCHAR2_ARRAY
);


PROCEDURE CreateIndCond(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_expr				IN	delegation_ind_cond.expr%TYPE,
	out_ind_cond_id		OUT	delegation_ind_cond.delegation_ind_cond_id%TYPE
);

PROCEDURE AmendIndCond(
	in_ind_cond_id		IN	delegation_ind_cond.delegation_ind_cond_id%TYPE,
	in_expr				IN	delegation_ind_cond.expr%TYPE
);

PROCEDURE SetStyles(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_description		IN	delegation_ind_description.description%TYPE,
	in_css_class		IN	delegation_ind.css_class%TYPE,
	in_visibility		IN	delegation_ind.visibility%TYPE,
	in_change_all		IN	NUMBER
);

PROCEDURE DeleteIndCond(
	in_ind_cond_id		IN	delegation_ind_cond.delegation_ind_cond_id%TYPE
);

-- this gets called repeatedly so we rely on the security check in CreateIndCond or AmendIndCod
PROCEDURE UNSEC_AddIndCondAction(
	in_ind_cond_id		IN	delegation_ind_cond_action.delegation_ind_cond_id%TYPE,
	in_action			IN	delegation_ind_cond_action.action%TYPE,
	in_tag				IN	delegation_ind_cond_action.tag%TYPE
);


PROCEDURE GetConditions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	cur_ind_tag				OUT	security_pkg.T_OUTPUT_CUR,
	cur_ind_cond			OUT	security_pkg.T_OUTPUT_CUR,
	cur_ind_cond_action		OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetFormExpressions(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetFormExpressionForIndicator(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_ind_sid          IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetFormExpressionForIndicator(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_ind_sid          IN  security_pkg.T_SID_ID,
    in_form_expr_id     IN  form_expr.form_expr_id%TYPE
);


PROCEDURE CreateFormExpression(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_expr             IN  form_expr.expr%TYPE,
    in_description      IN  form_expr.description%TYPE,
    out_form_expr_id    OUT form_expr.form_expr_id%TYPE
);


PROCEDURE UpdateFormExpression(
    in_form_expr_id     IN form_expr.form_expr_id%TYPE,
    in_expr             IN  form_expr.expr%TYPE,
    in_description      IN  form_expr.description%TYPE
);


PROCEDURE DeleteFormExpression(
    in_form_expr_id     IN form_expr.form_expr_id%TYPE
);


--PROCEDURE GetDelegationIndicators(
--    in_delegation_sid   IN  security_pkg.T_SID_ID,
--    out_cur             OUT security_pkg.T_OUTPUT_CUR
--);


PROCEDURE GetDelegationIndExpressionMap(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetDelegIndGroups(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetDelegIndGroupInds(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    out_cur                  OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE CreateDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_title                 IN  deleg_ind_group.title%TYPE,
	in_start_collapsed		 IN	 deleg_ind_group.start_collapsed%TYPE,
    out_deleg_ind_group_id   OUT deleg_ind_group.deleg_ind_group_id%TYPE
);


PROCEDURE UpdateDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    in_title                 IN  deleg_ind_group.title%TYPE,
	in_start_collapsed		 IN	 deleg_ind_group.start_collapsed%TYPE
);


PROCEDURE DeleteDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE
);


PROCEDURE AddIndToDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    in_ind_sid               IN  security_pkg.T_SID_ID
);


PROCEDURE RemoveIndFromDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_ind_sid               IN  security_pkg.T_SID_ID
);


PROCEDURE GetDelegIndGroupForInd(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_ind_sid               IN  security_pkg.T_SID_ID,
    out_deleg_ind_group_id   OUT deleg_ind_group.deleg_ind_group_id%TYPE
);

END;
/
