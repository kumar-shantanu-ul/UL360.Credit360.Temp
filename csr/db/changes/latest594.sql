-- Please update version.sql too -- this keeps clean builds in sync
define version=594
@update_header

set serveroutput on

declare
	v_wwwroot_sid number(10);
	v_site_sid number(10);
	v_pending_sid number(10);
	v_models_sid number(10);
	v_model_ashx_sid number(10);
begin
	user_pkg.LogonAdmin;

	for r in (select app_sid, host from csr.customer)
	loop
		security_pkg.SetApp(r.app_sid);
		
		begin
			v_wwwroot_sid := securableobject_pkg.GetSidFromPath(null, r.app_sid, 'wwwroot');
			v_site_sid := securableobject_pkg.GetSidFromPath(null, v_wwwroot_sid, 'csr/site');
			v_pending_sid := securableobject_pkg.GetSidFromPath(null, v_site_sid, 'pending');
		exception
			when security_pkg.object_not_found then
				v_pending_sid := null;
		end;

		if v_pending_sid is not null then
			dbms_output.put_line('Processing ' || r.host || ': copying pending permissions to model.ashx.');

			begin
				v_models_sid := securableobject_pkg.GetSidFromPath(null, v_site_sid, 'models');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_site_sid, 'models', v_models_sid);
			end;

			begin
				v_model_ashx_sid := securableobject_pkg.GetSidFromPath(null, v_models_sid, 'model.ashx');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_models_sid, 'model.ashx', v_model_ashx_sid);
			end;

			for a in (select sid_id, permission_set, ace_type, ace_flags from security.acl where acl_id = acl_pkg.GetDACLIDForSID(v_pending_sid) and bitand(ace_flags, bitwise_pkg.bitnot(security_pkg.ace_flag_inherited)) = ace_flags order by acl_index)
			loop
				acl_pkg.AddACE(sys_context('security', 'act'), acl_pkg.GetDACLIDForSID(v_model_ashx_sid), security_pkg.ACL_INDEX_LAST, a.ace_type, a.ace_flags, a.sid_id, a.permission_set);
			end loop;
		else
			dbms_output.put_line('Skipping ' || r.host || ': no pending permissions found.');
		end if;
	end loop;
end;
/

