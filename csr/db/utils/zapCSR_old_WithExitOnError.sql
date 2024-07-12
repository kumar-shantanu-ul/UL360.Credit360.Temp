-- Used by the csrexpimpzap CI build
whenever sqlerror exit sql.sqlcode
--@"C:\CCArtifacts\UITest Database Build\cvs\csr\db\utils\zapCSR.sql" &&1
@@zapCSR.sql &&1
