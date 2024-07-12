define rap4_version=1
@update_header

connect postcode/postcode@&_CONNECT_IDENTIFIER;
grant select, references on postcode.country to chain with grant option;

connect chain/chain@&_CONNECT_IDENTIFIER;
grant execute on chain.component_pkg to rfa;


@update_tail
