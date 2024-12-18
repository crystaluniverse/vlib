module sendgrid

pub struct Content {
	type_ string = 'text/html' @[json: 'type']
	value string
}

struct Recipient {
	email string @[required]
	name  ?string
}

struct Attachment {
	content     string  @[required]
	type_       ?string @[json: 'type']
	filename    string  @[required]
	disposition ?string
	content_id  ?string
}

struct UnsubscribeGroups {
	group_id         i64 @[required]
	group_to_display []i64
}

struct BypassListManagement {
	enable ?bool
}

struct BypassBounceManagement {
	enable ?bool
}

struct BypassUnsubscribeManagement {
	enable ?bool
}

struct Footer {
	enable ?bool
	text   ?string
	html   ?string
}

struct SandboxMode {
	enable ?bool
}

struct MailSettings {
	bypass_list_management        ?BypassListManagement
	bypass_bounce_management      ?BypassBounceManagement
	bypass_unsubscribe_management ?BypassUnsubscribeManagement
	footer                        ?Footer
	sandbox_mode                  ?SandboxMode
}

struct ClickTrackingSettings {
	enable      ?bool
	enable_text ?bool
}

struct OpenTrackingSettings {
	enable           ?bool
	substitution_tag ?string
}

struct SubscriptionTrackingSettings {
	enable           ?bool
	text             ?string
	html             ?string
	substitution_tag ?string
}

struct GoogleAnalyticsSettings {
	enable       ?bool
	utm_source   ?string
	utm_medium   ?string
	utm_term     ?string
	utm_content  ?string
	utm_campaign ?string
}

struct TrackingSettings {
	click_tracking        ?ClickTrackingSettings
	open_tracking         ?OpenTrackingSettings
	subscription_tracking ?SubscriptionTrackingSettings
	ganalytics            ?GoogleAnalyticsSettings
}

pub struct Email {
pub mut:
	personalizations  []Personalizations @[required]
	from              Recipient          @[required]
	subject           string             @[required]
	content           []Content          @[required]
	reply_to          ?Recipient
	reply_to_list     ?[]Recipient
	attachments       ?[]Attachment
	template_id       ?string
	headers           ?map[string]string
	categories        ?[]string
	custom_args       ?string
	send_at           ?i64
	batch_id          ?string
	asm_              ?UnsubscribeGroups @[json: 'asm']
	ip_pool_name      ?string
	mail_settings     ?MailSettings
	tracking_settings ?TrackingSettings
}

pub fn (mut e Email) add_personalization(personalizations []Personalizations) {
	e.personalizations << personalizations
}

pub fn (mut e Email) add_content(content []Content) {
	e.content << content
}

pub fn (mut e Email) add_headers(headers map[string]string) {
	e.headers or {
		e.headers = headers.clone()
		return
	}

	for k, v in headers {
		e.headers[k] = v
	}
}

pub fn new_email(to []string, from string, subject string, content string) Email {
	mut recipients := []Recipient{}

	for email in to {
		recipients << Recipient{
			email: email
		}
	}

	personalization := Personalizations{
		to: recipients
	}

	return Email{
		personalizations: [personalization]
		from:             Recipient{
			email: from
		}
		subject:          subject
		content:          [Content{
			value: content
		}]
	}
}
