{%- from "freeipa/map.jinja" import client, ipa_host with context %}
{%- if client.enabled %}

include:
  - freeipa.client

{%- for host in client.get("nsupdate", {}) %}

/etc/nsupdate-{{ host.name }}:
  file.managed:
    - template: jinja
    - source: salt://freeipa/files/nsupdate
    - defaults:
        name: {{ host.name }}
        {%- if host.ipv4 is not defined and host.name == ipa_host %}
        ipv4: {{ grains['fqdn_ip4']|default([]) }}
        {%- else %}
        ipv4: {{ host.ipv4|default([]) }}
        {%- endif %}
        {%- if host.ipv6 is not defined and host.name == ipa_host %}
        ipv6: {{ grains['fqdn_ip6']|default([]) }}
        {%- else %}
        ipv6: {{ host.ipv6|default([]) }}
        {%- endif %}
        ttl: {{ host.get('ttl', 1800) }}
    - watch_in:
      - cmd: nsupdate_{{ host.name }}
    - require:
      {%- if host.name == ipa_host %}
      - cmd: freeipa_client_install
      {%- else %}
      - cmd: freeipa_keytab_{{ host.get('keytab', '/etc/krb5.keytab') }}_host_{{ host.name }}
      {%- endif %}

/etc/nsupdate-{{ host.name }}-delete:
  file.managed:
    - template: jinja
    - source: salt://freeipa/files/nsupdate-delete
    - defaults:
        name: {{ host.name }}

nsupdate_{{ host.name }}:
  cmd.wait:
    - name: "kinit -kt {{ host.get('keytab', '/etc/krb5.keytab') }} host/{{ host.name }} && nsupdate -g /etc/nsupdate-{{ host.name }}; E=$?; /usr/bin/kdestroy; exit $E"

{%- endfor %}

{%- endif %}