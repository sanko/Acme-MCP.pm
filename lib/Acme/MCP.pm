use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Acme::MCP v1.0.0 {
    use JSON::PP;
    use Carp qw[carp croak];
    #
    field $name    : param : reader : writer = 'Generic MCP Server';
    field $version : param : reader : writer = '1.0.0';
    field %tools   : reader;
    field $json = JSON::PP->new->utf8(1);
    #
    method add_tool (%params) {
        my $name = $params{name} or croak 'Tool name required';
        my $code = $params{code} or croak 'Tool code (sub) required';
        $tools{$name}
            = { description => $params{description} // '', inputSchema => $params{schema} // { type => 'object', properties => {} }, code => $code };
    }

    method run () {
        $| = 1;    # Autoflush for stdio communication
        carp "$name started, listening on STDIN";
        while ( my $line = <STDIN> ) {
            chomp $line;
            my $request;
            try { $request = $json->decode($line) }
            catch ($e) {
                $self->_send_error( undef, -32700, 'Parse error' );
                next;
            }
            $self->_handle_request($request);
        }
    }

    method _handle_request ($req) {
        my $id     = $req->{id};
        my $method = $req->{method} // '';
        if ( $method eq 'initialize' ) {
            $self->_send_response(
                $id,
                {   protocolVersion => '2024-11-05',
                    capabilities    => { tools => { listChanged => JSON::PP::true }, },
                    serverInfo      => { name  => $name, version => $version }
                }
            );
        }
        elsif ( $method eq 'tools/list' ) {
            my @tool_list;
            for my $t_name ( sort keys %tools ) {
                push @tool_list, { name => $t_name, description => $tools{$t_name}{description}, inputSchema => $tools{$t_name}{inputSchema} };
            }
            $self->_send_response( $id, { tools => \@tool_list } );
        }
        elsif ( $method eq 'tools/call' ) {
            $self->_handle_tool_call( $id, $req->{params} );
        }
        else {
            $self->_send_error( $id, -32601, 'Method not found: ' . $method );
        }
    }

    method _handle_tool_call ( $id, $params ) {
        my $t_name = $params->{name};
        my $args   = $params->{arguments} // {};
        if ( my $tool = $tools{$t_name} ) {
            try {
                my $result = $tool->{code}->($args);
                $self->_send_tool_result( $id, $result );
            }
            catch ($e) {
                $self->_send_tool_result( $id, { error => $e }, 1 );
            }
        }
        else {
            $self->_send_error( $id, -32602, 'Unknown tool: ' . $t_name );
        }
    }

    method _send_response ( $id, $result ) {
        print STDOUT $json->encode( { jsonrpc => '2.0', id => $id, result => $result } ) . "\n";
    }

    method _send_tool_result ( $id, $content, $is_error = 0 ) {
        $self->_send_response(
            $id,
            {   content => [ { type => 'text', text => ref($content) ? $json->encode($content) : $content } ],
                isError => $is_error ? JSON::PP::true : JSON::PP::false
            }
        );
    }

    method _send_error ( $id, $code, $message ) {
        print STDOUT $json->encode( { jsonrpc => '2.0', id => $id, error => { code => $code, message => $message } } ) . "\n";
    }
};
#
1;
