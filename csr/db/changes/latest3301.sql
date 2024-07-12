-- Please update version.sql too -- this keeps clean builds in sync
define version=3301
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON supplier.all_company TO csr;
DECLARE
	PROCEDURE AddDeleteGrant(
		in_schema				varchar2,
		in_table				varchar2
	) AS
	BEGIN

		DECLARE
			v_count number;
			v_sql varchar2(2000);
		BEGIN

			v_sql := 'SELECT count(*) from SYS.all_tables where lower(table_name) = '''||in_table ||''' and lower(owner) = '''||in_schema||'''';
			EXECUTE IMMEDIATE v_sql INTO v_count;
			IF v_count = 1 THEN
				EXECUTE IMMEDIATE 'GRANT DELETE ON ' || in_schema || '.' || in_table || ' to csr';
			END IF;

		END;
	END;
BEGIN
	AddDeleteGrant('supplier', 'product_revision_tag');
	AddDeleteGrant('supplier', 'gt_formulation_answers');
	AddDeleteGrant('supplier', 'gt_fa_wsr');
	AddDeleteGrant('supplier', 'gt_fa_anc_mat');
	AddDeleteGrant('supplier', 'gt_fa_haz_chem');
	AddDeleteGrant('supplier', 'gt_fa_palm_ind');
	AddDeleteGrant('supplier', 'gt_fa_endangered_sp');
	AddDeleteGrant('supplier', 'gt_packaging_answers');
	AddDeleteGrant('supplier', 'gt_pack_item');
	AddDeleteGrant('supplier', 'gt_product_answers');
	AddDeleteGrant('supplier', 'gt_link_product');
	AddDeleteGrant('supplier', 'gt_country_sold_in');
	AddDeleteGrant('supplier', 'gt_profile');
	AddDeleteGrant('supplier', 'gt_scores');
	AddDeleteGrant('supplier', 'gt_supplier_answers');
	AddDeleteGrant('supplier', 'gt_transport_answers');
	AddDeleteGrant('supplier', 'gt_country_made_in');
	AddDeleteGrant('supplier', 'gt_scores_combined');
	AddDeleteGrant('supplier', 'gt_pdesign_answers');
	AddDeleteGrant('supplier', 'gt_pda_material_item');
	AddDeleteGrant('supplier', 'gt_pda_hc_item');
	AddDeleteGrant('supplier', 'gt_pda_anc_mat');
	AddDeleteGrant('supplier', 'gt_pda_endangered_sp');
	AddDeleteGrant('supplier', 'gt_pda_main_power');
	AddDeleteGrant('supplier', 'gt_pda_palm_ind');
	AddDeleteGrant('supplier', 'gt_pda_battery');
	AddDeleteGrant('supplier', 'gt_trans_item');
	AddDeleteGrant('supplier', 'gt_food_answers');
	AddDeleteGrant('supplier', 'gt_fd_answer_scheme');
	AddDeleteGrant('supplier', 'gt_fd_endangered_sp');
	AddDeleteGrant('supplier', 'gt_fd_ingredient');
	AddDeleteGrant('supplier', 'gt_fd_palm_ind');
	AddDeleteGrant('supplier', 'gt_food_anc_mat');
	AddDeleteGrant('supplier', 'gt_food_sa_q');
	AddDeleteGrant('supplier', 'supplier_answers');
	AddDeleteGrant('supplier', 'supplier_answers_wood');
	AddDeleteGrant('supplier', 'fsc_member');
	AddDeleteGrant('supplier', 'gt_target_scores_log');
END;
/

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../chain/chain_body

@update_tail
