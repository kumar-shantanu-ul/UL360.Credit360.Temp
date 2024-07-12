set serveroutput on
set echo off

@@test_common_pkg
@@test_common_body

grant execute on csr.test_common_pkg to csr;

set echo on
