-- Please update version.sql too -- this keeps clean builds in sync
define version=854
@update_header


-- Getting errors? SYS.LOW_PRIORITY_CLASS doesn't seem to exist? Try aspen2\tools\job_class.sql

-- Notes from Casey: Mw pointed me at some other scripts that create jobs:
--
--@security/db/oracle/create_jobs
--@aspen2/db/filecache_job
--@../oss/shared/FormTransaction/db/FormTransaction_job.sql
--@aspen2/cms/db/create_jobs
--@csr\db\create_jobs
--@csr\db\create_text_indexes_jobs
--@csr\chain\create_text_indexes_jobs
--
--You need to run these using "system/manager as sysdba" otherwise they won't run. 

grant execute on SYS.LOW_PRIORITY_JOB to csr;

/* SURVEY MANAGER FILE INDEX */
grant create table to csr;
create index csr.ix_qs_answer_file_search on csr.qs_answer_file(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from csr;

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.qs_answer_file_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''csr.ix_qs_answer_file_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise survey mangager text indexes');
       COMMIT;
END;
/


grant execute on SYS.LOW_PRIORITY_JOB to chain;

/* CHAIN UPLOAD FILE INDEX */
grant create table to chain;
create index chain.ix_file_upload_search on chain.file_upload(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
revoke create table from chain;

-- reindex job -- index on commit is flaky
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.file_upload_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''chain.ix_file_upload_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise survey mangager text indexes');
       COMMIT;
END;
/

grant select on csr.supplier_survey_response to chain;
grant select on csr.quick_survey_response to chain;
grant select on csr.quick_survey_answer to chain;
grant select on csr.qs_answer_file to chain;

grant select on chain.v$questionnaire_share to csr;
grant select, delete on chain.questionnaire_type to csr;

-- Output from chain.card_pkg.DumpCard
DECLARE
v_card_id         chain.card.card_id%TYPE;
v_desc            chain.card.description%TYPE;
v_class           chain.card.class_type%TYPE;
v_js_path         chain.card.js_include%TYPE;
v_js_class        chain.card.js_class_type%TYPE;
v_css_path        chain.card.css_include%TYPE;
v_actions         chain.T_STRING_LIST;
BEGIN
-- Chain.Cards.InvitationSummaryWithCheck
v_desc := 'Confirmation page for inviting a new supplier that includes check on email domain';
v_class := 'Credit360.Chain.Cards.Empty';
v_js_path := '/csr/site/chain/cards/invitationSummaryWithCheck.js';
v_js_class := 'Chain.Cards.InvitationSummaryWithCheck';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
END;
/


CREATE OR REPLACE VIEW CHAIN.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp.country_name supplier_country_name, 
			pc.purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur.country_name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id, NVL2(pc.supplier_product_id, 1, 0) mapped, mapped_by_user_sid, mapped_dtm,
			p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked
	  FROM purchased_component pc, component cmp, v$company supp, v$company pur, uninvited_supplier unv, v$product p
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
	   AND pc.supplier_product_id = p.product_id (+)
	   AND pc.app_sid = p.app_sid (+)
	   AND pc.supplier_company_sid = supp.company_sid(+)
	   AND pc.purchaser_company_sid = pur.company_sid(+)
	   AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid(+)
;

CREATE OR REPLACE VIEW CHAIN.v$component_product_rel AS
	SELECT 
			app_sid, 
			container_component_id, 
			container_component_type_id, 
			child_component_id, 
			child_component_type_id, 
			company_sid, 
			amount_child_per_parent, 
			amount_unit_id
	  FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	UNION
	SELECT 
			app_sid, 
			component_id container_component_id,
			3 container_component_type_id, -- chain.chain_pkg.PURCHASED_COMPONENT
			supplier_product_id child_component_id, 
			1 child_component_type_id,  -- chain.chain_pkg.PRODUCT_COMPONENT
			company_sid, 
			100 amount_child_per_parent, 
			1 amount_unit_id -- chain.chain_pkg.AU_PERCENTAGE unit ID for %
	FROM v$purchased_component
	WHERE supplier_product_id IS NOT NULL
	  AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

@..\chain\setup_pkg
@..\chain\chain_link_pkg
@..\chain\company_pkg
@..\chain\company_filter_pkg
@..\chain\filter_pkg
@..\supplier_pkg
@..\quick_survey_pkg

@..\chain\setup_body
@..\chain\card_body
@..\chain\capability_body
@..\chain\chain_link_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\chain\invitation_body
@..\quick_survey_body
@..\supplier_body
@..\indicator_body

@update_tail
