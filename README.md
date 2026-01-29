# NAME

Acme::MCP - Cheap Model Context Protocol (MCP) Server

# SYNOPSIS

```perl
use Acme::MCP;

my $mcp = Acme::MCP->new(
    name    => 'MathServer',
    version => '1.0.0'
);

# Define a tool for AI agents
$mcp->add_tool(
    name        => 'add',
    description => 'Adds two numbers',
    schema      => {
        type       => 'object',
        properties => {
            a => { type => 'number' },
            b => { type => 'number' }
        },
        required => ['a', 'b']
    },
    code => sub ($args) {
        return $args->{a} + $args->{b};
    }
);

# Start the server (STDIO transport)
$mcp->run();
```

# DESCRIPTION

`Acme::MCP` implements a painfully basic server for the Model Context Protocol (MCP). It allows you to expose your
Perl modules, local data, or internal tools to AI agents (like Claude or custom LLMs) through a standardized JSON-RPC
2.0 interface.

# PUBLIC METHODS

## `add_tool( %params )`

Registers a new tool that the AI agent can call.

- `name`: Unique tool identifier.
- `description`: Human-readable explanation of what the tool does.
- `schema`: JSON Schema describing the required arguments.
- `code`: Coderef executed when the tool is called.

## `run( )`

Starts the server loop. Listens for JSON-RPC requests on `STDIN` and writes responses to `STDOUT`. This transport is
compatible with standard MCP hosts.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
