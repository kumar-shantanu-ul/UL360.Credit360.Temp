-- Please update version too -- this keeps clean builds in sync
define version=1766
@update_header

alter table csr.measure add divisibility number(10);
update csr.measure set divisibility = 1;
alter table csr.measure modify divisibility not null;
alter table csr.ind rename column divisible to divisibility;

create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

alter table csrimp.measure add divisibility number(10);
update csrimp.measure set divisibility = 1;
alter table csrimp.measure modify divisibility not null;
alter table csrimp.ind rename column divisible to divisibility;

alter table actions.ind_template rename column divisible to divisibility;

alter table csr.std_measure_conversion add divisible number(1) default 1 not null;

begin
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=68;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=74;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=73;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=34;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=102;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=20277;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=13613;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=64;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26196;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=7957;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=101;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=100;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=49;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=71;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=51;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26170;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=59;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=44;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=43;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26195;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26194;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=25877;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=17;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26178;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1573;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1517;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=116;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26193;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=14677;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=23637;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=24757;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=69;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=99;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=4597;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26101;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=86;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26190;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=85;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1461;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=54;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=22517;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26171;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26161;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=119;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=33;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26187;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=55;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=3477;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26185;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=16;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=112;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=79;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=60;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=10197;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=21509;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=98;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=106;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1293;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=35;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=56;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1237;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=103;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=76;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26184;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26186;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=37;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=18;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=113;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=19;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=38;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=58;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1349;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1405;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26198;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26199;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=57;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=20;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26045;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=25933;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=63;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26175;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=108;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=52;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=2;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=1;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26197;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26183;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=12437;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=12493;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26192;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26191;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26169;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=80;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26179;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26165;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26163;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=2357;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=77;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=22;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26174;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=13557;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=40;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=3;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=4;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=24813;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=53;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=39;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=78;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=36;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=5;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=12;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=21397;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=24869;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26180;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26182;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=81;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26189;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=7;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=6;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26181;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=13;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=83;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=6837;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=84;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=82;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=28;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=118;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=27;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=11317;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=24925;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26158;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=19157;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=9;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=14;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=62;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=61;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26159;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26200;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=24;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=25;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=10;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=23;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=72;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=109;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=70;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=9077;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26166;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26168;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26167;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26157;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=110;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26188;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=107;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=114;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26177;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=93;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=5773;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=18037;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=25990;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=25991;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=25992;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26160;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=104;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26173;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=66;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=26162;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=67;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=94;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=5885;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=105;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=95;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=96;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=97;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=25989;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26164;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=26176;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=111;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=90;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=91;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=92;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=16917;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=5829;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=5941;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=115;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=131;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=75;
update csr.std_measure_conversion set divisible=0 where std_measure_conversion_id=65;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=30;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=50;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=48;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=46;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=41;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=89;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=88;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=87;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=45;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=42;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=29;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=11;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=15797;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=5717;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=229;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=173;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=117;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=32;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=8;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=31;
update csr.std_measure_conversion set divisible=1 where std_measure_conversion_id=47;
end;
/

update csr.measure m 
   set divisibility = (select decode(divisible, 0, 2, 1, 1)
   						 from csr.std_measure_conversion smc
   						where smc.std_measure_conversion_id = m.std_measure_conversion_id)
 where m.std_measure_conversion_id is not null;

alter table csr.customer add check_divisibility number(1) default 1 not null;
update csr.customer set check_divisibility = 0;
alter table csr.customer add constraint ck_customer_check_divis check (check_divisibility in (0,1));

alter table csrimp.customer add check_divisibility number(1) default 1 not null;
alter table csrimp.customer add CONSTRAINT CK_CUSTOMER_CHECK_DIVIS CHECK (CHECK_DIVISIBILITY IN (0,1));

@../indicator_pkg
@../measure_pkg
@../indicator_body
@../measure_body
@../vb_legacy_pkg
@../vb_legacy_body
@../pending_datasource_body
@../scenario_run_body
@../csrimp/imp_body
@../val_body
@../range_body
@../audit_body
@../model_body
@../aggregate_ind_pkg
@../quick_survey_body
@../dataview_body
@../ruleset_body
@../supplier_body
@../delegation_body
@../stored_calc_datasource_body
@../dataset_legacy_body
@../pending_body
@../datasource_body
@../sheet_body
@../val_datasource_body
@../schema_body
@../csr_app_body
@../aggregate_ind_body
@../actions/initiative_body
@../actions/task_body
@../actions/ind_template_body

@update_tail
