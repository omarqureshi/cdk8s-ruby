# cdk8s-ruby

Ruby naming and distribution for **cdk8s**, built with
[jsii-target-ruby](https://github.com/omarqureshi/jsii-target-ruby).

## What lives here

| | |
| --- | --- |
| `config/profile.json` | what cdk8s and cdk8s-plus are called in Ruby |
| `test/profile.test.js` | that those names are right |
| `conformance.sh` | the strong test — see below |

## The conformance check

A cdk8s app synthesizes Kubernetes YAML and talks to no cloud account, which
makes it the cheapest exact test these bindings have: build the same chart
twice, once in Ruby and once in TypeScript, and diff the manifests.

```sh
./conformance.sh /tmp/work path/to/node_modules
```

It generates the bindings, checks every generated file parses, synthesizes
both ways and compares. They are byte-for-byte identical today, across 840
generated files.

That is a stronger statement than any amount of reading generated code: it
says the bindings *mean* the same thing as the originals.

## Naming

`CDK8s`, not `Cdk8s` — an initialism with a digit in it, which no casing rule
is going to guess. Each `cdk8s-plus-NN` is a separate assembly pinned to a
Kubernetes minor, so each gets its own gem and module rather than one gem that
quietly changes what it binds to.
