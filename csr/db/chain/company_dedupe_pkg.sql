CREATE OR REPLACE PACKAGE CHAIN.company_dedupe_pkg
IS

FUNCTION DataMergedFromHigherPriorSrc(
	in_company_sid 					IN security_pkg.T_SID_ID
)RETURN NUMBER;

FUNCTION DataMergedFromHigherPriorSrc(
	in_company_sid 					IN security_pkg.T_SID_ID,
	in_import_source_id				IN import_source.import_source_id%TYPE
)RETURN NUMBER;

PROCEDURE QueueDedupeBatchJob(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_batch_job_id				OUT	dedupe_batch_job.batch_job_id%TYPE
);

PROCEDURE LockAndQueueDedupeBatchJob(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_batch_job_id				OUT	dedupe_batch_job.batch_job_id%TYPE
);

PROCEDURE GetDedupeBatchJob(
	in_batch_job_id					IN csr.batch_job.batch_job_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStagingRecords(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ProcessParentStagingRecord(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0
);

PROCEDURE ProcessParentStagingRecord(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_processed_record_ids		OUT security_pkg.T_SID_IDS
);

/* Only made public for tests */
FUNCTION TryParseUserSid(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	out_user_sid				OUT security_pkg.T_SID_ID,
	out_raw_val					OUT VARCHAR2
)RETURN BOOLEAN;

/* Only made public for tests */
FUNCTION TryParseVal(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	in_data_type				IN cms.tab_column.data_type%TYPE,
	out_str_val					OUT VARCHAR2,
	out_date_val				OUT DATE
) RETURN BOOLEAN;

/* Only made public for tests */
FUNCTION TryParseEnumVal(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	in_destination_col_sid		IN dedupe_mapping.destination_col_sid%TYPE,
	out_enum_value_id			OUT NUMBER,
	out_staging_val				OUT VARCHAR2,
	out_translated_val			OUT VARCHAR2
)RETURN BOOLEAN;

/* Only made public for tests */
PROCEDURE MergePreparedCmsData (
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_destination_table			IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid			IN cms.tab.oracle_table%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE
);

FUNCTION CreateUserMergeJob
RETURN csr.batch_job.batch_job_id%TYPE;

PROCEDURE SetUserAction (
	in_batch_job_id					IN dedupe_processed_record.batch_job_id%TYPE,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_dedupe_action				IN dedupe_processed_record.dedupe_action%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID
);

PROCEDURE ProcessUserActions (
	in_batch_job_id					IN	csr.batch_job.batch_job_id%TYPE,
	out_result						OUT	csr.batch_job.result%TYPE,
	out_result_url					OUT	csr.batch_job.result_url%TYPE
);

/* Only made public for tests */
PROCEDURE MergeRecord (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID
);

/* Only made public for tests */
PROCEDURE MergeRecord (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	out_child_proc_record_ids		OUT security.security_pkg.T_SID_IDS
);

/* Only made public for tests */
FUNCTION TestFindMatchesForRuleSet(
	in_rule_set_id					IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.ORACLE_SCHEMA%TYPE,
	in_staging_tab_name				IN cms.tab.ORACLE_TABLE%TYPE,
	in_staging_id_col_name			IN cms.tab_column.ORACLE_COLUMN%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.ORACLE_COLUMN%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN VARCHAR2 DEFAULT NULL
)RETURN security.T_SID_TABLE;

/* Only made public for tests */
FUNCTION FindAndStoreMatches(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_rule_set_id					OUT dedupe_rule_set.dedupe_rule_set_id%TYPE,
	out_resulted_match_type_id		OUT dedupe_rule_set.dedupe_match_type_id%TYPE,
	out_processed_record_id			OUT dedupe_processed_record.dedupe_processed_record_id%TYPE
)RETURN security_pkg.T_SID_IDS;

FUNCTION FindAndStoreMatchesPendi_UNSEC(
	in_pending_company_sid		security_pkg.T_SID_ID
)RETURN security_pkg.T_SID_IDS; /*company_sids*/

FUNCTION FindMatchesForNewCompany_UNSEC(
	in_company_row		T_DEDUPE_COMPANY_ROW,
	in_tag_ids			security_pkg.T_SID_IDS,
	in_ref_ids			security_pkg.T_SID_IDS,
	in_ref_vals			chain_pkg.T_STRINGS
)RETURN security_pkg.T_SID_IDS; /*company_sids*/

FUNCTION GetWebsiteDomainName(
	in_website				IN company.website%TYPE
)RETURN company.website%TYPE
DETERMINISTIC;

FUNCTION TryLockImportSource(
	in_import_source_id		IN import_source.import_source_id%TYPE
) RETURN BOOLEAN;

PROCEDURE ReleaseImportSourceLock(
	in_import_source_id		IN import_source.import_source_id%TYPE DEFAULT NULL
);

END company_dedupe_pkg;
/

