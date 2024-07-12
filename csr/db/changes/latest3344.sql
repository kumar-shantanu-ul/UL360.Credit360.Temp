define version=3344
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE CSR.CUSTOMER ADD MOBILE_BRANDING_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_ENABLE_MOBILE_BRANDING CHECK (MOBILE_BRANDING_ENABLED IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD MOBILE_BRANDING_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (MOBILE_BRANDING_ENABLED DEFAULT NULL);










DECLARE
	PROCEDURE UNSEC_DeleteIssue(
		in_issue_id		IN	csr.issue.issue_id%TYPE
	)
	AS
		v_issue_pending_val_id			csr.issue.issue_pending_val_id%TYPE;
		v_issue_sheet_value_id			csr.issue.issue_sheet_value_id%TYPE;
		v_issue_non_compliance_id		csr.issue.issue_non_compliance_id%TYPE;
		v_issue_survey_answer_id		csr.issue.issue_survey_answer_id%TYPE;
		v_issue_action_id				csr.issue.issue_action_id%TYPE;
		v_issue_meter_id				csr.issue.issue_meter_id%TYPE;
		v_issue_meter_alarm_id			csr.issue.issue_meter_alarm_id%TYPE;
		v_issue_meter_raw_data_id		csr.issue.issue_meter_raw_data_id%TYPE;
		v_issue_meter_data_source_id	csr.issue.issue_meter_data_source_id%TYPE;
		v_issue_supplier_id				csr.issue.issue_supplier_id%TYPE;
		v_issue_compliance_region_id	csr.issue.issue_compliance_region_id%TYPE;
	BEGIN
		-- recurse down cleaning out children
		FOR r IN (
			SELECT issue_id
			  FROM csr.issue 
			 WHERE parent_id = in_issue_id
		)
		LOOP
			UNSEC_deleteIssue(r.issue_id);
		END LOOP;
		
		-- get parents
		SELECT issue_pending_val_id, issue_sheet_value_id, issue_non_compliance_id, issue_survey_answer_id, 
			issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id,
			issue_supplier_id, issue_compliance_region_id
		  INTO v_issue_pending_val_id, v_issue_sheet_value_id, v_issue_non_compliance_id, v_issue_survey_answer_id,
			v_issue_action_id, v_issue_meter_id, v_issue_meter_alarm_id, v_issue_meter_raw_data_id, v_issue_meter_data_source_id,
			v_issue_supplier_id, v_issue_compliance_region_id
		  FROM csr.issue
		 WHERE issue_id = in_issue_id;
		 
		-- disconnect from parents
		UPDATE csr.issue
		   SET issue_pending_val_id = null, 
			   issue_sheet_value_id = null,
			   issue_non_compliance_id = null, 
			   issue_survey_answer_id = null,
			   issue_action_id = null,
			   issue_meter_id = null,
			   issue_meter_alarm_id = null,
			   issue_meter_raw_data_id = null,
			   issue_meter_data_source_id = null,
			   issue_supplier_id = null,
			   issue_compliance_region_id = null
		 WHERE issue_id = in_issue_id;
		-- now clean up the parents
		UPDATE csr.issue_log
		   SET issue_id = NULL
		 WHERE issue_id = in_issue_id;
		UPDATE csr.issue_action_log
		   SET issue_id = NULL
		 WHERE issue_id = in_issue_id;
		
		DELETE FROM csr.issue_pending_val
		 WHERE issue_pending_val_id = v_issue_pending_val_id;
		DELETE FROM csr.issue_sheet_value
		 WHERE issue_sheet_value_id = v_issue_sheet_value_id;
		 
		DELETE FROM csr.issue_non_compliance
		 WHERE issue_non_compliance_id = v_issue_non_compliance_id;
		DELETE FROM csr.issue_survey_answer
		 WHERE issue_survey_answer_id = v_issue_survey_answer_id;
		
		DELETE FROM csr.issue_user_cover
		 WHERE issue_id = in_issue_id;
		
		DELETE FROM csr.issue_action
		 WHERE issue_action_id = v_issue_action_id;
		
		DELETE FROM csr.issue_meter
		 WHERE issue_meter_id = v_issue_meter_id;
		
		DELETE FROM csr.issue_meter_alarm
		 WHERE issue_meter_alarm_id = v_issue_meter_alarm_id;
		
		DELETE FROM csr.issue_meter_raw_data
		 WHERE issue_meter_raw_data_id = v_issue_meter_raw_data_id;
		
		DELETE FROM csr.issue_meter_data_source
		 WHERE issue_meter_data_source_id = v_issue_meter_data_source_id;
		
		DELETE FROM csr.issue_supplier
		 WHERE issue_supplier_id = v_issue_supplier_id;
		 
		DELETE FROM csr.issue_compliance_region
		 WHERE issue_compliance_region_id = v_issue_compliance_region_id;
		
		DELETE FROM csr.issue_involvement
		 WHERE issue_id = in_issue_id;
		 
		DELETE FROM csr.issue_custom_field_str_val
		 WHERE issue_id = in_issue_id;
		 
		DELETE FROM csr.issue_custom_field_opt_sel 
		 WHERE issue_id = in_issue_id;
		 
		DELETE FROM csr.issue_custom_field_date_val
		 WHERE issue_id = in_issue_id;
		
		DELETE FROM csr.issue_alert
		 WHERE issue_id = in_issue_id;
		
		BEGIN
			DELETE FROM csr.issue
			 WHERE issue_id = in_issue_id;
		EXCEPTION
			WHEN security.security_pkg.ACCESS_DENIED THEN
				-- Access denied thrown by before delete trigger on all logging forms that have issues
				-- For now, just hide the issue from views by marking it as deleted. 
				UPDATE csr.issue
				   SET deleted = 1
				 WHERE issue_id = in_issue_id;
		END;
	END;
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (SELECT host FROM csr.customer WHERE name = 'lincolnelectric.credit360.com')
	LOOP
		security.user_pkg.logonadmin(r.host);
		-- Ids from "Repeat Actions_2372.xlsx" on TSQ-142
		BEGIN
			UNSEC_DeleteIssue(2863564);
			UNSEC_DeleteIssue(2863565);
			UNSEC_DeleteIssue(2863572);
			UNSEC_DeleteIssue(2863587);
			UNSEC_DeleteIssue(2863588);
			UNSEC_DeleteIssue(2863589);
			UNSEC_DeleteIssue(2863600);
			UNSEC_DeleteIssue(2863602);
			UNSEC_DeleteIssue(2863609);
			UNSEC_DeleteIssue(2863611);
			UNSEC_DeleteIssue(2863616);
			UNSEC_DeleteIssue(2863619);
			UNSEC_DeleteIssue(2863620);
			UNSEC_DeleteIssue(2863624);
			UNSEC_DeleteIssue(2863625);
			UNSEC_DeleteIssue(2863627);
			UNSEC_DeleteIssue(2863634);
			UNSEC_DeleteIssue(2863639);
			UNSEC_DeleteIssue(2863643);
			UNSEC_DeleteIssue(2863648);
			UNSEC_DeleteIssue(2863658);
			UNSEC_DeleteIssue(2863668);
			UNSEC_DeleteIssue(2863679);
			UNSEC_DeleteIssue(2863686);
			UNSEC_DeleteIssue(2863695);
			UNSEC_DeleteIssue(2863711);
			UNSEC_DeleteIssue(2863725);
			UNSEC_DeleteIssue(2863741);
			UNSEC_DeleteIssue(2863754);
			UNSEC_DeleteIssue(2863763);
			UNSEC_DeleteIssue(2863778);
			UNSEC_DeleteIssue(2863784);
			UNSEC_DeleteIssue(2863790);
			UNSEC_DeleteIssue(2863794);
			UNSEC_DeleteIssue(2863801);
			UNSEC_DeleteIssue(2863807);
			UNSEC_DeleteIssue(2863813);
			UNSEC_DeleteIssue(2863826);
			UNSEC_DeleteIssue(2863840);
			UNSEC_DeleteIssue(2863852);
			UNSEC_DeleteIssue(2863859);
			UNSEC_DeleteIssue(2863866);
			UNSEC_DeleteIssue(2863873);
			UNSEC_DeleteIssue(2863879);
			UNSEC_DeleteIssue(2863885);
			UNSEC_DeleteIssue(2863892);
			UNSEC_DeleteIssue(2863898);
			UNSEC_DeleteIssue(2863902);
			UNSEC_DeleteIssue(2863905);
			UNSEC_DeleteIssue(2863917);
			UNSEC_DeleteIssue(2863927);
			UNSEC_DeleteIssue(2863932);
			UNSEC_DeleteIssue(2863936);
			UNSEC_DeleteIssue(2863954);
			UNSEC_DeleteIssue(2863964);
			UNSEC_DeleteIssue(2863968);
			UNSEC_DeleteIssue(2863970);
			UNSEC_DeleteIssue(2863978);
			UNSEC_DeleteIssue(2863984);
			UNSEC_DeleteIssue(2863993);
			UNSEC_DeleteIssue(2864007);
			UNSEC_DeleteIssue(2864023);
			UNSEC_DeleteIssue(2864042);
			UNSEC_DeleteIssue(2864050);
			UNSEC_DeleteIssue(2864053);
			UNSEC_DeleteIssue(2864062);
			UNSEC_DeleteIssue(2864068);
			UNSEC_DeleteIssue(2864079);
			UNSEC_DeleteIssue(2864093);
			UNSEC_DeleteIssue(2864109);
			UNSEC_DeleteIssue(2864113);
			UNSEC_DeleteIssue(2864119);
			UNSEC_DeleteIssue(2864128);
			UNSEC_DeleteIssue(2864135);
			UNSEC_DeleteIssue(2864136);
			UNSEC_DeleteIssue(2864143);
			UNSEC_DeleteIssue(2864151);
			UNSEC_DeleteIssue(2864162);
			UNSEC_DeleteIssue(2864218);
			UNSEC_DeleteIssue(2864235);
			UNSEC_DeleteIssue(2864251);
			UNSEC_DeleteIssue(2864266);
			UNSEC_DeleteIssue(2864285);
			UNSEC_DeleteIssue(2864305);
			UNSEC_DeleteIssue(2864323);
			UNSEC_DeleteIssue(2864340);
			UNSEC_DeleteIssue(2864357);
			UNSEC_DeleteIssue(2864378);
			UNSEC_DeleteIssue(2864384);
			UNSEC_DeleteIssue(2864388);
			UNSEC_DeleteIssue(2864392);
			UNSEC_DeleteIssue(2864408);
			UNSEC_DeleteIssue(2864411);
			UNSEC_DeleteIssue(2864416);
			UNSEC_DeleteIssue(2864418);
			UNSEC_DeleteIssue(2864424);
			UNSEC_DeleteIssue(2864432);
			UNSEC_DeleteIssue(2864436);
			UNSEC_DeleteIssue(2864441);
			UNSEC_DeleteIssue(2864464);
			UNSEC_DeleteIssue(2864468);
			UNSEC_DeleteIssue(2864475);
			UNSEC_DeleteIssue(2864482);
			UNSEC_DeleteIssue(2864489);
			UNSEC_DeleteIssue(2864495);
			UNSEC_DeleteIssue(2864502);
			UNSEC_DeleteIssue(2864510);
			UNSEC_DeleteIssue(2864511);
			UNSEC_DeleteIssue(2864513);
			UNSEC_DeleteIssue(2864523);
			UNSEC_DeleteIssue(2864529);
			UNSEC_DeleteIssue(2864534);
			UNSEC_DeleteIssue(2864544);
			UNSEC_DeleteIssue(2864551);
			UNSEC_DeleteIssue(2864559);
			UNSEC_DeleteIssue(2864566);
			UNSEC_DeleteIssue(2864574);
			UNSEC_DeleteIssue(2864580);
			UNSEC_DeleteIssue(2864588);
			UNSEC_DeleteIssue(2864601);
			UNSEC_DeleteIssue(2864607);
			UNSEC_DeleteIssue(2864613);
			UNSEC_DeleteIssue(2864616);
			UNSEC_DeleteIssue(2864620);
			UNSEC_DeleteIssue(2864626);
			UNSEC_DeleteIssue(2864636);
			UNSEC_DeleteIssue(2864647);
			UNSEC_DeleteIssue(2864653);
			UNSEC_DeleteIssue(2864657);
			UNSEC_DeleteIssue(2864658);
			UNSEC_DeleteIssue(2864665);
			UNSEC_DeleteIssue(2864668);
			UNSEC_DeleteIssue(2864672);
			UNSEC_DeleteIssue(2864682);
			UNSEC_DeleteIssue(2864685);
			UNSEC_DeleteIssue(2864687);
			UNSEC_DeleteIssue(2864688);
			UNSEC_DeleteIssue(2864692);
			UNSEC_DeleteIssue(2864702);
			UNSEC_DeleteIssue(2864707);
			UNSEC_DeleteIssue(2864708);
			UNSEC_DeleteIssue(2864709);
			UNSEC_DeleteIssue(2864713);
			UNSEC_DeleteIssue(2864715);
			UNSEC_DeleteIssue(2864722);
			UNSEC_DeleteIssue(2864726);
			UNSEC_DeleteIssue(2864731);
			UNSEC_DeleteIssue(2864737);
			UNSEC_DeleteIssue(2864745);
			UNSEC_DeleteIssue(2864753);
			UNSEC_DeleteIssue(2864761);
			UNSEC_DeleteIssue(2864767);
			UNSEC_DeleteIssue(2864769);
			UNSEC_DeleteIssue(2864773);
			UNSEC_DeleteIssue(2864776);
			UNSEC_DeleteIssue(2864777);
			UNSEC_DeleteIssue(2864778);
			UNSEC_DeleteIssue(2864779);
			UNSEC_DeleteIssue(2864781);
			UNSEC_DeleteIssue(2864783);
			UNSEC_DeleteIssue(2864785);
			UNSEC_DeleteIssue(2864787);
			UNSEC_DeleteIssue(2864790);
			UNSEC_DeleteIssue(2864792);
			UNSEC_DeleteIssue(2864794);
			UNSEC_DeleteIssue(2864795);
			UNSEC_DeleteIssue(2864797);
			UNSEC_DeleteIssue(2864800);
			UNSEC_DeleteIssue(2864802);
			UNSEC_DeleteIssue(2864821);
			UNSEC_DeleteIssue(2864830);
			UNSEC_DeleteIssue(2864835);
			UNSEC_DeleteIssue(2864842);
			UNSEC_DeleteIssue(2864845);
			UNSEC_DeleteIssue(2864849);
			UNSEC_DeleteIssue(2864853);
			UNSEC_DeleteIssue(2864862);
			UNSEC_DeleteIssue(2864868);
			UNSEC_DeleteIssue(2864877);
			UNSEC_DeleteIssue(2864894);
			UNSEC_DeleteIssue(2864910);
			UNSEC_DeleteIssue(2864930);
			UNSEC_DeleteIssue(2864939);
			UNSEC_DeleteIssue(2864952);
			UNSEC_DeleteIssue(2864963);
			UNSEC_DeleteIssue(2864976);
			UNSEC_DeleteIssue(2864987);
			UNSEC_DeleteIssue(2865004);
			UNSEC_DeleteIssue(2865014);
			UNSEC_DeleteIssue(2865033);
			UNSEC_DeleteIssue(2865043);
			UNSEC_DeleteIssue(2865060);
			UNSEC_DeleteIssue(2865072);
			UNSEC_DeleteIssue(2865078);
			UNSEC_DeleteIssue(2865089);
			UNSEC_DeleteIssue(2865105);
			UNSEC_DeleteIssue(2865121);
			UNSEC_DeleteIssue(2865159);
			UNSEC_DeleteIssue(2865176);
			UNSEC_DeleteIssue(2865185);
			UNSEC_DeleteIssue(2865194);
			UNSEC_DeleteIssue(2865205);
			UNSEC_DeleteIssue(2865211);
			UNSEC_DeleteIssue(2865221);
			UNSEC_DeleteIssue(2865234);
			UNSEC_DeleteIssue(2865245);
			UNSEC_DeleteIssue(2865256);
			UNSEC_DeleteIssue(2865269);
			UNSEC_DeleteIssue(2865287);
			UNSEC_DeleteIssue(2865336);
			UNSEC_DeleteIssue(2865356);
			UNSEC_DeleteIssue(2865379);
			UNSEC_DeleteIssue(2865418);
			UNSEC_DeleteIssue(2865453);
			UNSEC_DeleteIssue(2865533);
			UNSEC_DeleteIssue(2865543);
			UNSEC_DeleteIssue(2865576);
			UNSEC_DeleteIssue(2865624);
			UNSEC_DeleteIssue(2865652);
			UNSEC_DeleteIssue(2865668);
			UNSEC_DeleteIssue(2865708);
			UNSEC_DeleteIssue(2865743);
			UNSEC_DeleteIssue(2865769);
			UNSEC_DeleteIssue(2865779);
			UNSEC_DeleteIssue(2865797);
			UNSEC_DeleteIssue(2865807);
			UNSEC_DeleteIssue(2865836);
			UNSEC_DeleteIssue(2865851);
			UNSEC_DeleteIssue(2865874);
			UNSEC_DeleteIssue(2865885);
			UNSEC_DeleteIssue(2865894);
			UNSEC_DeleteIssue(2865907);
			UNSEC_DeleteIssue(2865916);
			UNSEC_DeleteIssue(2865921);
			UNSEC_DeleteIssue(2865931);
			UNSEC_DeleteIssue(2865945);
			UNSEC_DeleteIssue(2865952);
			UNSEC_DeleteIssue(2865967);
			UNSEC_DeleteIssue(2865979);
			UNSEC_DeleteIssue(2865990);
			UNSEC_DeleteIssue(2866006);
			UNSEC_DeleteIssue(2866017);
			UNSEC_DeleteIssue(2866024);
			UNSEC_DeleteIssue(2866039);
			UNSEC_DeleteIssue(2866042);
			UNSEC_DeleteIssue(2866054);
			UNSEC_DeleteIssue(2866078);
			UNSEC_DeleteIssue(2866091);
			UNSEC_DeleteIssue(2866096);
			UNSEC_DeleteIssue(2866108);
			UNSEC_DeleteIssue(2866115);
			UNSEC_DeleteIssue(2866121);
			UNSEC_DeleteIssue(2866129);
			UNSEC_DeleteIssue(2866150);
			UNSEC_DeleteIssue(2866157);
			UNSEC_DeleteIssue(2866159);
			UNSEC_DeleteIssue(2866161);
			UNSEC_DeleteIssue(2866163);
			UNSEC_DeleteIssue(2866170);
			UNSEC_DeleteIssue(2866182);
			UNSEC_DeleteIssue(2866203);
			UNSEC_DeleteIssue(2866219);
			UNSEC_DeleteIssue(2866227);
			UNSEC_DeleteIssue(2866237);
			UNSEC_DeleteIssue(2866244);
			UNSEC_DeleteIssue(2866251);
			UNSEC_DeleteIssue(2866252);
			UNSEC_DeleteIssue(2866257);
			UNSEC_DeleteIssue(2866265);
			UNSEC_DeleteIssue(2866271);
			UNSEC_DeleteIssue(2866276);
			UNSEC_DeleteIssue(2866283);
			UNSEC_DeleteIssue(2866288);
			UNSEC_DeleteIssue(2866292);
			UNSEC_DeleteIssue(2866300);
			UNSEC_DeleteIssue(2866307);
			UNSEC_DeleteIssue(2866314);
			UNSEC_DeleteIssue(2866320);
			UNSEC_DeleteIssue(2866325);
			UNSEC_DeleteIssue(2866333);
			UNSEC_DeleteIssue(2866341);
			UNSEC_DeleteIssue(2866372);
			UNSEC_DeleteIssue(2866384);
			UNSEC_DeleteIssue(2866399);
			UNSEC_DeleteIssue(2866435);
			UNSEC_DeleteIssue(2866449);
			UNSEC_DeleteIssue(2866473);
			UNSEC_DeleteIssue(2866499);
			UNSEC_DeleteIssue(2866520);
			UNSEC_DeleteIssue(2866537);
			UNSEC_DeleteIssue(2866554);
			UNSEC_DeleteIssue(2866565);
			UNSEC_DeleteIssue(2866577);
			UNSEC_DeleteIssue(2866593);
			UNSEC_DeleteIssue(2866611);
			UNSEC_DeleteIssue(2866635);
			UNSEC_DeleteIssue(2866656);
			UNSEC_DeleteIssue(2866673);
			UNSEC_DeleteIssue(2866684);
			UNSEC_DeleteIssue(2866697);
			UNSEC_DeleteIssue(2866709);
			UNSEC_DeleteIssue(2866726);
			UNSEC_DeleteIssue(2866743);
			UNSEC_DeleteIssue(2866771);
			UNSEC_DeleteIssue(2866802);
			UNSEC_DeleteIssue(2866831);
			UNSEC_DeleteIssue(2866852);
			UNSEC_DeleteIssue(2866876);
			UNSEC_DeleteIssue(2866905);
			UNSEC_DeleteIssue(2866920);
			UNSEC_DeleteIssue(2866930);
			UNSEC_DeleteIssue(2866953);
			UNSEC_DeleteIssue(2866962);
			UNSEC_DeleteIssue(2866976);
			UNSEC_DeleteIssue(2866985);
			UNSEC_DeleteIssue(2866999);
			UNSEC_DeleteIssue(2867013);
			UNSEC_DeleteIssue(2867035);
			UNSEC_DeleteIssue(2867055);
			UNSEC_DeleteIssue(2867067);
			UNSEC_DeleteIssue(2867077);
			UNSEC_DeleteIssue(2867095);
			UNSEC_DeleteIssue(2867111);
			UNSEC_DeleteIssue(2867128);
			UNSEC_DeleteIssue(2867149);
			UNSEC_DeleteIssue(2867158);
			UNSEC_DeleteIssue(2867169);
			UNSEC_DeleteIssue(2867193);
			UNSEC_DeleteIssue(2867209);
			UNSEC_DeleteIssue(2867226);
			UNSEC_DeleteIssue(2867230);
			UNSEC_DeleteIssue(2867236);
			UNSEC_DeleteIssue(2867244);
			UNSEC_DeleteIssue(2867253);
			UNSEC_DeleteIssue(2867259);
			UNSEC_DeleteIssue(2867265);
			UNSEC_DeleteIssue(2867284);
			UNSEC_DeleteIssue(2867298);
			UNSEC_DeleteIssue(2867306);
			UNSEC_DeleteIssue(2867321);
			UNSEC_DeleteIssue(2867342);
			UNSEC_DeleteIssue(2867347);
			UNSEC_DeleteIssue(2867354);
			UNSEC_DeleteIssue(2867358);
			UNSEC_DeleteIssue(2867364);
			UNSEC_DeleteIssue(2867368);
			UNSEC_DeleteIssue(2867375);
			UNSEC_DeleteIssue(2867406);
			UNSEC_DeleteIssue(2867414);
			UNSEC_DeleteIssue(2867421);
			UNSEC_DeleteIssue(2867502);
			UNSEC_DeleteIssue(2867511);
			UNSEC_DeleteIssue(2867542);
			UNSEC_DeleteIssue(2867561);
			UNSEC_DeleteIssue(2867610);
			UNSEC_DeleteIssue(2867657);
			UNSEC_DeleteIssue(2867731);
			UNSEC_DeleteIssue(2867747);
			UNSEC_DeleteIssue(2867801);
			UNSEC_DeleteIssue(2867824);
			UNSEC_DeleteIssue(2867842);
			UNSEC_DeleteIssue(2867877);
			UNSEC_DeleteIssue(2867919);
			UNSEC_DeleteIssue(2867957);
			UNSEC_DeleteIssue(2868053);
			UNSEC_DeleteIssue(2868115);
			UNSEC_DeleteIssue(2868133);
			UNSEC_DeleteIssue(2868174);
			UNSEC_DeleteIssue(2868246);
			UNSEC_DeleteIssue(2868315);
			UNSEC_DeleteIssue(2868336);
			UNSEC_DeleteIssue(2868352);
			UNSEC_DeleteIssue(2868370);
			UNSEC_DeleteIssue(2868386);
			UNSEC_DeleteIssue(2868399);
			UNSEC_DeleteIssue(2868416);
			UNSEC_DeleteIssue(2868437);
			UNSEC_DeleteIssue(2868449);
			UNSEC_DeleteIssue(2868470);
			UNSEC_DeleteIssue(2868490);
			UNSEC_DeleteIssue(2868511);
			UNSEC_DeleteIssue(2868518);
			UNSEC_DeleteIssue(2868525);
			UNSEC_DeleteIssue(2868532);
			UNSEC_DeleteIssue(2868536);
			UNSEC_DeleteIssue(2868546);
			UNSEC_DeleteIssue(2868564);
			UNSEC_DeleteIssue(2868578);
			UNSEC_DeleteIssue(2868587);
			UNSEC_DeleteIssue(2868605);
			UNSEC_DeleteIssue(2868616);
			UNSEC_DeleteIssue(2868619);
			UNSEC_DeleteIssue(2868636);
			UNSEC_DeleteIssue(2868652);
			UNSEC_DeleteIssue(2868661);
			UNSEC_DeleteIssue(2868663);
			UNSEC_DeleteIssue(2868682);
			UNSEC_DeleteIssue(2868691);
			UNSEC_DeleteIssue(2868698);
			UNSEC_DeleteIssue(2868709);
			UNSEC_DeleteIssue(2868714);
			UNSEC_DeleteIssue(2868716);
			UNSEC_DeleteIssue(2868723);
			UNSEC_DeleteIssue(2868730);
			UNSEC_DeleteIssue(2868746);
			UNSEC_DeleteIssue(2868752);
			UNSEC_DeleteIssue(2868762);
			UNSEC_DeleteIssue(2868770);
			UNSEC_DeleteIssue(2868777);
			UNSEC_DeleteIssue(2868786);
			UNSEC_DeleteIssue(2868795);
			UNSEC_DeleteIssue(2868800);
			UNSEC_DeleteIssue(2868808);
			UNSEC_DeleteIssue(2868827);
			UNSEC_DeleteIssue(2868837);
			UNSEC_DeleteIssue(2868839);
			UNSEC_DeleteIssue(2868841);
			UNSEC_DeleteIssue(2868851);
			UNSEC_DeleteIssue(2868861);
			UNSEC_DeleteIssue(2868873);
			UNSEC_DeleteIssue(2868886);
			UNSEC_DeleteIssue(2868897);
			UNSEC_DeleteIssue(2868903);
			UNSEC_DeleteIssue(2868911);
			UNSEC_DeleteIssue(2868945);
			UNSEC_DeleteIssue(2868986);
			UNSEC_DeleteIssue(2868999);
			UNSEC_DeleteIssue(2869017);
			UNSEC_DeleteIssue(2869044);
			UNSEC_DeleteIssue(2869055);
			UNSEC_DeleteIssue(2869079);
			UNSEC_DeleteIssue(2869112);
			UNSEC_DeleteIssue(2869135);
			UNSEC_DeleteIssue(2869162);
			UNSEC_DeleteIssue(2869179);
			UNSEC_DeleteIssue(2869201);
			UNSEC_DeleteIssue(2869214);
			UNSEC_DeleteIssue(2869235);
			UNSEC_DeleteIssue(2869251);
			UNSEC_DeleteIssue(2869270);
			UNSEC_DeleteIssue(2869297);
			UNSEC_DeleteIssue(2869333);
			UNSEC_DeleteIssue(2869349);
			UNSEC_DeleteIssue(2869364);
			UNSEC_DeleteIssue(2869385);
			UNSEC_DeleteIssue(2869406);
			UNSEC_DeleteIssue(2869424);
			UNSEC_DeleteIssue(2869432);
			UNSEC_DeleteIssue(2869451);
			UNSEC_DeleteIssue(2869471);
			UNSEC_DeleteIssue(2869491);
			UNSEC_DeleteIssue(2869515);
			UNSEC_DeleteIssue(2869548);
			UNSEC_DeleteIssue(2869571);
			UNSEC_DeleteIssue(2869596);
			UNSEC_DeleteIssue(2869628);
			UNSEC_DeleteIssue(2869659);
			UNSEC_DeleteIssue(2869688);
			UNSEC_DeleteIssue(2869707);
			UNSEC_DeleteIssue(2869721);
			UNSEC_DeleteIssue(2869739);
			UNSEC_DeleteIssue(2869753);
			UNSEC_DeleteIssue(2869771);
			UNSEC_DeleteIssue(2869782);
			UNSEC_DeleteIssue(2869795);
			UNSEC_DeleteIssue(2869808);
			UNSEC_DeleteIssue(2869816);
			UNSEC_DeleteIssue(2869825);
			UNSEC_DeleteIssue(2869835);
			UNSEC_DeleteIssue(2869847);
			UNSEC_DeleteIssue(2869868);
			UNSEC_DeleteIssue(2869878);
			UNSEC_DeleteIssue(2869889);
			UNSEC_DeleteIssue(2869901);
			UNSEC_DeleteIssue(2869918);
			UNSEC_DeleteIssue(2869932);
			UNSEC_DeleteIssue(2869942);
			UNSEC_DeleteIssue(2869953);
			UNSEC_DeleteIssue(2869974);
			UNSEC_DeleteIssue(2869991);
			UNSEC_DeleteIssue(2869997);
			UNSEC_DeleteIssue(2870005);
			UNSEC_DeleteIssue(2870021);
			UNSEC_DeleteIssue(2870036);
			UNSEC_DeleteIssue(2870047);
			UNSEC_DeleteIssue(2870057);
			UNSEC_DeleteIssue(2870065);
			UNSEC_DeleteIssue(2870096);
			UNSEC_DeleteIssue(2870105);
			UNSEC_DeleteIssue(2870110);
			UNSEC_DeleteIssue(2870121);
			UNSEC_DeleteIssue(2870128);
			UNSEC_DeleteIssue(2870141);
			UNSEC_DeleteIssue(2870151);
			UNSEC_DeleteIssue(2870158);
			UNSEC_DeleteIssue(2870163);
			UNSEC_DeleteIssue(2870170);
			UNSEC_DeleteIssue(2870177);
			UNSEC_DeleteIssue(2870179);
			UNSEC_DeleteIssue(2870181);
			UNSEC_DeleteIssue(2870186);
			UNSEC_DeleteIssue(2870189);
			UNSEC_DeleteIssue(2870193);
			UNSEC_DeleteIssue(2870200);
			UNSEC_DeleteIssue(2870212);
			UNSEC_DeleteIssue(2870217);
			UNSEC_DeleteIssue(2870220);
			UNSEC_DeleteIssue(2870223);
			UNSEC_DeleteIssue(2870227);
			UNSEC_DeleteIssue(2870230);
			UNSEC_DeleteIssue(2870238);
			UNSEC_DeleteIssue(2870250);
			UNSEC_DeleteIssue(2870264);
			UNSEC_DeleteIssue(2870281);
			UNSEC_DeleteIssue(2870306);
			UNSEC_DeleteIssue(2870326);
			UNSEC_DeleteIssue(2870373);
			UNSEC_DeleteIssue(2870387);
			UNSEC_DeleteIssue(2870401);
			UNSEC_DeleteIssue(2870413);
			UNSEC_DeleteIssue(2870442);
			UNSEC_DeleteIssue(2870453);
			UNSEC_DeleteIssue(2870480);
			UNSEC_DeleteIssue(2870497);
			UNSEC_DeleteIssue(2870516);
			UNSEC_DeleteIssue(2870529);
			UNSEC_DeleteIssue(2870548);
			UNSEC_DeleteIssue(2870578);
			UNSEC_DeleteIssue(2870587);
			UNSEC_DeleteIssue(2870595);
			UNSEC_DeleteIssue(2870605);
			UNSEC_DeleteIssue(2870623);
			UNSEC_DeleteIssue(2870645);
			UNSEC_DeleteIssue(2870656);
			UNSEC_DeleteIssue(2870690);
			UNSEC_DeleteIssue(2870712);
			UNSEC_DeleteIssue(2870732);
			UNSEC_DeleteIssue(2870774);
			UNSEC_DeleteIssue(2870793);
			UNSEC_DeleteIssue(2870806);
			UNSEC_DeleteIssue(2870817);
			UNSEC_DeleteIssue(2870836);
			UNSEC_DeleteIssue(2870852);
			UNSEC_DeleteIssue(2870869);
			UNSEC_DeleteIssue(2870898);
			UNSEC_DeleteIssue(2870919);
			UNSEC_DeleteIssue(2870937);
			UNSEC_DeleteIssue(2870950);
			UNSEC_DeleteIssue(2870973);
			UNSEC_DeleteIssue(2870983);
			UNSEC_DeleteIssue(2871001);
			UNSEC_DeleteIssue(2871020);
			UNSEC_DeleteIssue(2871046);
			UNSEC_DeleteIssue(2871059);
			UNSEC_DeleteIssue(2871066);
			UNSEC_DeleteIssue(2871075);
			UNSEC_DeleteIssue(2871085);
			UNSEC_DeleteIssue(2871086);
			UNSEC_DeleteIssue(2871095);
			UNSEC_DeleteIssue(2871106);
			UNSEC_DeleteIssue(2871120);
			UNSEC_DeleteIssue(2871137);
			UNSEC_DeleteIssue(2871152);
			UNSEC_DeleteIssue(2871177);
			UNSEC_DeleteIssue(2871187);
			UNSEC_DeleteIssue(2871200);
			UNSEC_DeleteIssue(2871218);
			UNSEC_DeleteIssue(2871239);
			UNSEC_DeleteIssue(2871253);
			UNSEC_DeleteIssue(2871257);
			UNSEC_DeleteIssue(2871271);
			UNSEC_DeleteIssue(2871293);
			UNSEC_DeleteIssue(2871315);
			UNSEC_DeleteIssue(2871325);
			UNSEC_DeleteIssue(2871340);
			UNSEC_DeleteIssue(2871344);
			UNSEC_DeleteIssue(2871345);
			UNSEC_DeleteIssue(2871360);
			UNSEC_DeleteIssue(2871370);
			UNSEC_DeleteIssue(2871392);
			UNSEC_DeleteIssue(2871398);
			UNSEC_DeleteIssue(2871401);
			UNSEC_DeleteIssue(2871406);
			UNSEC_DeleteIssue(2871409);
			UNSEC_DeleteIssue(2871418);
			UNSEC_DeleteIssue(2871421);
			UNSEC_DeleteIssue(2871423);
			UNSEC_DeleteIssue(2871428);
			UNSEC_DeleteIssue(2871435);
			UNSEC_DeleteIssue(2871440);
			UNSEC_DeleteIssue(2871441);
			UNSEC_DeleteIssue(2871443);
			UNSEC_DeleteIssue(2871444);
			UNSEC_DeleteIssue(2871449);
			UNSEC_DeleteIssue(2871455);
			UNSEC_DeleteIssue(2871482);
			UNSEC_DeleteIssue(2871503);
			UNSEC_DeleteIssue(2871555);
			UNSEC_DeleteIssue(2871561);
			UNSEC_DeleteIssue(2871587);
			UNSEC_DeleteIssue(2871664);
			UNSEC_DeleteIssue(2871679);
			UNSEC_DeleteIssue(2871689);
			UNSEC_DeleteIssue(2871696);
			UNSEC_DeleteIssue(2871708);
			UNSEC_DeleteIssue(2871713);
			UNSEC_DeleteIssue(2871727);
			UNSEC_DeleteIssue(2871740);
			UNSEC_DeleteIssue(2871744);
			UNSEC_DeleteIssue(2871760);
			UNSEC_DeleteIssue(2871764);
			UNSEC_DeleteIssue(2871771);
			UNSEC_DeleteIssue(2871778);
			UNSEC_DeleteIssue(2871807);
			UNSEC_DeleteIssue(2871842);
			UNSEC_DeleteIssue(2871849);
			UNSEC_DeleteIssue(2871865);
			UNSEC_DeleteIssue(2871878);
			UNSEC_DeleteIssue(2871887);
			UNSEC_DeleteIssue(2871895);
			UNSEC_DeleteIssue(2871931);
			UNSEC_DeleteIssue(2871938);
			UNSEC_DeleteIssue(2871939);
			UNSEC_DeleteIssue(2871960);
			UNSEC_DeleteIssue(2871967);
			UNSEC_DeleteIssue(2871970);
			UNSEC_DeleteIssue(2871984);
			UNSEC_DeleteIssue(2871988);
			UNSEC_DeleteIssue(2872004);
			UNSEC_DeleteIssue(2872012);
			UNSEC_DeleteIssue(2872030);
			UNSEC_DeleteIssue(2872035);
			UNSEC_DeleteIssue(2872037);
			UNSEC_DeleteIssue(2872039);
			UNSEC_DeleteIssue(2872057);
			UNSEC_DeleteIssue(2872058);
			UNSEC_DeleteIssue(2872062);
			UNSEC_DeleteIssue(2872064);
			UNSEC_DeleteIssue(2872084);
			UNSEC_DeleteIssue(2872085);
			UNSEC_DeleteIssue(2872087);
			UNSEC_DeleteIssue(2872093);
			UNSEC_DeleteIssue(2872106);
			UNSEC_DeleteIssue(2872117);
			UNSEC_DeleteIssue(2872127);
			UNSEC_DeleteIssue(2872138);
			UNSEC_DeleteIssue(2872142);
			UNSEC_DeleteIssue(2872147);
			UNSEC_DeleteIssue(2872155);
			UNSEC_DeleteIssue(2872167);
			UNSEC_DeleteIssue(2872177);
			UNSEC_DeleteIssue(2872181);
			UNSEC_DeleteIssue(2872185);
			UNSEC_DeleteIssue(2872189);
			UNSEC_DeleteIssue(2872194);
			UNSEC_DeleteIssue(2872204);
			UNSEC_DeleteIssue(2872243);
			UNSEC_DeleteIssue(2872248);
			UNSEC_DeleteIssue(2872289);
			UNSEC_DeleteIssue(2872295);
			UNSEC_DeleteIssue(2872300);
			UNSEC_DeleteIssue(2872303);
			UNSEC_DeleteIssue(2872314);
			UNSEC_DeleteIssue(2872321);
			UNSEC_DeleteIssue(2872330);
			UNSEC_DeleteIssue(2872377);
			UNSEC_DeleteIssue(2872616);
			UNSEC_DeleteIssue(2872632);
			UNSEC_DeleteIssue(2872673);
			UNSEC_DeleteIssue(2872700);
			UNSEC_DeleteIssue(2872726);
			UNSEC_DeleteIssue(2872747);
			UNSEC_DeleteIssue(2872778);
			UNSEC_DeleteIssue(2872805);
			UNSEC_DeleteIssue(2872878);
			UNSEC_DeleteIssue(2872901);
			UNSEC_DeleteIssue(2872965);
			UNSEC_DeleteIssue(2873005);
			UNSEC_DeleteIssue(2873053);
			UNSEC_DeleteIssue(2873091);
			UNSEC_DeleteIssue(2873192);
			UNSEC_DeleteIssue(2873201);
			UNSEC_DeleteIssue(2873349);
			UNSEC_DeleteIssue(2873360);
			UNSEC_DeleteIssue(2873438);
			UNSEC_DeleteIssue(2873465);
			UNSEC_DeleteIssue(2873509);
			UNSEC_DeleteIssue(2873606);
			UNSEC_DeleteIssue(2873651);
			UNSEC_DeleteIssue(2873665);
			UNSEC_DeleteIssue(2873702);
			UNSEC_DeleteIssue(2873777);
			UNSEC_DeleteIssue(2900741);
			UNSEC_DeleteIssue(2921031);
			UNSEC_DeleteIssue(2921032);
			UNSEC_DeleteIssue(2965632);
			UNSEC_DeleteIssue(2965636);
			UNSEC_DeleteIssue(2965637);
			UNSEC_DeleteIssue(2965649);
			UNSEC_DeleteIssue(2965650);
			UNSEC_DeleteIssue(2965651);
			UNSEC_DeleteIssue(2965655);
			UNSEC_DeleteIssue(2965656);
			UNSEC_DeleteIssue(2965657);
			UNSEC_DeleteIssue(2965668);
			UNSEC_DeleteIssue(2965669);
			UNSEC_DeleteIssue(2965670);
			UNSEC_DeleteIssue(2965677);
			UNSEC_DeleteIssue(2965678);
			UNSEC_DeleteIssue(2965679);
			UNSEC_DeleteIssue(2965695);
			UNSEC_DeleteIssue(2965696);
			UNSEC_DeleteIssue(2965697);
			UNSEC_DeleteIssue(2965709);
			UNSEC_DeleteIssue(2965710);
			UNSEC_DeleteIssue(2965711);
			UNSEC_DeleteIssue(2965729);
			UNSEC_DeleteIssue(2965730);
			UNSEC_DeleteIssue(2965731);
			UNSEC_DeleteIssue(2965742);
			UNSEC_DeleteIssue(2965743);
			UNSEC_DeleteIssue(2965744);
			UNSEC_DeleteIssue(2965756);
			UNSEC_DeleteIssue(2965757);
			UNSEC_DeleteIssue(2965758);
			UNSEC_DeleteIssue(2965762);
			UNSEC_DeleteIssue(2965763);
			UNSEC_DeleteIssue(2965764);
			UNSEC_DeleteIssue(2965772);
			UNSEC_DeleteIssue(2965773);
			UNSEC_DeleteIssue(2965774);
			UNSEC_DeleteIssue(2965781);
			UNSEC_DeleteIssue(2965782);
			UNSEC_DeleteIssue(2965783);
			UNSEC_DeleteIssue(2965785);
			UNSEC_DeleteIssue(2965786);
			UNSEC_DeleteIssue(2965787);
			UNSEC_DeleteIssue(2965791);
			UNSEC_DeleteIssue(2965792);
			UNSEC_DeleteIssue(2965793);
			UNSEC_DeleteIssue(2965798);
			UNSEC_DeleteIssue(2965799);
			UNSEC_DeleteIssue(2965800);
			UNSEC_DeleteIssue(2965807);
			UNSEC_DeleteIssue(2965808);
			UNSEC_DeleteIssue(2965809);
			UNSEC_DeleteIssue(2965815);
			UNSEC_DeleteIssue(2965816);
			UNSEC_DeleteIssue(2965817);
			UNSEC_DeleteIssue(2965829);
			UNSEC_DeleteIssue(2965830);
			UNSEC_DeleteIssue(2965831);
			UNSEC_DeleteIssue(2965842);
			UNSEC_DeleteIssue(2965843);
			UNSEC_DeleteIssue(2965844);
			UNSEC_DeleteIssue(2965874);
			UNSEC_DeleteIssue(2965875);
			UNSEC_DeleteIssue(2965876);
			UNSEC_DeleteIssue(2965886);
			UNSEC_DeleteIssue(2965887);
			UNSEC_DeleteIssue(2965888);
			UNSEC_DeleteIssue(2965911);
			UNSEC_DeleteIssue(2965912);
			UNSEC_DeleteIssue(2965913);
			UNSEC_DeleteIssue(2965934);
			UNSEC_DeleteIssue(2965935);
			UNSEC_DeleteIssue(2965936);
			UNSEC_DeleteIssue(2966072);
			UNSEC_DeleteIssue(2966073);
			UNSEC_DeleteIssue(2966074);
			UNSEC_DeleteIssue(2966089);
			UNSEC_DeleteIssue(2966090);
			UNSEC_DeleteIssue(2966091);
			UNSEC_DeleteIssue(2966106);
			UNSEC_DeleteIssue(2966107);
			UNSEC_DeleteIssue(2966108);
			UNSEC_DeleteIssue(2966125);
			UNSEC_DeleteIssue(2966126);
			UNSEC_DeleteIssue(2966127);
			UNSEC_DeleteIssue(2966146);
			UNSEC_DeleteIssue(2966147);
			UNSEC_DeleteIssue(2966148);
			UNSEC_DeleteIssue(2966154);
			UNSEC_DeleteIssue(2966155);
			UNSEC_DeleteIssue(2966156);
			UNSEC_DeleteIssue(2966170);
			UNSEC_DeleteIssue(2966171);
			UNSEC_DeleteIssue(2966172);
			UNSEC_DeleteIssue(2966189);
			UNSEC_DeleteIssue(2966190);
			UNSEC_DeleteIssue(2966191);
			UNSEC_DeleteIssue(2966204);
			UNSEC_DeleteIssue(2966205);
			UNSEC_DeleteIssue(2966206);
			UNSEC_DeleteIssue(2966224);
			UNSEC_DeleteIssue(2966225);
			UNSEC_DeleteIssue(2966226);
			UNSEC_DeleteIssue(2966286);
			UNSEC_DeleteIssue(2966287);
			UNSEC_DeleteIssue(2966288);
			UNSEC_DeleteIssue(2966310);
			UNSEC_DeleteIssue(2966311);
			UNSEC_DeleteIssue(2966312);
			UNSEC_DeleteIssue(2966345);
			UNSEC_DeleteIssue(2966346);
			UNSEC_DeleteIssue(2966347);
			UNSEC_DeleteIssue(2966368);
			UNSEC_DeleteIssue(2966369);
			UNSEC_DeleteIssue(2966370);
			UNSEC_DeleteIssue(2966391);
			UNSEC_DeleteIssue(2966392);
			UNSEC_DeleteIssue(2966393);
			UNSEC_DeleteIssue(2966456);
			UNSEC_DeleteIssue(2966457);
			UNSEC_DeleteIssue(2966458);
			UNSEC_DeleteIssue(2966481);
			UNSEC_DeleteIssue(2966482);
			UNSEC_DeleteIssue(2966483);
			UNSEC_DeleteIssue(2966504);
			UNSEC_DeleteIssue(2966505);
			UNSEC_DeleteIssue(2966506);
			UNSEC_DeleteIssue(2966531);
			UNSEC_DeleteIssue(2966532);
			UNSEC_DeleteIssue(2966533);
			UNSEC_DeleteIssue(2966553);
			UNSEC_DeleteIssue(2966554);
			UNSEC_DeleteIssue(2966555);
			UNSEC_DeleteIssue(2966587);
			UNSEC_DeleteIssue(2966588);
			UNSEC_DeleteIssue(2966589);
			UNSEC_DeleteIssue(2966620);
			UNSEC_DeleteIssue(2966621);
			UNSEC_DeleteIssue(2966622);
			UNSEC_DeleteIssue(2966672);
			UNSEC_DeleteIssue(2966673);
			UNSEC_DeleteIssue(2966674);
			UNSEC_DeleteIssue(2966696);
			UNSEC_DeleteIssue(2966697);
			UNSEC_DeleteIssue(2966698);
			UNSEC_DeleteIssue(2966714);
			UNSEC_DeleteIssue(2966715);
			UNSEC_DeleteIssue(2966716);
			UNSEC_DeleteIssue(2966739);
			UNSEC_DeleteIssue(2966740);
			UNSEC_DeleteIssue(2966741);
			UNSEC_DeleteIssue(2966758);
			UNSEC_DeleteIssue(2966759);
			UNSEC_DeleteIssue(2966760);
			UNSEC_DeleteIssue(2966767);
			UNSEC_DeleteIssue(2966768);
			UNSEC_DeleteIssue(2966769);
			UNSEC_DeleteIssue(2966783);
			UNSEC_DeleteIssue(2966784);
			UNSEC_DeleteIssue(2966785);
			UNSEC_DeleteIssue(2966795);
			UNSEC_DeleteIssue(2966796);
			UNSEC_DeleteIssue(2966797);
			UNSEC_DeleteIssue(2966805);
			UNSEC_DeleteIssue(2966806);
			UNSEC_DeleteIssue(2966807);
			UNSEC_DeleteIssue(2966840);
			UNSEC_DeleteIssue(2966841);
			UNSEC_DeleteIssue(2966842);
			UNSEC_DeleteIssue(2966858);
			UNSEC_DeleteIssue(2966859);
			UNSEC_DeleteIssue(2966860);
			UNSEC_DeleteIssue(2966867);
			UNSEC_DeleteIssue(2966868);
			UNSEC_DeleteIssue(2966869);
			UNSEC_DeleteIssue(2966881);
			UNSEC_DeleteIssue(2966882);
			UNSEC_DeleteIssue(2966883);
			UNSEC_DeleteIssue(2966893);
			UNSEC_DeleteIssue(2966894);
			UNSEC_DeleteIssue(2966895);
			UNSEC_DeleteIssue(2966908);
			UNSEC_DeleteIssue(2966909);
			UNSEC_DeleteIssue(2966910);
			UNSEC_DeleteIssue(2966919);
			UNSEC_DeleteIssue(2966920);
			UNSEC_DeleteIssue(2966921);
			UNSEC_DeleteIssue(2966932);
			UNSEC_DeleteIssue(2966933);
			UNSEC_DeleteIssue(2966934);
			UNSEC_DeleteIssue(2966949);
			UNSEC_DeleteIssue(2966950);
			UNSEC_DeleteIssue(2966951);
			UNSEC_DeleteIssue(2966956);
			UNSEC_DeleteIssue(2966957);
			UNSEC_DeleteIssue(2966958);
			UNSEC_DeleteIssue(2966969);
			UNSEC_DeleteIssue(2966970);
			UNSEC_DeleteIssue(2966971);
			UNSEC_DeleteIssue(2966983);
			UNSEC_DeleteIssue(2966984);
			UNSEC_DeleteIssue(2966985);
			UNSEC_DeleteIssue(2966997);
			UNSEC_DeleteIssue(2966998);
			UNSEC_DeleteIssue(2966999);
			UNSEC_DeleteIssue(2967014);
			UNSEC_DeleteIssue(2967015);
			UNSEC_DeleteIssue(2967016);
			UNSEC_DeleteIssue(2967022);
			UNSEC_DeleteIssue(2967023);
			UNSEC_DeleteIssue(2967024);
			UNSEC_DeleteIssue(2967032);
			UNSEC_DeleteIssue(2967033);
			UNSEC_DeleteIssue(2967034);
			UNSEC_DeleteIssue(2967038);
			UNSEC_DeleteIssue(2967039);
			UNSEC_DeleteIssue(2967040);
			UNSEC_DeleteIssue(2967048);
			UNSEC_DeleteIssue(2967049);
			UNSEC_DeleteIssue(2967050);
			UNSEC_DeleteIssue(2967053);
			UNSEC_DeleteIssue(2967054);
			UNSEC_DeleteIssue(2967055);
			UNSEC_DeleteIssue(2967062);
			UNSEC_DeleteIssue(2967063);
			UNSEC_DeleteIssue(2967064);
			UNSEC_DeleteIssue(2967118);
			UNSEC_DeleteIssue(2967120);
			UNSEC_DeleteIssue(2967122);
			UNSEC_DeleteIssue(2995818);
			UNSEC_DeleteIssue(2995820);
			UNSEC_DeleteIssue(3019293);
			UNSEC_DeleteIssue(3019321);
			UNSEC_DeleteIssue(3019331);
			UNSEC_DeleteIssue(3019353);
			UNSEC_DeleteIssue(3019374);
			UNSEC_DeleteIssue(3019395);
			UNSEC_DeleteIssue(3019419);
			UNSEC_DeleteIssue(3019428);
			UNSEC_DeleteIssue(3019433);
			UNSEC_DeleteIssue(3019448);
			UNSEC_DeleteIssue(3019466);
			UNSEC_DeleteIssue(3019482);
			UNSEC_DeleteIssue(3019495);
			UNSEC_DeleteIssue(3019499);
			UNSEC_DeleteIssue(3019505);
			UNSEC_DeleteIssue(3019517);
			UNSEC_DeleteIssue(3019528);
			UNSEC_DeleteIssue(3019547);
			UNSEC_DeleteIssue(3019561);
			UNSEC_DeleteIssue(3019582);
			UNSEC_DeleteIssue(3019599);
			UNSEC_DeleteIssue(3019611);
			UNSEC_DeleteIssue(3019620);
			UNSEC_DeleteIssue(3019632);
			UNSEC_DeleteIssue(3019646);
			UNSEC_DeleteIssue(3019656);
			UNSEC_DeleteIssue(3019661);
			UNSEC_DeleteIssue(3019670);
			UNSEC_DeleteIssue(3019675);
			UNSEC_DeleteIssue(3019686);
			UNSEC_DeleteIssue(3019692);
			UNSEC_DeleteIssue(3019702);
			UNSEC_DeleteIssue(3019708);
			UNSEC_DeleteIssue(3019714);
			UNSEC_DeleteIssue(3019741);
			UNSEC_DeleteIssue(3019747);
			UNSEC_DeleteIssue(3019760);
			UNSEC_DeleteIssue(3019781);
			UNSEC_DeleteIssue(3019788);
			UNSEC_DeleteIssue(3019799);
			UNSEC_DeleteIssue(3019806);
			UNSEC_DeleteIssue(3019811);
			UNSEC_DeleteIssue(3019818);
			UNSEC_DeleteIssue(3019829);
			UNSEC_DeleteIssue(3019834);
			UNSEC_DeleteIssue(3019838);
			UNSEC_DeleteIssue(3019847);
			UNSEC_DeleteIssue(3019854);
			UNSEC_DeleteIssue(3019862);
			UNSEC_DeleteIssue(3019864);
			UNSEC_DeleteIssue(3019876);
			UNSEC_DeleteIssue(3019878);
			UNSEC_DeleteIssue(3019887);
			UNSEC_DeleteIssue(3019901);
			UNSEC_DeleteIssue(3019914);
			UNSEC_DeleteIssue(3019922);
			UNSEC_DeleteIssue(3019934);
			UNSEC_DeleteIssue(3019953);
			UNSEC_DeleteIssue(3019965);
			UNSEC_DeleteIssue(3019990);
			UNSEC_DeleteIssue(3020010);
			UNSEC_DeleteIssue(3020027);
			UNSEC_DeleteIssue(3020051);
			UNSEC_DeleteIssue(3020068);
			UNSEC_DeleteIssue(3020079);
			UNSEC_DeleteIssue(3020095);
			UNSEC_DeleteIssue(3020121);
			UNSEC_DeleteIssue(3020140);
			UNSEC_DeleteIssue(3020164);
			UNSEC_DeleteIssue(3020181);
			UNSEC_DeleteIssue(3020203);
			UNSEC_DeleteIssue(3020219);
			UNSEC_DeleteIssue(3020239);
			UNSEC_DeleteIssue(3020256);
			UNSEC_DeleteIssue(3020265);
			UNSEC_DeleteIssue(3020282);
			UNSEC_DeleteIssue(3020309);
			UNSEC_DeleteIssue(3020331);
			UNSEC_DeleteIssue(3020360);
			UNSEC_DeleteIssue(3020383);
			UNSEC_DeleteIssue(3020395);
			UNSEC_DeleteIssue(3020421);
			UNSEC_DeleteIssue(3020439);
			UNSEC_DeleteIssue(3020474);
			UNSEC_DeleteIssue(3020492);
			UNSEC_DeleteIssue(3020514);
			UNSEC_DeleteIssue(3020546);
			UNSEC_DeleteIssue(3020572);
			UNSEC_DeleteIssue(3020595);
			UNSEC_DeleteIssue(3020617);
			UNSEC_DeleteIssue(3020640);
			UNSEC_DeleteIssue(3020660);
			UNSEC_DeleteIssue(3020674);
			UNSEC_DeleteIssue(3020692);
			UNSEC_DeleteIssue(3020711);
			UNSEC_DeleteIssue(3020729);
			UNSEC_DeleteIssue(3020736);
			UNSEC_DeleteIssue(3020743);
			UNSEC_DeleteIssue(3020754);
			UNSEC_DeleteIssue(3020758);
			UNSEC_DeleteIssue(3020768);
			UNSEC_DeleteIssue(3020773);
			UNSEC_DeleteIssue(3020779);
			UNSEC_DeleteIssue(3020791);
			UNSEC_DeleteIssue(3020810);
			UNSEC_DeleteIssue(3020822);
			UNSEC_DeleteIssue(3020839);
			UNSEC_DeleteIssue(3020863);
			UNSEC_DeleteIssue(3020885);
			UNSEC_DeleteIssue(3020892);
			UNSEC_DeleteIssue(3020904);
			UNSEC_DeleteIssue(3020914);
			UNSEC_DeleteIssue(3020924);
			UNSEC_DeleteIssue(3020933);
			UNSEC_DeleteIssue(3020937);
			UNSEC_DeleteIssue(3020949);
			UNSEC_DeleteIssue(3020957);
			UNSEC_DeleteIssue(3020967);
			UNSEC_DeleteIssue(3020971);
			UNSEC_DeleteIssue(3020982);
			UNSEC_DeleteIssue(3020997);
			UNSEC_DeleteIssue(3021008);
			UNSEC_DeleteIssue(3021014);
			UNSEC_DeleteIssue(3021020);
			UNSEC_DeleteIssue(3021027);
			UNSEC_DeleteIssue(3021032);
			UNSEC_DeleteIssue(3021034);
			UNSEC_DeleteIssue(3021036);
			UNSEC_DeleteIssue(3021049);
			UNSEC_DeleteIssue(3021053);
			UNSEC_DeleteIssue(3021056);
			UNSEC_DeleteIssue(3021059);
			UNSEC_DeleteIssue(3021060);
			UNSEC_DeleteIssue(3021061);
			UNSEC_DeleteIssue(3021062);
			UNSEC_DeleteIssue(3021067);
			UNSEC_DeleteIssue(3021068);
			UNSEC_DeleteIssue(3021077);
			UNSEC_DeleteIssue(3021082);
			UNSEC_DeleteIssue(3021084);
			UNSEC_DeleteIssue(3021098);
			UNSEC_DeleteIssue(3021105);
			UNSEC_DeleteIssue(3021109);
			UNSEC_DeleteIssue(3021112);
			UNSEC_DeleteIssue(3021114);
			UNSEC_DeleteIssue(3021119);
			UNSEC_DeleteIssue(3021123);
			UNSEC_DeleteIssue(3021125);
			UNSEC_DeleteIssue(3021127);
			UNSEC_DeleteIssue(3021130);
			UNSEC_DeleteIssue(3021133);
			UNSEC_DeleteIssue(3021136);
			UNSEC_DeleteIssue(3021141);
			UNSEC_DeleteIssue(3021144);
			UNSEC_DeleteIssue(3021149);
			UNSEC_DeleteIssue(3021152);
			UNSEC_DeleteIssue(3021156);
			UNSEC_DeleteIssue(3021162);
			UNSEC_DeleteIssue(3021166);
			UNSEC_DeleteIssue(3021173);
			UNSEC_DeleteIssue(3021185);
			UNSEC_DeleteIssue(3021194);
			UNSEC_DeleteIssue(3021201);
			UNSEC_DeleteIssue(3021211);
			UNSEC_DeleteIssue(3021222);
			UNSEC_DeleteIssue(3021230);
			UNSEC_DeleteIssue(3021237);
			UNSEC_DeleteIssue(3021250);
			UNSEC_DeleteIssue(3021254);
			UNSEC_DeleteIssue(3021260);
			UNSEC_DeleteIssue(3021265);
			UNSEC_DeleteIssue(3021268);
			UNSEC_DeleteIssue(3021276);
			UNSEC_DeleteIssue(3021283);
			UNSEC_DeleteIssue(3021287);
			UNSEC_DeleteIssue(3021295);
			UNSEC_DeleteIssue(3021305);
			UNSEC_DeleteIssue(3021311);
			UNSEC_DeleteIssue(3021327);
			UNSEC_DeleteIssue(3021342);
			UNSEC_DeleteIssue(3021358);
			UNSEC_DeleteIssue(3021367);
			UNSEC_DeleteIssue(3021381);
			UNSEC_DeleteIssue(3021397);
			UNSEC_DeleteIssue(3021410);
			UNSEC_DeleteIssue(3021424);
			UNSEC_DeleteIssue(3021444);
			UNSEC_DeleteIssue(3021454);
			UNSEC_DeleteIssue(3021472);
			UNSEC_DeleteIssue(3021475);
			UNSEC_DeleteIssue(3021483);
			UNSEC_DeleteIssue(3021496);
			UNSEC_DeleteIssue(3021500);
			UNSEC_DeleteIssue(3021501);
			UNSEC_DeleteIssue(3021504);
			UNSEC_DeleteIssue(3021506);
			UNSEC_DeleteIssue(3021508);
			UNSEC_DeleteIssue(3021511);
			UNSEC_DeleteIssue(3021517);
			UNSEC_DeleteIssue(3021521);
			UNSEC_DeleteIssue(3021528);
			UNSEC_DeleteIssue(3021529);
			UNSEC_DeleteIssue(3021530);
			UNSEC_DeleteIssue(3021532);
			UNSEC_DeleteIssue(3021538);
			UNSEC_DeleteIssue(3021540);
			UNSEC_DeleteIssue(3021543);
			UNSEC_DeleteIssue(3021549);
			UNSEC_DeleteIssue(3021550);
			UNSEC_DeleteIssue(3021554);
			UNSEC_DeleteIssue(3021558);
			UNSEC_DeleteIssue(3021564);
			UNSEC_DeleteIssue(3021574);
			UNSEC_DeleteIssue(3021581);
			UNSEC_DeleteIssue(3021586);
			UNSEC_DeleteIssue(3021591);
			UNSEC_DeleteIssue(3021596);
			UNSEC_DeleteIssue(3021599);
			UNSEC_DeleteIssue(3021601);
			UNSEC_DeleteIssue(3021604);
			UNSEC_DeleteIssue(3021609);
			UNSEC_DeleteIssue(3021613);
			UNSEC_DeleteIssue(3021629);
			UNSEC_DeleteIssue(3021632);
			UNSEC_DeleteIssue(3021633);
			UNSEC_DeleteIssue(3021635);
			UNSEC_DeleteIssue(3021639);
			UNSEC_DeleteIssue(3021641);
			UNSEC_DeleteIssue(3021647);
			UNSEC_DeleteIssue(3021651);
			UNSEC_DeleteIssue(3021654);
			UNSEC_DeleteIssue(3021659);
			UNSEC_DeleteIssue(3021664);
			UNSEC_DeleteIssue(3021668);
			UNSEC_DeleteIssue(3021671);
			UNSEC_DeleteIssue(3021673);
			UNSEC_DeleteIssue(3021674);
			UNSEC_DeleteIssue(3021675);
			UNSEC_DeleteIssue(3021676);
			UNSEC_DeleteIssue(3021680);
			UNSEC_DeleteIssue(3021683);
			UNSEC_DeleteIssue(3021684);
			UNSEC_DeleteIssue(3021685);
			UNSEC_DeleteIssue(3021686);
			UNSEC_DeleteIssue(3021692);
			UNSEC_DeleteIssue(3021701);
			UNSEC_DeleteIssue(3021703);
			UNSEC_DeleteIssue(3021709);
			UNSEC_DeleteIssue(3021712);
			UNSEC_DeleteIssue(3021720);
			UNSEC_DeleteIssue(3021728);
			UNSEC_DeleteIssue(3021732);
			UNSEC_DeleteIssue(3021737);
			UNSEC_DeleteIssue(3021750);
			UNSEC_DeleteIssue(3021770);
			UNSEC_DeleteIssue(3021784);
			UNSEC_DeleteIssue(3021792);
			UNSEC_DeleteIssue(3021793);
			UNSEC_DeleteIssue(3021805);
			UNSEC_DeleteIssue(3021817);
			UNSEC_DeleteIssue(3021843);
			UNSEC_DeleteIssue(3021869);
			UNSEC_DeleteIssue(3021874);
			UNSEC_DeleteIssue(3021890);
			UNSEC_DeleteIssue(3021903);
			UNSEC_DeleteIssue(3021917);
			UNSEC_DeleteIssue(3021935);
			UNSEC_DeleteIssue(3021946);
			UNSEC_DeleteIssue(3021950);
			UNSEC_DeleteIssue(3021957);
			UNSEC_DeleteIssue(3021965);
			UNSEC_DeleteIssue(3021973);
			UNSEC_DeleteIssue(3021985);
			UNSEC_DeleteIssue(3021996);
			UNSEC_DeleteIssue(3022013);
			UNSEC_DeleteIssue(3022026);
			UNSEC_DeleteIssue(3022037);
			UNSEC_DeleteIssue(3022045);
			UNSEC_DeleteIssue(3022054);
			UNSEC_DeleteIssue(3022061);
			UNSEC_DeleteIssue(3022067);
			UNSEC_DeleteIssue(3022070);
			UNSEC_DeleteIssue(3022072);
			UNSEC_DeleteIssue(3022075);
			UNSEC_DeleteIssue(3022086);
			UNSEC_DeleteIssue(3022102);
			UNSEC_DeleteIssue(3022116);
			UNSEC_DeleteIssue(3022124);
			UNSEC_DeleteIssue(3022139);
			UNSEC_DeleteIssue(3022156);
			UNSEC_DeleteIssue(3022171);
			UNSEC_DeleteIssue(3022188);
			UNSEC_DeleteIssue(3022200);
			UNSEC_DeleteIssue(3022209);
			UNSEC_DeleteIssue(3022215);
			UNSEC_DeleteIssue(3022224);
			UNSEC_DeleteIssue(3022238);
			UNSEC_DeleteIssue(3022247);
			UNSEC_DeleteIssue(3022255);
			UNSEC_DeleteIssue(3022260);
			UNSEC_DeleteIssue(3022263);
			UNSEC_DeleteIssue(3022272);
			UNSEC_DeleteIssue(3022273);
			UNSEC_DeleteIssue(3022274);
			UNSEC_DeleteIssue(3022275);
			UNSEC_DeleteIssue(3022278);
			UNSEC_DeleteIssue(3022285);
			UNSEC_DeleteIssue(3022287);
			UNSEC_DeleteIssue(3022292);
			UNSEC_DeleteIssue(3022296);
			UNSEC_DeleteIssue(3022302);
			UNSEC_DeleteIssue(3022308);
			UNSEC_DeleteIssue(3022309);
			UNSEC_DeleteIssue(3022315);
			UNSEC_DeleteIssue(3022318);
			UNSEC_DeleteIssue(3022321);
			UNSEC_DeleteIssue(3022356);
			UNSEC_DeleteIssue(3022361);
			UNSEC_DeleteIssue(3022362);
			UNSEC_DeleteIssue(3022364);
			UNSEC_DeleteIssue(3022367);
			UNSEC_DeleteIssue(3022371);
			UNSEC_DeleteIssue(3022377);
			UNSEC_DeleteIssue(3022385);
			UNSEC_DeleteIssue(3022394);
			UNSEC_DeleteIssue(3022403);
			UNSEC_DeleteIssue(3022408);
			UNSEC_DeleteIssue(3022414);
			UNSEC_DeleteIssue(3022421);
			UNSEC_DeleteIssue(3022424);
			UNSEC_DeleteIssue(3022429);
			UNSEC_DeleteIssue(3022431);
			UNSEC_DeleteIssue(3022436);
			UNSEC_DeleteIssue(3022443);
			UNSEC_DeleteIssue(3022448);
			UNSEC_DeleteIssue(3022451);
			UNSEC_DeleteIssue(3022456);
			UNSEC_DeleteIssue(3022462);
			UNSEC_DeleteIssue(3022474);
			UNSEC_DeleteIssue(3022486);
			UNSEC_DeleteIssue(3022504);
			UNSEC_DeleteIssue(3022515);
			UNSEC_DeleteIssue(3022539);
			UNSEC_DeleteIssue(3022555);
			UNSEC_DeleteIssue(3022568);
			UNSEC_DeleteIssue(3022582);
			UNSEC_DeleteIssue(3022598);
			UNSEC_DeleteIssue(3022620);
			UNSEC_DeleteIssue(3022627);
			UNSEC_DeleteIssue(3022634);
			UNSEC_DeleteIssue(3022640);
			UNSEC_DeleteIssue(3022655);
			UNSEC_DeleteIssue(3022666);
			UNSEC_DeleteIssue(3022681);
			UNSEC_DeleteIssue(3022706);
			UNSEC_DeleteIssue(3022728);
			UNSEC_DeleteIssue(3022749);
			UNSEC_DeleteIssue(3022781);
			UNSEC_DeleteIssue(3022792);
			UNSEC_DeleteIssue(3022816);
			UNSEC_DeleteIssue(3022828);
			UNSEC_DeleteIssue(3022847);
			UNSEC_DeleteIssue(3022856);
			UNSEC_DeleteIssue(3022872);
			UNSEC_DeleteIssue(3022896);
			UNSEC_DeleteIssue(3022907);
			UNSEC_DeleteIssue(3022920);
			UNSEC_DeleteIssue(3022949);
			UNSEC_DeleteIssue(3022959);
			UNSEC_DeleteIssue(3022981);
			UNSEC_DeleteIssue(3023006);
			UNSEC_DeleteIssue(3023025);
			UNSEC_DeleteIssue(3023045);
			UNSEC_DeleteIssue(3023067);
			UNSEC_DeleteIssue(3023076);
			UNSEC_DeleteIssue(3023095);
			UNSEC_DeleteIssue(3023108);
			UNSEC_DeleteIssue(3023133);
			UNSEC_DeleteIssue(3023149);
			UNSEC_DeleteIssue(3023171);
			UNSEC_DeleteIssue(3023181);
			UNSEC_DeleteIssue(3023191);
			UNSEC_DeleteIssue(3023215);
			UNSEC_DeleteIssue(3023220);
			UNSEC_DeleteIssue(3023231);
			UNSEC_DeleteIssue(3023242);
			UNSEC_DeleteIssue(3023252);
			UNSEC_DeleteIssue(3023265);
			UNSEC_DeleteIssue(3023277);
			UNSEC_DeleteIssue(3023297);
			UNSEC_DeleteIssue(3023309);
			UNSEC_DeleteIssue(3023323);
			UNSEC_DeleteIssue(3023333);
			UNSEC_DeleteIssue(3023340);
			UNSEC_DeleteIssue(3023350);
			UNSEC_DeleteIssue(3023365);
			UNSEC_DeleteIssue(3023386);
			UNSEC_DeleteIssue(3023408);
			UNSEC_DeleteIssue(3023434);
			UNSEC_DeleteIssue(3023455);
			UNSEC_DeleteIssue(3023470);
			UNSEC_DeleteIssue(3023491);
			UNSEC_DeleteIssue(3023512);
			UNSEC_DeleteIssue(3023523);
			UNSEC_DeleteIssue(3023538);
			UNSEC_DeleteIssue(3023554);
			UNSEC_DeleteIssue(3023565);
			UNSEC_DeleteIssue(3023573);
			UNSEC_DeleteIssue(3023578);
			UNSEC_DeleteIssue(3023582);
			UNSEC_DeleteIssue(3023623);
			UNSEC_DeleteIssue(3050325);
			UNSEC_DeleteIssue(3183142);
			UNSEC_DeleteIssue(3183151);
			UNSEC_DeleteIssue(3183154);
			UNSEC_DeleteIssue(3183161);
			UNSEC_DeleteIssue(3183163);
			UNSEC_DeleteIssue(3183164);
			UNSEC_DeleteIssue(3183165);
			UNSEC_DeleteIssue(3183168);
			UNSEC_DeleteIssue(3183174);
			UNSEC_DeleteIssue(3183181);
			UNSEC_DeleteIssue(3183184);
			UNSEC_DeleteIssue(3183186);
			UNSEC_DeleteIssue(3183187);
			UNSEC_DeleteIssue(3183188);
			UNSEC_DeleteIssue(3183189);
			UNSEC_DeleteIssue(3183193);
			UNSEC_DeleteIssue(3183196);
			UNSEC_DeleteIssue(3183201);
			UNSEC_DeleteIssue(3183202);
			UNSEC_DeleteIssue(3183204);
			UNSEC_DeleteIssue(3183205);
			UNSEC_DeleteIssue(3183208);
			UNSEC_DeleteIssue(3183220);
			UNSEC_DeleteIssue(3183228);
			UNSEC_DeleteIssue(3183232);
			UNSEC_DeleteIssue(3183233);
			UNSEC_DeleteIssue(3183234);
			UNSEC_DeleteIssue(3183236);
			UNSEC_DeleteIssue(3183248);
			UNSEC_DeleteIssue(3183251);
			UNSEC_DeleteIssue(3183256);
			UNSEC_DeleteIssue(3183261);
			UNSEC_DeleteIssue(3183266);
			UNSEC_DeleteIssue(3183275);
			UNSEC_DeleteIssue(3183287);
			UNSEC_DeleteIssue(3183301);
			UNSEC_DeleteIssue(3183310);
			UNSEC_DeleteIssue(3183315);
			UNSEC_DeleteIssue(3183323);
			UNSEC_DeleteIssue(3183333);
			UNSEC_DeleteIssue(3183339);
			UNSEC_DeleteIssue(3183351);
			UNSEC_DeleteIssue(3183362);
			UNSEC_DeleteIssue(3183379);
			UNSEC_DeleteIssue(3183387);
			UNSEC_DeleteIssue(3183397);
			UNSEC_DeleteIssue(3183403);
			UNSEC_DeleteIssue(3183406);
			UNSEC_DeleteIssue(3183413);
			UNSEC_DeleteIssue(3183426);
			UNSEC_DeleteIssue(3183430);
			UNSEC_DeleteIssue(3183436);
			UNSEC_DeleteIssue(3183443);
			UNSEC_DeleteIssue(3183459);
			UNSEC_DeleteIssue(3183469);
			UNSEC_DeleteIssue(3183479);
			UNSEC_DeleteIssue(3183489);
			UNSEC_DeleteIssue(3183501);
			UNSEC_DeleteIssue(3183503);
			UNSEC_DeleteIssue(3183517);
			UNSEC_DeleteIssue(3183525);
			UNSEC_DeleteIssue(3183531);
			UNSEC_DeleteIssue(3183535);
			UNSEC_DeleteIssue(3183536);
			UNSEC_DeleteIssue(3183537);
			UNSEC_DeleteIssue(3183539);
			UNSEC_DeleteIssue(3183541);
			UNSEC_DeleteIssue(3183545);
			UNSEC_DeleteIssue(3183549);
			UNSEC_DeleteIssue(3183554);
			UNSEC_DeleteIssue(3183566);
			UNSEC_DeleteIssue(3183582);
			UNSEC_DeleteIssue(3183596);
			UNSEC_DeleteIssue(3183599);
			UNSEC_DeleteIssue(3183611);
			UNSEC_DeleteIssue(3183619);
			UNSEC_DeleteIssue(3183633);
			UNSEC_DeleteIssue(3183650);
			UNSEC_DeleteIssue(3183661);
			UNSEC_DeleteIssue(3183668);
			UNSEC_DeleteIssue(3183673);
			UNSEC_DeleteIssue(3183681);
			UNSEC_DeleteIssue(3183685);
			UNSEC_DeleteIssue(3183688);
			UNSEC_DeleteIssue(3183693);
			UNSEC_DeleteIssue(3183697);
			UNSEC_DeleteIssue(3183701);
			UNSEC_DeleteIssue(3183705);
			UNSEC_DeleteIssue(3183712);
			UNSEC_DeleteIssue(3183717);
			UNSEC_DeleteIssue(3183724);
			UNSEC_DeleteIssue(3183725);
			UNSEC_DeleteIssue(3183727);
			UNSEC_DeleteIssue(3183765);
			UNSEC_DeleteIssue(3212539);
		END;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
	v_acl_id				security.security_pkg.T_ACL_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer WHERE question_library_enabled = 1
		 )
	)
	LOOP
		BEGIN
		-- Create menu item
		security.menu_pkg.CreateMenu(
			in_act_id			=> v_act,
			in_parent_sid_id	=> security.securableobject_pkg.GetSIDFromPath(v_act, r.application_sid_id,'menu/setup'),
			in_name				=> 'csr_surveys_config',
			in_description		=> 'Surveys Config',
			in_action			=> '/csr/site/surveys/config.acds',
			in_pos				=> NULL,
			in_context			=> NULL,
			out_sid_id			=> v_sid
		);
		END;
	END LOOP;