/* Results from running on live:

================== VERSION 594 ========================
PL/SQL procedure successfully completed.
Skipping www.whistler2020.ca: no pending permissions found.
Skipping sergio.credit360.com: no pending permissions found.
Skipping csrnetwork.credit360.com: no pending permissions found.
Skipping mectest.credit360.com: no pending permissions found.
Processing sarab.credit360.com: copying pending permissions to model.ashx.
Skipping rwe.test.credit360.com: no pending permissions found.
Skipping starbucks.test.credit360.com: no pending permissions found.
Processing www.credit360.com: copying pending permissions to model.ashx.
Processing sara.credit360.com: copying pending permissions to model.ashx.
Skipping ngt.credit360.com: no pending permissions found.
Skipping sr-online.credit360.com: no pending permissions found.
Skipping xyz.credit360.com: no pending permissions found.
Skipping jlpdemo.flagcsr.co.uk: no pending permissions found.
Skipping boots.credit360.com: no pending permissions found.
Skipping chevron.credit360.com: no pending permissions found.
Skipping rwe.credit360.com: no pending permissions found.
Skipping mtn.credit360.com: no pending permissions found.
Skipping itv.credit360.com: no pending permissions found.
Processing telekom-internal.credit360.com: copying pending permissions to model.ashx.
Processing otto2.credit360.com: copying pending permissions to model.ashx.
Skipping mangroup.credit360.com: no pending permissions found.
Skipping rsa.credit360.com: no pending permissions found.
Skipping 2012.credit360.com: no pending permissions found.
Skipping cairnindia.credit360.com: no pending permissions found.
Skipping test-britishland.credit360.com: no pending permissions found.
Skipping test.mcdonalds.credit360.com: no pending permissions found.
Skipping charlotte.credit360.com: no pending permissions found.
Skipping testhsbc.credit360.com: no pending permissions found.
Skipping example.credit360.com: no pending permissions found.
Skipping test-essent.credit360.com: no pending permissions found.
Processing vancity.credit360.com: copying pending permissions to model.ashx.
Processing trucost.credit360.com: copying pending permissions to model.ashx.
Skipping goahead.credit360.com: no pending permissions found.
Skipping christina.credit360.com: no pending permissions found.
Processing marksandspencer.credit360.com: copying pending permissions to model.ashx.
Skipping gsskpmg.credit360.com: no pending permissions found.
Skipping hsbc.credit360.com: no pending permissions found.
Skipping telefonica.test.credit360.com: no pending permissions found.
Skipping auditorslinde2.credit360.com: no pending permissions found.
Skipping virginunite.credit360.com: no pending permissions found.
Skipping vtplc.credit360.com: no pending permissions found.
Skipping reuters.credit360.com: no pending permissions found.
Skipping itvtest.credit360.com: no pending permissions found.
Skipping francesca.credit360.com: no pending permissions found.
Skipping produceworldtest.credit360.com: no pending permissions found.
Skipping cairntest.credit360.com: no pending permissions found.
Processing rbsinitiatives.credit360.com: copying pending permissions to model.ashx.
Skipping old-demo.credit360.com: no pending permissions found.
Skipping banarra.credit360.com: no pending permissions found.
Skipping nmg.credit360.com: no pending permissions found.
Skipping scottish-newcastle.credit360.com: no pending permissions found.
Skipping prudential.credit360.com: no pending permissions found.
Skipping corporateedge.credit360.com: no pending permissions found.
Processing juniper.credit360.com: copying pending permissions to model.ashx.
Skipping picknpay.credit360.com: no pending permissions found.
Processing cairn.credit360.com: copying pending permissions to model.ashx.
Processing aviva_old.credit360.com: copying pending permissions to model.ashx.
Skipping scottishpower.credit360.com: no pending permissions found.
Skipping mcdonalds.credit360.com: no pending permissions found.
Processing praxair.credit360.com: copying pending permissions to model.ashx.
Skipping hsbc.test.credit360.com: no pending permissions found.
Skipping scottishpowertest.credit360.com: no pending permissions found.
Skipping upstream.credit360.com: no pending permissions found.
Skipping virginmedia.credit360.com: no pending permissions found.
Skipping rbstest.credit360.com: no pending permissions found.
Skipping telefonica-old.credit360.com: no pending permissions found.
Skipping t-mobile.credit360.com: no pending permissions found.
Skipping allianceboots.credit360.com: no pending permissions found.
Skipping johnsondiversey.credit360.com: no pending permissions found.
Skipping emil2.credit360.com: no pending permissions found.
Skipping bootssupplier.credit360.com: no pending permissions found.
Skipping cliffordchance.credit360.com: no pending permissions found.
Skipping mcd2.credit360.com: no pending permissions found.
Processing ing.credit360.com: copying pending permissions to model.ashx.
Skipping iadb.credit360.com: no pending permissions found.
Skipping therightstep.co.uk: no pending permissions found.
Skipping telekom.credit360.com: no pending permissions found.
Skipping segro.credit360.com: no pending permissions found.
Skipping worldbank.credit360.com: no pending permissions found.
Skipping vodaphone.credit360.com: no pending permissions found.
Processing london2012ali.credit360.com: copying pending permissions to model.ashx.
Skipping firstgroup.credit360.com: no pending permissions found.
Skipping old-intertek.credit360.com: no pending permissions found.
Skipping hrg.credit360.com: no pending permissions found.
Skipping natura.credit360.com: no pending permissions found.
Processing experian.credit360.com: copying pending permissions to model.ashx.
Skipping vodafone.credit360.com: no pending permissions found.
Processing tmater.credit360.com: copying pending permissions to model.ashx.
Processing heineken.credit360.com: copying pending permissions to model.ashx.
Processing wendy.credit360.com: copying pending permissions to model.ashx.
Processing sheila.credit360.com: copying pending permissions to model.ashx.
Processing elektro.credit360.com: copying pending permissions to model.ashx.
Processing menno.credit360.com: copying pending permissions to model.ashx.
Processing computershare.credit360.com: copying pending permissions to model.ashx.
Skipping htw.credit360.com: no pending permissions found.
Processing telekomtest.credit360.com: copying pending permissions to model.ashx.
Processing mtr-demo.credit360.com: copying pending permissions to model.ashx.
Skipping co2.credit360.com: no pending permissions found.
Skipping ml.credit360.com: no pending permissions found.
Skipping yvr.credit360.com: no pending permissions found.
Processing bat.credit360.com: copying pending permissions to model.ashx.
Skipping eontest.credit360.com: no pending permissions found.
Skipping crestnicholson.credit360.com: no pending permissions found.
Skipping lindetest.credit360.com: no pending permissions found.
Skipping kpmgtest.credit360.com: no pending permissions found.
Skipping aconacmg.credit360.com: no pending permissions found.
Processing na.credit360.com: copying pending permissions to model.ashx.
Skipping thematrix.credit360.com: no pending permissions found.
Skipping puertos.credit360.com: no pending permissions found.
Skipping cc.credit360.com: no pending permissions found.
Processing lacaixa.credit360.com: copying pending permissions to model.ashx.
Skipping pepsico.credit360.com: no pending permissions found.
Skipping re.credit360.com: no pending permissions found.
Skipping test.mangroup.credit360.com: no pending permissions found.
Skipping huntstock.credit360.com: no pending permissions found.
Skipping acona.credit360.com: no pending permissions found.
Skipping novonordisk.credit360.com: no pending permissions found.
Processing fabian.credit360.com: copying pending permissions to model.ashx.
Processing africanbank.credit360.com: copying pending permissions to model.ashx.
Processing danskebank.credit360.com: copying pending permissions to model.ashx.
Processing london2012test.credit360.com: copying pending permissions to model.ashx.
Skipping tata.credit360.com: no pending permissions found.
Skipping climatesmart.credit360.com: no pending permissions found.
Skipping kyle.credit360.com: no pending permissions found.
Processing repsol.credit360.com: copying pending permissions to model.ashx.
Processing impress.credit360.com: copying pending permissions to model.ashx.
Skipping dev.credit360.com: no pending permissions found.
Skipping sa.credit360.com: no pending permissions found.
Skipping daniel.credit360.com: no pending permissions found.
Processing mcdonalds-global.credit360.com: copying pending permissions to model.ashx.
Processing bae.credit360.com: copying pending permissions to model.ashx.
Processing westpacsupplier.credit360.com: copying pending permissions to model.ashx.
Processing aviva.credit360.com: copying pending permissions to model.ashx.
Processing telefonica.credit360.com: copying pending permissions to model.ashx.
Skipping ica.credit360.com: no pending permissions found.
Skipping rbs.credit360.com: no pending permissions found.
Skipping iberdrola.credit360.com: no pending permissions found.
Processing linde.credit360.com: copying pending permissions to model.ashx.
Skipping atkins.credit360.com: no pending permissions found.
Skipping alistair.credit360.com: no pending permissions found.
Processing starbucks.credit360.com: copying pending permissions to model.ashx.
Skipping abtest.credit360.com: no pending permissions found.
Skipping fnb.credit360.com: no pending permissions found.
Skipping britishland.credit360.com: no pending permissions found.
Skipping cbi.credit360.com: no pending permissions found.
Skipping pronino.credit360.com: no pending permissions found.
Processing mec.credit360.com: copying pending permissions to model.ashx.
Skipping vancity-test.credit360.com: no pending permissions found.
Skipping rbsenv.credit360.com: no pending permissions found.
Skipping eon.credit360.com: no pending permissions found.
Skipping bootstest.credit360.com: no pending permissions found.
Skipping scaa.credit360.com: no pending permissions found.
Skipping t-mobile-test.credit360.com: no pending permissions found.
Skipping kerry.credit360.com: no pending permissions found.
Processing telekom2.credit360.com: copying pending permissions to model.ashx.
Skipping james.credit360.com: no pending permissions found.
Skipping produceworld.credit360.com: no pending permissions found.
Skipping crh.credit360.com: no pending permissions found.
Skipping centrica.credit360.com: no pending permissions found.
Processing chaininfo.credit360.com: copying pending permissions to model.ashx.
Skipping helena.credit360.com: no pending permissions found.
Processing new.credit360.com: copying pending permissions to model.ashx.
Processing copersucar.credit360.com: copying pending permissions to model.ashx.
Processing australia.credit360.com: copying pending permissions to model.ashx.
Processing london2012sue.credit360.com: copying pending permissions to model.ashx.
Processing westpacngers.credit360.com: copying pending permissions to model.ashx.
Processing test-swissre.credit360.com: copying pending permissions to model.ashx.
Processing mattel-demo.credit360.com: copying pending permissions to model.ashx.
Processing ghgi.credit360.com: copying pending permissions to model.ashx.
Processing tjx.credit360.com: copying pending permissions to model.ashx.
Processing hornery-demo.credit360.com: copying pending permissions to model.ashx.
Processing dbcom.credit360.com: copying pending permissions to model.ashx.
Processing energywholesale.credit360.com: copying pending permissions to model.ashx.
Processing otto.credit360.com: copying pending permissions to model.ashx.
Processing hs.credit360.com: copying pending permissions to model.ashx.
Processing arcelormittal.credit360.com: copying pending permissions to model.ashx.
Processing swissre09.credit360.com: copying pending permissions to model.ashx.
Processing alexis.credit360.com: copying pending permissions to model.ashx.
Skipping imi.credit360.com: no pending permissions found.
Processing skytest.credit360.com: copying pending permissions to model.ashx.
Processing pentest.credit360.com: copying pending permissions to model.ashx.
Processing maosheng.credit360.com: copying pending permissions to model.ashx.
Skipping jaguar.credit360.com: no pending permissions found.
Skipping tf5.credit360.com: no pending permissions found.
Processing stockland.credit360.com: copying pending permissions to model.ashx.
Skipping tr.credit360.com: no pending permissions found.
Processing london2012.credit360.com: copying pending permissions to model.ashx.
Skipping frederic.credit360.com: no pending permissions found.
Processing otto-demo.credit360.com: copying pending permissions to model.ashx.
Processing halcrow-sales.credit360.com: copying pending permissions to model.ashx.
Skipping survey.credit360.com: no pending permissions found.
Processing sc.credit360.com: copying pending permissions to model.ashx.
Processing westpac.credit360.com: copying pending permissions to model.ashx.
Processing pwc.credit360.com: copying pending permissions to model.ashx.
Skipping rbsenvtest.credit360.com: no pending permissions found.
Processing pb.credit360.com: copying pending permissions to model.ashx.
Processing dansketest.credit360.com: copying pending permissions to model.ashx.
Processing sdb.credit360.com: copying pending permissions to model.ashx.
Processing rweimp.credit360.com: copying pending permissions to model.ashx.
Processing brdemo.credit360.com: copying pending permissions to model.ashx.
Processing jmfamily.credit360.com: copying pending permissions to model.ashx.
Processing staples-old.credit360.com: copying pending permissions to model.ashx.
Processing livemarketing.credit360.com: copying pending permissions to model.ashx.
Processing e-valuation.credit360.com: copying pending permissions to model.ashx.
Processing mapfre.credit360.com: copying pending permissions to model.ashx.
Processing brakes.credit360.com: copying pending permissions to model.ashx.
Processing mace.credit360.com: copying pending permissions to model.ashx.
Skipping barclays.credit360.com: no pending permissions found.
Processing burberry.credit360.com: copying pending permissions to model.ashx.
Processing danny.credit360.com: copying pending permissions to model.ashx.
Processing intertek.credit360.com: copying pending permissions to model.ashx.
Processing axelspringer.credit360.com: copying pending permissions to model.ashx.
Processing base.credit360.com: copying pending permissions to model.ashx.
Processing hornery.credit360.com: copying pending permissions to model.ashx.
Processing amwater.credit360.com: copying pending permissions to model.ashx.
Processing maersk.credit360.com: copying pending permissions to model.ashx.
Processing otto-heidi.credit360.com: copying pending permissions to model.ashx.
Processing ladbrokes.credit360.com: copying pending permissions to model.ashx.
Processing transtemp.credit360.com: copying pending permissions to model.ashx.
Processing auditorslinde.credit360.com: copying pending permissions to model.ashx.
Processing rainforestalliance.credit360.com: copying pending permissions to model.ashx.
Processing rag.credit360.com: copying pending permissions to model.ashx.
Processing signe.credit360.com: copying pending permissions to model.ashx.
Processing jmfdemo.credit360.com: copying pending permissions to model.ashx.
Processing frontenac.credit360.com: copying pending permissions to model.ashx.
Processing locog.credit360.com: copying pending permissions to model.ashx.
Skipping essentcopy.credit360.com: no pending permissions found.
Processing chaindemo.credit360.com: copying pending permissions to model.ashx.
Processing lcw.credit360.com: copying pending permissions to model.ashx.
Skipping test.imi.credit360.com: no pending permissions found.
Processing swissre.credit360.com: copying pending permissions to model.ashx.
Processing alphabank.credit360.com: copying pending permissions to model.ashx.
Processing db2.credit360.com: copying pending permissions to model.ashx.
Processing ingtest.credit360.com: copying pending permissions to model.ashx.
Skipping bestbuy.credit360.com: no pending permissions found.
Skipping essent.credit360.com: no pending permissions found.
Processing db.credit360.com: copying pending permissions to model.ashx.
Processing xstrata.credit360.com: copying pending permissions to model.ashx.
Processing freshfields.credit360.com: copying pending permissions to model.ashx.
Processing ironmountain.credit360.com: copying pending permissions to model.ashx.
Processing supplier-risk@credit360.com: copying pending permissions to model.ashx.
Processing imperial.credit360.com: copying pending permissions to model.ashx.
Processing amita.credit360.com: copying pending permissions to model.ashx.
Processing aswatson.credit360.com: copying pending permissions to model.ashx.
Processing hammerson.credit360.com: copying pending permissions to model.ashx.
Processing grontmij.credit360.com: copying pending permissions to model.ashx.
Processing aviva-test.credit360.com: copying pending permissions to model.ashx.
Processing crdemo.credit360.com: copying pending permissions to model.ashx.
Processing yara.credit360.com: copying pending permissions to model.ashx.
Processing tiffany-old.credit360.com: copying pending permissions to model.ashx.
Processing cg.credit360.com: copying pending permissions to model.ashx.
Processing prologis.credit360.com: copying pending permissions to model.ashx.
Processing westpac-test.credit360.com: copying pending permissions to model.ashx.
Processing otto-test.credit360.com: copying pending permissions to model.ashx.
Processing fiep.credit360.com: copying pending permissions to model.ashx.
Processing uniq.credit360.com: copying pending permissions to model.ashx.
Processing owltest.credit360.com: copying pending permissions to model.ashx.
Processing starbucks-gr.credit360.com: copying pending permissions to model.ashx.
Processing betfair.credit360.com: copying pending permissions to model.ashx.
Processing camargocorrea.credit360.com: copying pending permissions to model.ashx.
Processing itau.credit360.com: copying pending permissions to model.ashx.
Processing mattel.credit360.com: copying pending permissions to model.ashx.
Processing mwh.credit360.com: copying pending permissions to model.ashx.
Processing experian-test.credit360.com: copying pending permissions to model.ashx.
Processing npsl.co.uk: copying pending permissions to model.ashx.
Processing philips-supplier.credit360.com: copying pending permissions to model.ashx.
Processing energywholesaletest.credit360.com: copying pending permissions to model.ashx.
Processing greenmountainenergy.credit360.com: copying pending permissions to model.ashx.
Processing sempra-sales.credit360.com: copying pending permissions to model.ashx.
Skipping iadb-test.credit360.com: no pending permissions found.
Processing rmenergy.credit360.com: copying pending permissions to model.ashx.
Processing imperialcdp.credit360.com: copying pending permissions to model.ashx.
Processing intertek1.credit360.com: copying pending permissions to model.ashx.
Processing evaluationcr360.credit360.com: copying pending permissions to model.ashx.
Processing homedepot.credit360.com: copying pending permissions to model.ashx.
Processing huaneng.credit360.com: copying pending permissions to model.ashx.
Processing mace-test.credit360.com: copying pending permissions to model.ashx.
Processing cermaq-sales.credit360.com: copying pending permissions to model.ashx.
Processing benelux.credit360.com: copying pending permissions to model.ashx.
Processing isi.credit360.com: copying pending permissions to model.ashx.
Processing csresolutions.credit360.com: copying pending permissions to model.ashx.
Processing heh.credit360.com: copying pending permissions to model.ashx.
Processing demo.credit360.com: copying pending permissions to model.ashx.
Processing supplier-risk.credit360.com: copying pending permissions to model.ashx.
Processing nationalgrid.credit360.com: copying pending permissions to model.ashx.
Processing nacrdemo.credit360.com: copying pending permissions to model.ashx.
Processing starbucks-gr2.credit360.com: copying pending permissions to model.ashx.
Processing debeers.credit360.com: copying pending permissions to model.ashx.
Processing mattelNew.credit360.com: copying pending permissions to model.ashx.
Processing santander.credit360.com: copying pending permissions to model.ashx.
Processing gamesa.credit360.com: copying pending permissions to model.ashx.
Processing mtr.credit360.com: copying pending permissions to model.ashx.
Processing volkerwessels.credit360.com: copying pending permissions to model.ashx.
Processing cbidemo.credit360.com: copying pending permissions to model.ashx.
Processing kpmg-us.credit360.com: copying pending permissions to model.ashx.
Processing cermaq.credit360.com: copying pending permissions to model.ashx.
Processing diana.credit360.com: copying pending permissions to model.ashx.
Skipping gmcr.credit360.com: no pending permissions found.
Skipping alliancebootstest.credit360.com: no pending permissions found.
Processing td.credit360.com: copying pending permissions to model.ashx.
Processing ipfin.credit360.com: copying pending permissions to model.ashx.
Skipping test.credit360.com: no pending permissions found.
Processing pge.credit360.com: copying pending permissions to model.ashx.
Skipping sky.credit360.com: no pending permissions found.
Processing markit.credit360.com: copying pending permissions to model.ashx.
Processing chipotle.credit360.com: copying pending permissions to model.ashx.
Processing phillips-uk.credit360.com: copying pending permissions to model.ashx.
Processing mothercare.credit360.com: copying pending permissions to model.ashx.
Processing logica.credit360.com: copying pending permissions to model.ashx.
Processing huawei.credit360.com: copying pending permissions to model.ashx.
Processing dsnorden.credit360.com: copying pending permissions to model.ashx.
Processing staples.credit360.com: copying pending permissions to model.ashx.
Processing gpf.credit360.com: copying pending permissions to model.ashx.
Processing crc.credit360.com: copying pending permissions to model.ashx.
Processing heidi.credit360.com: copying pending permissions to model.ashx.
Processing o2-uk.credit360.com: copying pending permissions to model.ashx.
Processing gf.credit360.com: copying pending permissions to model.ashx.
Processing oldmutual.credit360.com: copying pending permissions to model.ashx.
Processing philips.credit360.com: copying pending permissions to model.ashx.
Processing yaratest.credit360.com: copying pending permissions to model.ashx.
Processing ali.credit360.com: copying pending permissions to model.ashx.
Processing sempra.credit360.com: copying pending permissions to model.ashx.
Processing staplestest.credit360.com: copying pending permissions to model.ashx.
Processing sempra-test.credit360.com: copying pending permissions to model.ashx.
Processing diana2.credit360.com: copying pending permissions to model.ashx.
Processing luisamf.credit360.com: copying pending permissions to model.ashx.
Processing lloyds.credit360.com: copying pending permissions to model.ashx.
Processing eicc.credit360.com: copying pending permissions to model.ashx.
Processing constructors.credit360.com: copying pending permissions to model.ashx.
Processing greenlife.credit360.com: copying pending permissions to model.ashx.
Processing halcrow.credit360.com: copying pending permissions to model.ashx.
Processing worldbank-test.credit360.com: copying pending permissions to model.ashx.
Processing cairn2.credit360.com: copying pending permissions to model.ashx.
Processing swissretest.credit360.com: copying pending permissions to model.ashx.
Processing premierfarnell.credit360.com: copying pending permissions to model.ashx.
Skipping test.ica.credit360.com: no pending permissions found.
Processing td-old.credit360.com: copying pending permissions to model.ashx.
Processing nicolap.credit360.com: copying pending permissions to model.ashx.
Processing lgi.credit360.com: copying pending permissions to model.ashx.
Processing gfcr360.credit360.com: copying pending permissions to model.ashx.
Processing arup.credit360.com: copying pending permissions to model.ashx.
Skipping blihr-test.credit360.com: no pending permissions found.
Skipping sustainability.credit360.com: no pending permissions found.
Processing gs.credit360.com: copying pending permissions to model.ashx.
Processing isidemo.credit360.com: copying pending permissions to model.ashx.
Processing markshields.credit360.com: copying pending permissions to model.ashx.
Processing oldmutualtest.credit360.com: copying pending permissions to model.ashx.
Processing tiffany.credit360.com: copying pending permissions to model.ashx.
Processing telefonica-fundacion.credit360.com: copying pending permissions to model.ashx.
PL/SQL procedure successfully completed.
1 row updated.
Commit complete.
================== UPDATED OK ========================

*/
@update_tail
