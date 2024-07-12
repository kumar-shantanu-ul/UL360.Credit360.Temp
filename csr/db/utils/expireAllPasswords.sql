--Prompt the user the host we are going to make the users change the pass.
exec security.user_pkg.logonadmin('&HOST');

update security.user_table
   set last_password_change=sysdate-366
  where sid_id in (
     select csr_user_sid
       from csr.csr_user
     where app_sid = security.security_pkg.getapp
       and hidden = 0
  ); 
  
prompt Don't forget to commit the changes.