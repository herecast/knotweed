# frozen_string_literal: true

def mailchimp_webhook_content
  ActiveSupport::HashWithIndifferentAccess.new(
    'type' => 'unsubscribe',
    'fired_at' => '2019-03-20 18:12:00',
    'data' => {
      'action' => 'unsub',
      'reason' => 'manual',
      'id' => '101d0536eb',
      'email' => 'sheehan1102@hotmail.com',
      'email_type' => 'html',
      'ip_opt' => '3.81.26.242',
      'ip_signup' => '72.15.30.58',
      'web_id' => '213129437',
      'merges' => {
        'EMAIL' => 'sheehan1102@hotmail.com',
        'FNAME' => '',
        'LNAME' => '',
        'ADDRESS' => '',
        'PHONE' => '',
        'INTERESTS' => '',
        'GROUPINGS' => {
          '0' => {
            'id' => '14141',
            'unique_id' => '0e0173410c',
            'name' => 'Your Interests',
            'groups' => ''
          }
        }
      },
      'list_id' => 'dummy-id'
    },
    'format' => 'json',
    'controller' => 'api/v3/mailchimp_webhooks',
    'action' => 'create'
  )
end
