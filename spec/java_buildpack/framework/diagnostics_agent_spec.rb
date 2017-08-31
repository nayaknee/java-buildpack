# Cloud Foundry Java Buildpack
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/framework/diagnostics_agent'

describe JavaBuildpack::Framework::DiagnosticsAgent do
  include_context 'component_helper'

  it 'does not detect without Diagnostics service' do
    expect(component.detect).to be_nil
  end

  context do

    before do
      allow(services).to receive(:one_service?).with(/diagnostics/, 'mediator-url').and_return(true)
    end

    it 'detects with diagnostics-n/a service' do
      expect(component.detect).to eq("diagnostics-agent=#{version}")
    end

    it 'downloads and unzips Diagnostics Agent, instruments the JRE',
       cache_fixture: 'stub-diagnostics-agent.jar' do

      component.compile

      expect(sandbox + 'lib/probeagent.jar').to exist
      expect(sandbox + 'classes/cf/instr.jre').to exist
    end

    it 'updates JAVA_OPTS' do
      allow(services).to receive(:find_service).and_return('credentials' => { 'mediator-url' => 'http://test-mediator.net:2006' })
      allow(component).to receive(:arch).and_return('x86_64')

      component.release

      expect(java_opts).to include('-javaagent:$PWD/.java-buildpack/diagnostics_agent/lib/probeagent.jar')
      expect(java_opts).to include('-Xbootclasspath/p:$PWD/.java-buildpack/diagnostics_agent/classes/cf/instr.jre')
      expect(java_opts).to include('-agentpath:$PWD/.java-buildpack/diagnostics_agent/lib/x86-linux64/libjvmti.so')
      expect(java_opts).to include('-Ddispatcher.registrar.url=http://test-mediator.net:2006/registrar')
      expect(java_opts).to include('-Ddiag.config.override=pcf')
      expect(java_opts).to include('-Dprobe.group=test-application-name')
    end

  end

end
