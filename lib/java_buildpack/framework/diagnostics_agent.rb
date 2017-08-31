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

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling Diagnostics Java Agent support
    class DiagnosticsAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_zip

        # Automatic Explicit mode
        java_exec = @droplet.java_home.root.to_s + '/bin/java'
        jarfile = @droplet.sandbox + 'lib/jreinstrumenter.jar'
        command = "#{java_exec} -jar #{jarfile} -f cf"
        # Ignore the result ... the absolute pathnames during app deployment will be different
        tmp = `#{command}`

      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        credentials   = @application.services.find_service(FILTER)['credentials']
        java_opts = @droplet.java_opts
        settings = {}

        extract(settings, @configuration)
        extract(settings, credentials)

        settings['dispatcher.registrar.url'] = registrar_url(credentials)
        settings['diag.config.override'] = 'pcf'

        java_opts
          .add_bootclasspath_p(@droplet.sandbox + 'classes/cf/instr.jre')
          .add_javaagent(@droplet.sandbox + 'lib/probeagent.jar')
          .add_agentpath(@droplet.sandbox + jvmti_lib_name)

        flush_system_properties(java_opts, settings)

      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, MEDIATOR
      end

      private

      FILTER = /diagnostics/
      MEDIATOR = 'mediator-url'.freeze

      private_constant :FILTER, :MEDIATOR

      def registrar_url(credentials)
        credentials[MEDIATOR] + '/registrar'
      end

      def jvmti_lib_name
        arch == 'x86_64' ? 'lib/x86-linux64/libjvmti.so' : 'lib/x86-linux/libjvmti.so'
      end

      def arch
        `uname -m`.strip
      end

      def extract(properties, collection)
        collection.each do |key, value|
          diag_opt = /^diag\.(.*)/.match(key)
          properties[diag_opt[1]] = value if diag_opt
        end
      end

      def flush_system_properties(java_opts, properties)
        properties.each do |key, value|
          java_opts.add_system_property(key, value)
        end
      end

    end

  end
end