END;
/
@latestUD4083_packages
DECLARE
	v_audit_msg VARCHAR2(1024);
	v_host		csr.customer.host%TYPE;
BEGIN	
	FOR r IN (
		SELECT DISTINCT imsi.ind_sid, imsi.app_sid
		  FROM csr.initiative_metric_state_ind imsi
		  JOIN csr.ind i ON imsi.ind_sid = i.ind_sid AND imsi.app_sid = i.app_sid
		  JOIN csr.aggregate_ind_group_member aigm ON aigm.ind_sid = imsi.ind_sid and aigm.app_sid = imsi.app_sid
		 WHERE (i.ind_type = 0 OR i.is_system_managed = 0)
		UNION
		SELECT DISTINCT imti.ind_sid, imti.app_sid
		  FROM csr.initiative_metric_tag_ind imti
		  JOIN csr.ind i ON imti.ind_sid = i.ind_sid AND imti.app_sid = i.app_sid
		  JOIN csr.aggregate_ind_group_member aigm ON aigm.ind_sid = imti.ind_sid and aigm.app_sid = imti.app_sid
		 WHERE (i.ind_type = 0 OR i.is_system_managed = 0)
	)
	LOOP
		SELECT host
		  INTO v_host
		  FROM csr.customer c
		 WHERE c.app_sid = r.app_sid;
		
		security.user_pkg.logonadmin(v_host);
		UPDATE csr.ind
		   SET ind_type = 3,
		       is_system_managed = 1
		 WHERE ind_sid = r.ind_sid;
		v_audit_msg := 'Set to system managed and ind type 3 (Initiative metric mapping correction: UD-4083).';
		
		csr.temp_csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_audit_type_id	=> 4,  --AUDIT_TYPE_CHANGE_SCHEMA
			in_app_sid			=> SYS_CONTEXT('SECURITY', 'APP'),
			in_object_sid		=> r.ind_sid,
			in_description		=> v_audit_msg
		);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
DROP PACKAGE csr.temp_csr_data_pkg;
DECLARE
	v_act		security.security_pkg.T_ACT_ID;
	v_sid		security.security_pkg.T_SID_ID;
	v_sag_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.measures', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
			BEGIN
				SELECT csr_user_sid
				INTO v_sag_sid
				FROM csr.csr_user
				WHERE r.application_sid_id = app_sid
				AND user_name = 'surveyauthorisedguest';
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, v_sag_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN NULL;
			END;
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/




CREATE OR REPLACE PACKAGE csr.credentials_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.credentials_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.credentials_pkg TO web_user;


@..\branding_pkg
@..\audit_pkg
@..\credentials_pkg
@..\automated_export_import_pkg
@..\indicator_pkg


@..\csr_user_body
@..\chain\company_user_body
@..\branding_body
@..\csrimp\imp_body
@..\audit_body
@..\enable_body
@..\credentials_body
@..\automated_export_import_body
@..\indicator_body
@..\initiative_metric_body
@..\site_name_management_body



@update_tail
