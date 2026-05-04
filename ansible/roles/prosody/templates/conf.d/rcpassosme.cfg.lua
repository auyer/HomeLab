local _privileges = {
	roster = "both",
	message = "outgoing",
	iq = {
		["http://jabber.org/protocol/pubsub"] = "both",
		["http://jabber.org/protocol/pubsub#owner"] = "set",
		["urn:xmpp:http:upload:0"] = "get",
	},
}

VirtualHost("{{ conf_settings.chat_hostname }}")
	enabled = true
	http_host = "{{ conf_settings.chat_hostname }}"
	privileged_entities = {
		["matrix.{{ conf_settings.chat_hostname }}"] = _privileges,
	}
	disco_items = {
		{ "matrix.{{ conf_settings.chat_hostname }}", "Matrix Bridge" },
		{ "irc.{{ conf_settings.base_hostname }}", "biboumi IRC Bridge" },
		{ "notify.{{ conf_settings.base_hostname }}", "Unified push Notifications" },
	}
	modules_enabled = {
	 	"pubsub_serverinfo";
		{% if prosody_invite_registration %}
		"invites";
    "invites_adhoc";
    "invites_register";
    "invites_register_web";
		{% endif %}
		{% if prosody_conversejs %}
		"conversejs";
		{% endif %}
	}


	http_external_url = "https://{{ conf_settings.http_external_url }}/"

	{% if prosody_invite_registration %}
	invites_page = "https://{{ conf_settings.chat_hostname }}/invite?{invite.token}"
	invites_page_template_dir = "/var/www/invites"

	http_paths = {
		invites_page = "/invite";
		invites_register_web = "/register";
	}

	allow_registration = true
	allow_user_invites = true
	registration_invite_only = true
	invite_expiry = 86400 * 7
	site_name = "{{ prosody_service_name }}"

	registration_notification = "User $username just registered on $host"
	registration_watchers = {{ admin_addresses | to_json | replace('[', '{') | replace(']', '}') }};
	{% endif %}


	{% if prosody_conversejs %}
	conversejs_tags = {
        -- Load libsignal-protocol.js for OMEMO support (GPLv3; be aware of licence implications)
        [[<script src="https://cdn.conversejs.org/3rdparty/libsignal-protocol.min.js"></script>]];
	}
	conversejs_name = "{{ prosody_service_name }}"
  conversejs_short_name = "{{ prosody_service_name }}"
	conversejs_description = "{{ prosody_service_name }}"
	{% endif %}

Component("g.{{ conf_settings.chat_hostname }}")("muc")
	modules_enabled = {
		"muc_mam",
	  -- "pubsub_serverinfo";
	}
	restrict_room_creation = "local"

Component("share.{{ conf_settings.chat_hostname }}")("http_file_share")
	http_file_share_daily_quota = 200 * 1024 * 1024 -- 100 MiB per day per user
	http_file_share_size_limit = 20 * 1024 * 1024
	http_file_share_global_quota = 1024 * 1024 * 1024
	http_file_share_expire_after = "1 week"
	http_file_share_access = { "matrix.{{ conf_settings.chat_hostname }}" }
	-- its not necessary to have s2s loaded here:
	modules_disabled = { "s2s" }
	-- Change the Limit to 100MB:
	-- http_file_share_size_limit = 1024 * 1024 * 100
	-- http_file_share_expires_after = "2 weeks"
	http_external_url = "https://share.{{ conf_settings.http_external_url }}/"

	-- here you see how we can manipulate the path:
	http_paths = {
		file_share = "/share", --Serve from the base URL
	}
Component("p65.{{ conf_settings.chat_hostname }}")("proxy65")
	proxy65_address = "{{ conf_settings.chat_hostname }}"

Component("notify.{{ conf_settings.base_hostname }}")("unified_push")
	unified_push_secret = "{{ conf_settings.unified_push_secret }}"
	http_host = "{{ conf_settings.chat_hostname }}"

Component("matrix.{{ conf_settings.chat_hostname }}")
	component_secret = "{{ matridge_secret }}"

	modules_enabled = { "privilege" }

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
        "pubsub_get",
        "pubsub_eventsource",
    }

   -- http_external_url = "{{ conf_settings.http_external_url }}/"
   -- default_admin_affiliation = "owner"
   pubsub_serverinfo_publish_user_count = true
   admins = {{ admin_addresses | to_json | replace('[', '{') | replace(']', '}') }}

   feeds = {{ prosody_feeds | to_json | replace('[', '{') | replace(']', '}') }}


   feed_pull_interval_seconds = 900
