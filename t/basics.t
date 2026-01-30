use v5.42;
use Test2::V0;
use lib '../lib';
use Acme::MCP;
use JSON::PP;
#
subtest 'Tool Registration' => sub {
    isa_ok my $mcp = Acme::MCP->new(), ['Acme::MCP'];
    ok $mcp->add_tool( name => 'echo', code => sub ($args) { $args->{text} } ), 'add_tool->( ... )';

    # Internal check
    my %all_tools = $mcp->tools;
    is $all_tools{echo}, E(), 'Tool registered';
};

# We mock STDIN/STDOUT to test the JSON-RPC loop
subtest 'JSON-RPC Handling' => sub {
    my $mcp = Acme::MCP->new( name => 'TestServer' );
    $mcp->add_tool( name => 'add', code => sub ($args) { $args->{a} + $args->{b} } );
    my $json = JSON::PP->new->utf8(1);
    my $request
        = $json->encode( { jsonrpc => '2.0', id => 1, method => 'tools/call', params => { name => 'add', arguments => { a => 5, b => 10 } } } );

    # Mock handle_request directly to avoid loop
    my $response;
    no warnings 'redefine';
    local *Acme::MCP::_send_response = sub ( $self, $id, $res ) {
        $response = $res;
    };
    $mcp->_handle_request( $json->decode($request) );
    ok $response, 'Got response from tool call';
    is $response->{content}[0]{text}, '15', 'Correct tool result';
};
#
done_testing;
