SET DEFINE OFF

@@chain_bus_rel\test_bus_rel_pkg
@@chain_bus_rel\test_bus_rel_body

GRANT EXECUTE ON chain.test_bus_rel_pkg TO csr;

SET DEFINE ON
