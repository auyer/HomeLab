local _privileges = {
    roster = "both",
    message = "outgoing",
    iq = {
        ["http://jabber.org/protocol/pubsub"] = "both",
        ["http://jabber.org/protocol/pubsub#owner"] = "set",
    },
}

VirtualHost("{{ conf_settings.chat_hostname }}")
    enabled = true
    privileged_entities = {
        ["matrix.{{ conf_settings.chat_hostname }}"] = _privileges,
    }
    disco_items = {
        { "matrix.{{ conf_settings.chat_hostname }}", "Matrix Bridge" },
        { "irc.{{ conf_settings.base_hostname }}", "biboumi IRC Bridge" },
        { "notify.{{ conf_settings.base_hostname }}", "Unified push Notifications" },
        { "pubsub.{{ conf_settings.chat_hostname }}", "PubSub Service" },
    }
    modules_enabled = {
         "pubsub_serverinfo";
        {% if prosody_invite_registration %}
        "invites";
        "invites_adhoc";
        "invites_register";
        {% endif %}
    }

    pubsub_serverinfo_service = "pubsub.{{ conf_settings.chat_hostname }}"
    pubsub_serverinfo_publish_user_count = true

    {% if prosody_invite_registration %}
    allow_registration = true
    allow_user_invites = true
    registration_invite_only = true
    invite_expiry = 86400 * 7
    site_name = "{{ prosody_service_name }}"

    registration_notification = "User $username just registered on $host"
    registration_watchers = {{ (admin_addresses.keys() | list if admin_addresses is mapping else ([admin_addresses] if admin_addresses is string else admin_addresses)) | to_json | replace('[', '{') | replace(']', '}') }};
    {% endif %}

Component("g.{{ conf_settings.chat_hostname }}")("muc")
    modules_enabled = {
        "muc_mam",
    }
    restrict_room_creation = "local"

Component("notify.{{ conf_settings.base_hostname }}")("unified_push")
    unified_push_secret = "{{ conf_settings.unified_push_secret }}"


Component("irc.{{ conf_settings.base_hostname }}")
    component_secret = "{{ biboumi_password }}"

    modules_enabled = { "privilege" }

Component "pubsub.{{ conf_settings.chat_hostname }}" "pubsub"
    server_user_role = "prosody:registered"
    add_permissions = {
        ["prosody:registered"] = { "pubsub:create-node" }
    }
    modules_enabled = {
        "pubsub_feeds",
        "pubsub_text_interface",
    }

    admins = { "{{ conf_settings.chat_hostname }}" }

    feeds = {
{% if prosody_feeds is mapping %}
{% for name, url in prosody_feeds.items() %}
        {{ name }} = "{{ url }}";
{% endfor %}
{% else %}
{% for url in prosody_feeds %}
        "{{ url }}";
{% endfor %}
{% endif %}
    }

    feed_pull_interval_seconds = 900
