/*
grant create table to csr;
If this is not granted, you will likely get errors like this when attempting to "create index":
Error report -
ORA-29855: error occurred in the execution of ODCIINDEXCREATE routine
ORA-20000: Oracle Text error:
DRG-50857: oracle error in drvxtab.create_index_tables
ORA-01031: insufficient privileges
ORA-06512: at "CTXSYS.DRUE", line 186
ORA-06512: at "CTXSYS.TEXTINDEXMETHODS", line 320
29855. 00000 -  "error occurred in the execution of ODCIINDEXCREATE routine"
*Cause:    Failed to successfully execute the ODCIIndexCreate routine.
*Action:   Check to see if the routine has been coded correctly.
*/
grant create table to csr;

/* DOCLIB FILE INDEX */
create index csr.ix_doc_search on csr.doc_data(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* DOCLIB DOC DESCRIPTION INDEX */
create index csr.ix_doc_desc_search on csr.doc_version(description) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* DELEGATION FILE UPLOAD INDEX */
create index csr.ix_file_upload_search on csr.file_upload(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* DELEGATION SHEET NOTES INDEX */
create index csr.ix_sh_val_note_search on csr.sheet_value(note) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* HELP BODY TEXT INDEX */
create index csr.ix_help_body_search on csr.help_topic_text(body) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* SURVEY MANAGER FILE INDEX */
create index csr.ix_qs_response_file_srch on csr.qs_response_file(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* SURVEY ANSWER ANSWER INDEX */
create index csr.ix_qs_ans_ans_search on csr.quick_survey_answer(answer) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* ISSUE LOG TEXT INDEX */
create index csr.ix_issue_log_search on csr.issue_log(message) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* ISSUE LABEL TEXT INDEX */
create index csr.ix_issue_search on csr.issue(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* ISSUE DESCRIPTION TEXT INDEX */
create index csr.ix_issue_desc_search on csr.issue(description) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* AUDIT LABEL TEXT INDEX */
create index csr.ix_audit_label_search on csr.internal_audit(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* AUDIT NOTES TEXT INDEX */
create index csr.ix_audit_notes_search on csr.internal_audit(notes) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE LABEL TEXT INDEX */
create index csr.ix_non_comp_label_search on csr.non_compliance(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE DETAIL TEXT INDEX */
create index csr.ix_non_comp_detail_search on csr.non_compliance(detail) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE ROOT_CAUSE TEXT INDEX */
create index csr.ix_non_comp_rt_cse_search on csr.non_compliance(root_cause) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* NON COMPLIANCE SUGGESTED_ACTION TEXT INDEX */
create index csr.ix_non_comp_sugact_search on csr.non_compliance(suggested_action) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* Preference for fuzzy and stemming searchs on text indexes */
BEGIN
	ctx_ddl.create_preference('CSR.STEM_FUZZY_PREF', 'BASIC_WORDLIST');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_MATCH','ENGLISH');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_SCORE','1');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_NUMRESULTS','5000');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','SUBSTRING_INDEX','TRUE');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','STEMMER','AUTO');
END;
/

/* SECTION HTML INDEX */
create index csr.ix_section_body_search on csr.section_version(body) indextype is ctxsys.context 
parameters ('filter CTXSYS.NULL_FILTER section group ctxsys.html_section_group stoplist ctxsys.empty_stoplist Wordlist CSR.STEM_FUZZY_PREF');

/* SECTION TITLE INDEX */
create index csr.ix_section_title_search on csr.section_version(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist Wordlist CSR.STEM_FUZZY_PREF');

/* COMPLIANCE ITEM TITLE INDEX */
create index csr.ix_ci_title_search on csr.compliance_item_description(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM SUMMARY INDEX */
create index csr.ix_ci_summary_search on csr.compliance_item_description(summary) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM DETAILS INDEX */
create index csr.ix_ci_details_search on csr.compliance_item_description(details) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM REFERENCE CODE INDEX */
create index csr.ix_ci_ref_code_search on csr.compliance_item(reference_code) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM USER COMMENT INDEX */
create index csr.ix_ci_usr_comment_search on csr.compliance_item(user_comment) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE ITEM CITATION INDEX */
create index csr.ix_ci_citation_search on csr.compliance_item_description(citation) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE PERMIT TITLE INDEX */
create index csr.ix_cp_title_search on csr.compliance_permit(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE PERMIT REFERENCE INDEX */
create index csr.ix_cp_reference_search on csr.compliance_permit(permit_reference) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* COMPLIANCE PERMIT ACTIVITY DETAILS INDEX */
create index csr.ix_cp_activity_details_search on csr.compliance_permit(activity_details) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from csr;

grant execute on ctx_ddl to csr;
@@create_text_indexes_jobs
