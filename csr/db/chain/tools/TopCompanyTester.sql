DECLARE
    v_company_sid NUMBER;
BEGIN

    user_pkg.logonadmin('rainforestalliance.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'ASDA' and country_code = 'gb';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('RA Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('RA No');
    END IF;
    
    user_pkg.logonadmin('rainforestalliance.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'Double A';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('RA Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('RA No');
    END IF;
    
    user_pkg.logonadmin('rainforestalliance.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'ABC Corporation';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('RA Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('RA No');
    END IF;
  
    user_pkg.logonadmin('Maersk.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'A.P. Moller - Maersk';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('Maersk Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Maersk No');
    END IF;
    
    user_pkg.logonadmin('Maersk.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'ABS';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('Maersk Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Maersk No');
    END IF;
    
    user_pkg.logonadmin('marksandspencer.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'Marks '||CHR(38)||' Spencer';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('MnS Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('MnS No');
    END IF;
    
    user_pkg.logonadmin('marksandspencer.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = '10 International 10 International 1541';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN  
        DBMS_OUTPUT.PUT_LINE('MnS Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('MnS No');
    END IF;
    
    user_pkg.logonadmin('marksandspencer.credit360.com');
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = '10 International';
    --security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    IF (helper_pkg.isSidTopCompany(v_company_sid)=1) THEN 
        DBMS_OUTPUT.PUT_LINE('MnS Yes');
    ELSE
        DBMS_OUTPUT.PUT_LINE('MnS No');
    END IF;
    
   
END;


