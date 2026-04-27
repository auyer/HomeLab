-- Section for localhost
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
	-- modules_enabled = {
	-- 	"pubsub_serverinfo";
	-- }
	-- http_external_url = "https://www.{{ conf_settings.chat_hostname }}/"
Component("g.{{ conf_settings.chat_hostname }}")("muc")
	modules_enabled = {
		"muc_mam",
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
	http_external_url = "https://share.{{ conf_settings.chat_hostname }}:5281/"

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

-- Component "ps.{{ conf_settings.chat_hostname }}" "pubsub"
--     modules_enabled = {
--         "pubsub_feeds",
--         "pubsub_get",
--         "pubsub_eventsource",
--     }
--
-- 		-- http_external_url = "https://{{ conf_settings.chat_hostname }}/"
--     -- default_admin_affiliation = "owner"
--     pubsub_serverinfo_publish_user_count = true
--     -- admins = { "auyer@{{ conf_settings.chat_hostname }}" }
--
--    feeds = {}

--
--     feed_pull_interval_seconds = 900
