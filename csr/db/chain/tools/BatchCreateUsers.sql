DECLARE
    v_company_sid NUMBER;
	v_user_sid NUMBER;
BEGIN
    user_pkg.logonadmin('rainforestalliance.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'ASDA' and country_code = 'gb';

    -- visibility 3 = all details

--v_user_sid :=  chain.company_user_pkg.CreateUser(v_company_sid, 'Wings Leung', 'Wings', 'w1leung@wal-mart.com', 'w1leung@wal-mart.com', null, null, 3);	chain.company_user_pkg.ActivateUser(v_user_sid); chain.company_user_pkg.SetRegistrationStatus(v_user_sid ,1);  chain.company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid); chain.company_user_pkg.ApproveUser(v_company_sid, v_user_sid);
--v_user_sid :=  chain.company_user_pkg.CreateUser(v_company_sid, 'Bob Choi', 'Bob', 'bchoi@wal-mart.com', 'bchoi@wal-mart.com', null, null, 3);	chain.company_user_pkg.ActivateUser(v_user_sid); chain.company_user_pkg.SetRegistrationStatus(v_user_sid ,1);  chain.company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid); chain.company_user_pkg.ApproveUser(v_company_sid, v_user_sid);
v_user_sid :=  chain.company_user_pkg.CreateUser(v_company_sid, 'Ray Huang', 'Ray', 'rhuang6@wal-mart.com', 'rhuang6@wal-mart.com', null, null, 3);	chain.company_user_pkg.ActivateUser(v_user_sid); chain.company_user_pkg.SetRegistrationStatus(v_user_sid ,1);  chain.company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid); chain.company_user_pkg.ApproveUser(v_company_sid, v_user_sid);
v_user_sid :=  chain.company_user_pkg.CreateUser(v_company_sid, 'Melody Lee', 'Melody', 'm2lee@wal-mart.com', 'm2lee@wal-mart.com', null, null, 3);	chain.company_user_pkg.ActivateUser(v_user_sid); chain.company_user_pkg.SetRegistrationStatus(v_user_sid ,1);  chain.company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid); chain.company_user_pkg.ApproveUser(v_company_sid, v_user_sid);
	
END;
/