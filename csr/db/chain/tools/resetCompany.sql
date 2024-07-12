
-- USE WITH CARE - this isn't a maintained script
-- This script: 
-- 		Terminates a relationship with any supplier company of XXX (who also supply another company -> so we can't delete them)
--		Soft deletes any suppliers who only supply this company 
--		Clears any uninvited companies
-- 		clears any old invites 		

-- 	Leaves the company XXX and it's users alone

-- TO DO - can orphan company 
-- TO DO - does nothing with products


DECLARE
    v_company_sid NUMBER;
BEGIN
    user_pkg.logonadmin('ra.credit360.com');
    
    SELECT company_sid INTO v_company_sid FROM chain.COMPANY WHERE name = 'XXX';
    
    security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
    
    -- TERMINATE any SUPPLIERS supplying OTHERS 
    FOR r IN (
        SELECT supplier_company_sid, name
          FROM supplier_relationship sr
          JOIN company c ON sr.supplier_company_sid = c.company_sid
         WHERE purchaser_company_sid = v_company_sid
           AND supplier_company_sid IN (
                 SELECT supplier_company_sid  
                  FROM supplier_relationship 
                 WHERE purchaser_company_sid <> v_company_sid   
           )
    ) LOOP
        -- DELETE COMPANY
        DBMS_OUTPUT.PUT_LINE('Termination of relationship '||r.name||'='||r.supplier_company_sid  );
        company_pkg.TerminateRelationship(v_company_sid, r.supplier_company_sid, TRUE);    
    END LOOP;
    
    -- DELETE any SUPPLIERS only supplying XXX 
    FOR r IN (
        SELECT supplier_company_sid, name
          FROM supplier_relationship sr
          JOIN company c ON sr.supplier_company_sid = c.company_sid
         WHERE purchaser_company_sid = v_company_sid 
           AND supplier_company_sid NOT IN (
                 SELECT supplier_company_sid  
                  FROM supplier_relationship 
                 WHERE purchaser_company_sid <> v_company_sid        
           )
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Deleting '||r.name||'='||r.supplier_company_sid  );
        company_pkg.DeleteCompany(r.supplier_company_sid);    
    END LOOP;
    
    -- nuke uninvited 
    FOR r IN (
        SELECT uninvited_supplier_sid, name
          FROM uninvited_supplier
          WHERE company_sid = v_company_sid
            AND created_as_company_sid IS NULL 
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Deleting uninvited'||r.name||'='||r.uninvited_supplier_sid  );
        
       UPDATE purchased_component
           SET component_supplier_type_id = 0, uninvited_supplier_sid = NULL
         WHERE uninvited_supplier_sid = r.uninvited_supplier_sid
           AND app_sid = security_pkg.GetApp;
           
        DELETE FROM uninvited_supplier
         WHERE uninvited_supplier_sid = r.uninvited_supplier_sid
           AND app_sid = security_pkg.GetApp;
    END LOOP;
    
    -- clear invites
    FOR i IN (
        SELECT invitation_id FROM invitation WHERE app_sid = security_pkg.getApp AND from_company_sid = v_company_sid
    )
    LOOP    
        DBMS_OUTPUT.PUT_LINE('Deleting invite '||i.invitation_id  );
        UPDATE invitation SET REINVITATION_OF_INVITATION_ID = NULL WHERE app_sid = security_pkg.getApp AND REINVITATION_OF_INVITATION_ID = i.invitation_id;
        DELETE FROM invitation_qnr_type WHERE  app_sid = security_pkg.getApp AND invitation_id = i.invitation_id;
        DELETE FROM invitation WHERE app_sid = security_pkg.getApp AND invitation_id = i.invitation_id;   
    END LOOP;
    
END;
/