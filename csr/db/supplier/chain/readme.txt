In order to use a chain site, you'll need to create a company and add your user details using:

declare
    v_user_sid          security_pkg.T_SID_ID default 100180; -- the user sid to add    
    v_company_sid       security_pkg.T_SID_ID;
begin
    -- login --
    user_pkg.LOGONADMIN('chain.credit360.com');
    -- create the company --
    chain_company_pkg.CREATECOMPANY('Credit360 (UK)', 'UK', v_company_sid);
    -- add the user to the company -- 
    company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid, company_user_pkg.USER_IS_AUTHORIZED);
    -- set the company_sid in the context --
    security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', v_company_sid);
    -- add the user to the company's admin group --
    company_group_pkg.AddUserToGroup(v_user_sid, company_group_pkg.GT_COMPANY_ADMIN);
end;
/



To create a questionnaire (don't forget to be logged in):

begin
    -- login --
    user_pkg.LOGONADMIN('chaininfo.credit360.com');
	insert into chain_questionnaire 
	(chain_questionnaire_id, friendly_name, description, edit_url) 
	values (chain_questionnaire_id_seq.nextval, 'Workforce Standards', 'A questionnaire focussing on policies and standards relating to a supplier''s workforce.', '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId={questionnaireId}&edit=true');
	
end;
/

	
Give the UserCreatorDaemon full permissions on supplier/companies


You'll also need to turn on self registration for the site:

/csr/site/admin/config/global.acds

Set the self administration group to 'Supplier Users' and UNCHECK 'Self registration requires approval'

To setup the first-login redirection, you need to alter the action on menu path menu/admin/my_details
to /csr/site/supplier/chain/userprofile.acds