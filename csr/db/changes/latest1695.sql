-- Please update version.sql too -- this keeps clean builds in sync
define version=1695
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

BEGIN
-- Delete duplicate factors

DELETE FROM csr.factor_type WHERE factor_type_id=7209;
DELETE FROM csr.factor_type WHERE factor_type_id=7269;
DELETE FROM csr.factor_type WHERE factor_type_id=7450;
DELETE FROM csr.factor_type WHERE factor_type_id=7695;
DELETE FROM csr.factor_type WHERE factor_type_id=7697;
DELETE FROM csr.factor_type WHERE factor_type_id=7750;
DELETE FROM csr.factor_type WHERE factor_type_id=8004;
DELETE FROM csr.factor_type WHERE factor_type_id=8006;
DELETE FROM csr.factor_type WHERE factor_type_id=8059;
DELETE FROM csr.factor_type WHERE factor_type_id=8101;
DELETE FROM csr.factor_type WHERE factor_type_id=8102;
DELETE FROM csr.factor_type WHERE factor_type_id=8310;
DELETE FROM csr.factor_type WHERE factor_type_id=8370;
DELETE FROM csr.factor_type WHERE factor_type_id=8551;
DELETE FROM csr.factor_type WHERE factor_type_id=8796;
DELETE FROM csr.factor_type WHERE factor_type_id=8798;
DELETE FROM csr.factor_type WHERE factor_type_id=8851;
DELETE FROM csr.factor_type WHERE factor_type_id=9105;
DELETE FROM csr.factor_type WHERE factor_type_id=9107;
DELETE FROM csr.factor_type WHERE factor_type_id=9160;
DELETE FROM csr.factor_type WHERE factor_type_id=9202;
DELETE FROM csr.factor_type WHERE factor_type_id=9203;
DELETE FROM csr.factor_type WHERE factor_type_id=9411;
DELETE FROM csr.factor_type WHERE factor_type_id=9471;
DELETE FROM csr.factor_type WHERE factor_type_id=9652;
DELETE FROM csr.factor_type WHERE factor_type_id=9897;
DELETE FROM csr.factor_type WHERE factor_type_id=9899;
DELETE FROM csr.factor_type WHERE factor_type_id=10206;
DELETE FROM csr.factor_type WHERE factor_type_id=10208;
DELETE FROM csr.factor_type WHERE factor_type_id=10261;
DELETE FROM csr.factor_type WHERE factor_type_id=10303;
DELETE FROM csr.factor_type WHERE factor_type_id=10304;
DELETE FROM csr.factor_type WHERE factor_type_id=11276;
DELETE FROM csr.factor_type WHERE factor_type_id=11353;
DELETE FROM csr.factor_type WHERE factor_type_id=11431;
DELETE FROM csr.factor_type WHERE factor_type_id=11520;
DELETE FROM csr.factor_type WHERE factor_type_id=11585;
DELETE FROM csr.factor_type WHERE factor_type_id=11662;
DELETE FROM csr.factor_type WHERE factor_type_id=11739;
DELETE FROM csr.factor_type WHERE factor_type_id=11816;
DELETE FROM csr.factor_type WHERE factor_type_id=11894;
DELETE FROM csr.factor_type WHERE factor_type_id=11971;
DELETE FROM csr.factor_type WHERE factor_type_id=12048;
DELETE FROM csr.factor_type WHERE factor_type_id=12127;
DELETE FROM csr.factor_type WHERE factor_type_id=12204;
DELETE FROM csr.factor_type WHERE factor_type_id=12281;
DELETE FROM csr.factor_type WHERE factor_type_id=12358;
DELETE FROM csr.factor_type WHERE factor_type_id=12435;
DELETE FROM csr.factor_type WHERE factor_type_id=12612;
DELETE FROM csr.factor_type WHERE factor_type_id=12614;
DELETE FROM csr.factor_type WHERE factor_type_id=12666;
DELETE FROM csr.factor_type WHERE factor_type_id=12738;
DELETE FROM csr.factor_type WHERE factor_type_id=12739;
DELETE FROM csr.factor_type WHERE factor_type_id=12770;
DELETE FROM csr.factor_type WHERE factor_type_id=12839;
DELETE FROM csr.factor_type WHERE factor_type_id=13079;
DELETE FROM csr.factor_type WHERE factor_type_id=13081;
DELETE FROM csr.factor_type WHERE factor_type_id=13133;
DELETE FROM csr.factor_type WHERE factor_type_id=13205;
DELETE FROM csr.factor_type WHERE factor_type_id=13206;
DELETE FROM csr.factor_type WHERE factor_type_id=13237;
DELETE FROM csr.factor_type WHERE factor_type_id=13306;
DELETE FROM csr.factor_type WHERE factor_type_id=13546;
DELETE FROM csr.factor_type WHERE factor_type_id=13548;
DELETE FROM csr.factor_type WHERE factor_type_id=13600;
DELETE FROM csr.factor_type WHERE factor_type_id=13672;
DELETE FROM csr.factor_type WHERE factor_type_id=13673;
DELETE FROM csr.factor_type WHERE factor_type_id=13704;
DELETE FROM csr.factor_type WHERE factor_type_id=13773;

COMMIT;
END;
/

@update_tail