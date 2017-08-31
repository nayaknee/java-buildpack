# Diagnostics Agent Framework
The Diagnostics Agent Framework causes an application to be automatically configured to work with a bound Diagnostics Service.  **Note:** This framework is disabled by default.

<table>
  <tr>
    <td><strong>Detection Criterion</strong></td><td>Existence of a single bound Diagnostics service. The existence of an Diagnostics service defined by the <a href="http://docs.cloudfoundry.org/devguide/deploy-apps/environment-variable.html#VCAP-SERVICES"><code>VCAP_SERVICES</code></a> payload containing a service name, label or tag with <code>diagnostics</code> as a substring and contains <code>mediator-url</code> field in the credentials.
</td>
  </tr>
  <tr>
    <td><strong>Tags</strong></td><td><tt>diagnostics-agent=&lt;version&gt;</tt></td>
  </tr>
</table>
Tags are printed to standard output by the buildpack detect script

## User-Provided Service
When binding Diagnostics Agent using a user-provided service, it must have name or tag with `diagnostics` in it. The credentials payload can contain the following entries.

| Name | Description
| ---- | -----------
| `mediator-url` | The URL of the Diagnostics mediator in the form http://<host>:<port>
| `diag.*` | (Optional) Any entry of this form can be used to set a Diagnostics option. Just add the `diag.` prefix to the probe setting name.

### Payload example
```
{
  "mediator-url" : "http://my.mediator.server:2006",
  "diag.probe.group" : "Inventory",
  "diag.dispatcher.minimum.fragment.latency" : "100ms"
}
```

**NOTE**

* If the Probe Group (`diag.probe.group`) is not defined by the credentials payload, it will default to the PCF application name.

## Configuration
For general information on configuring the buildpack, including how to specify configuration values through environment variables, refer to [Configuration and Extension][].

The framework can be configured by modifying the configuration file [`config/diagnostics_agent.yml`][] in the buildpack fork. The framework uses the [`Repository` utility support][repositories] and so it supports the [version syntax][] defined there.

| Name | Description
| ---- | -----------
| `repository_root` | The URL of the Diagnostics repository index ([details][repositories]).
| `version` | The version of Diagnostics Agent to use.
| `diag.*` | (Optional) Any entry of this form can be used to set a Diagnostics option. Just add the `diag.` prefix to the probe setting name.

**NOTES**

* Diagnostics setting set in the credentials payload take precedence over the Diagnostics settings set in the configuration file.
* It is not possible to override `probe.id` in the configuration file or in the credentials payload; the probe id will be automatically assigned by Diagnostics as `<application_name>_<instance_index>`.

[`config/diagnostics_agent.yml`]: ../config/diagnostics_agent.yml
[Configuration and Extension]: ../README.md#configuration-and-extension
[repositories]: extending-repositories.md
[version syntax]: extending-repositories.md#version-syntax-and-ordering
