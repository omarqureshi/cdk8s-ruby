# A cdk8s app in Ruby, paired with app.ts. Both build the same chart; their
# synthesized manifests are compared byte-for-byte by cdk8s-conformance.sh.
#
# This is the cheapest end-to-end check this target has: a cdk8s app writes
# YAML and touches no cloud account, so "does the binding produce the same
# semantics as the TypeScript original" is answered by a diff rather than by
# reading generated code.
lib = File.expand_path(ENV.fetch('CDK8S_RUBY_LIB'), Dir.pwd)
$LOAD_PATH.unshift(lib)
require 'jsii'

# No explicit assembly loading: each generated entry point loads its own
# assembly when required. Doing it again here loaded every assembly twice,
# which on Node 22 left the kernel with two module instances of cdk8s — so
# cdk8s's `value instanceof Lazy` check failed against the other copy's class
# and synthesis died on "can't render non-simple object of type 'Lazy'".
# Node 24 tolerated the double load, which is why this only failed in CI.
require 'cdk8s'
require 'cdk8s-plus-27'

app = CDK8s::App.new
chart = CDK8s::Chart.new(app, 'hello')
CDK8sPlus27::Deployment.new(chart, 'web', {
  replicas: 2,
  containers: [{ image: 'nginx:1.27', port: 80 }],
})
app.synth
Jsii::Kernel.instance.shutdown
