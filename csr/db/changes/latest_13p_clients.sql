define host=bidvest.credit360.com
define usr=bidvest
@\cvs\clients\bidvest\db\report_pkg
@\cvs\clients\bidvest\db\report_body
define host=britishland.credit360.com
define usr=britishland
@\cvs\clients\britishland\db\reports_pkg
@\cvs\clients\britishland\db\reports_body
define host=britishland_test.credit360.com
define usr=britishland_test
@\cvs\clients\britishland\db\reports_pkg
@\cvs\clients\britishland\db\reports_body
define host=cermaq.credit360.com
define usr=cermaq
@\cvs\clients\cermaq\db\cermaq_pkg
@\cvs\clients\cermaq\db\cermaq_body
define host=chevron.credit360.com
define usr=chevron
@\cvs\clients\chevron\db\project_pkg
@\cvs\clients\chevron\db\project_body
define host=cr360sharing.credit360.com
define usr=cr360sharing
@\cvs\clients\cr360sharing\db\project_pkg
@\cvs\clients\cr360sharing\db\project_body
define host=dms.credit360.com
define usr=dms
@\cvs\clients\dbdms\db\project_pkg
@\cvs\clients\dbdms\db\project_body
define host=gsk-test.credit360.com
define usr=gsktest
@\cvs\clients\gsk\db\custom_report_pkg
@\cvs\clients\gsk\db\custom_report_body
define host=hammerson.credit360.com
define usr=hammerson
@\cvs\clients\hammerson\db\project_pkg
@\cvs\clients\hammerson\db\project_body
define host=heinekenspm.credit360.com
define usr=heinekenspm
grant select on csr.delegation_policy to heinekenspm;
@\cvs\clients\heinekenspm\db\import_pkg
@\cvs\clients\heinekenspm\db\import_body
@\cvs\clients\heinekenspm\db\report_pkg
@\cvs\clients\heinekenspm\db\report_body
define host=linde.credit360.com
define usr=linde
@\cvs\clients\linde\db\report_pkg
@\cvs\clients\linde\db\report_body
define host=philips.credit360.com
define usr=philips
grant select, insert, update, delete on csr.temp_delegation_detail to philips;
@\cvs\clients\philips\db\hs\hs_pkg
@\cvs\clients\philips\db\hs\hs_body
@\cvs\clients\philips\db\logistics\logistics_pkg
@\cvs\clients\philips\db\logistics\logistics_body
define host=lumiled.credit360.com
define usr=lumiled
grant select, insert, update, delete on csr.temp_delegation_detail to lumiled;
@\cvs\clients\philips\db\hs\hs_pkg
@\cvs\clients\philips\db\hs\hs_body
define host=otto-sc-sandbox.credit360.com
define usr=ottosc
@\cvs\clients\otto-supplychain\db\chain_setup_pkg
@\cvs\clients\otto-supplychain\db\chain_setup_body
define host=otto-supplychain.credit360.com
define usr=otto_supplychain
grant select on csr.audit_type_closure_type to otto_supplychain;
@\cvs\clients\otto-supplychain\db\chain_setup_pkg
@\cvs\clients\otto-supplychain\db\chain_setup_body
@\cvs\clients\otto-supplychain\db\report_pkg
@\cvs\clients\otto-supplychain\db\report_body
@\cvs\clients\otto-supplychain\db\migration_pkg
@\cvs\clients\otto-supplychain\db\migration_body
define host=otto-sc.credit360.com
define usr=osc
@\cvs\clients\otto-supplychain\db\chain_setup_pkg
@\cvs\clients\otto-supplychain\db\chain_setup_body
define host=otto-sc-sandbox2.credit360.com
define usr=ottosc2
@\cvs\clients\otto-supplychain\db\chain_setup_pkg
@\cvs\clients\otto-supplychain\db\chain_setup_body
define host=centrica.credit360.com
define usr=centrica
grant select on csr.scenario_run to centrica;
@\cvs\clients\centrica\db\scenario_pkg
@\cvs\clients\centrica\db\scenario_body
define host=mcdonalds-sc-sandbox.credit360.com
define usr=mcdsc
@\cvs\clients\mcdonalds-supplychain\db\chain_setup_pkg
@\cvs\clients\mcdonalds-supplychain\db\chain_setup_body
define host=otto.credit360.com
define usr=otto
@\cvs\clients\otto\db\backfill_pkg
@\cvs\clients\otto\db\backfill_body
define host=abinbev.credit360.com
define usr=abinbev
grant select on csr.scenario_run to abinbev;
@\cvs\clients\abinbev\db\scenario\meanscores_pkg
@\cvs\clients\abinbev\db\scenario\meanscores_body
define host=credit-agricole.credit360.com
define usr=creditagricole
grant select on csr.scenario_run to creditagricole;
@\cvs\clients\creditagricole\orga\orga_pkg
@\cvs\clients\creditagricole\orga\orga_body
define host=credit-agricole-uat.credit360.com
define usr=casauat2
grant select on csr.scenario_run to casauat2;
@\cvs\clients\creditagricole\orga\orga_pkg
@\cvs\clients\creditagricole\orga\orga_body
define host=centrica-epr-test.credit360.com
define usr=centricatest
grant select on csr.scenario_run to centricatest;
@\cvs\clients\centrica\db\scenario_pkg
@\cvs\clients\centrica\db\scenario_body
exit
