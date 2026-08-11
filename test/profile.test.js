const assert = require('node:assert/strict');
const path = require('node:path');
const { describe, test, before, after } = require('node:test');

const { profileHarness } = require('jsii-target-ruby/testing');

/**
 * What cdk8s is called in Ruby.
 *
 * Questions about this library, asked here rather than in the target, which
 * has no opinion about Kubernetes. See ../README.md for why the conformance
 * check (conformance.sh) carries most of the weight for this one: a cdk8s app
 * synthesizes YAML and touches no cloud account, so the strongest available
 * test is to build the same chart in Ruby and TypeScript and diff the output.
 *
 *   CDK8S=node_modules/cdk8s node --test test/*.test.js
 */
const PROFILE = path.resolve(__dirname, '..', 'config', 'profile.json');
const ASSEMBLY = process.env.CDK8S;

describe('the cdk8s naming profile', () => {
  let h;
  before(() => {
    h = profileHarness({ profile: PROFILE, assemblies: ASSEMBLY ? [ASSEMBLY] : [] });
  });
  after(() => h?.dispose());

  test('names the root module as an initialism, digit and all', () => {
    // CDK8s, not Cdk8s: no casing rule guesses this, which is exactly why a
    // profile exists.
    assert.equal(h.modulePathFor('cdk8s'), 'CDK8s');
  });

  test('gives each Kubernetes-versioned plus library its own module', () => {
    // cdk8s-plus-27 and -28 are separate assemblies pinned to Kubernetes
    // minors; one shared module would silently change what it binds to.
    assert.equal(h.modulePathFor('cdk8s-plus-27'), 'CDK8sPlus27');
  });

  test('applies acronym casing to type names', () => {
    if (!ASSEMBLY) return;
    assert.match(h.render("new cdk8s.ApiObject(this, 'O');"), /CDK8s::APIObject/);
  });

  test('cdk8s declares no submodules to drift', () => {
    // Unlike aws-cdk-lib, cdk8s is flat — so the drift surface here is the
    // set of cdk8s-plus versions, which is a packaging decision rather than
    // something a release can add behind our backs.
    if (!ASSEMBLY) return;
    assert.deepEqual(h.unnamedSubmodules(), []);
  });
});
