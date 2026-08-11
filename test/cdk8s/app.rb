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

kernel = Jsii::Kernel.instance
# The kernel needs each assembly loaded before its proxies can be constructed;
# pacmak emits the tarballs next to the sources it generates. Discover them
# rather than naming versions: whatever `npm install` resolved is what was
# generated, and a hardcoded version is a check that only passes on the
# machine it was written on.
#
# The kernel rejects an assembly whose dependencies it has not seen, so order
# matters — but reading it out of each tarball is more machinery than a test
# app needs. Load what loads, repeat while anything is still making progress:
# that is dependency order without having to know it.
pending = Dir[File.join(lib, '*.jsii.tgz')]
until pending.empty?
  loaded = pending.select do |tarball|
    name, version = File.basename(tarball, '.jsii.tgz').split('@')
    begin
      kernel.load_assembly(name, version, tarball)
      true
    rescue Jsii::RuntimeError
      false
    end
  end
  raise "could not load: #{pending.map { |f| File.basename(f) }.join(', ')}" if loaded.empty?

  pending -= loaded
end

require 'cdk8s'
require 'cdk8s-plus-27'

app = CDK8s::App.new
chart = CDK8s::Chart.new(app, 'hello')
CDK8sPlus27::Deployment.new(chart, 'web', {
  replicas: 2,
  containers: [{ image: 'nginx:1.27', port: 80 }],
})
app.synth
kernel.shutdown
