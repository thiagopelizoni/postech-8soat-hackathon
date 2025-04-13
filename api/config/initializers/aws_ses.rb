require 'aws-sdk-rails'

ActionMailer::Base.add_delivery_method :aws_sdk, Aws::Rails::Mailer,
  credentials: Aws::Credentials.new(
    ENV.fetch('AWS_ACCESS_KEY_ID'),
    ENV.fetch('AWS_SECRET_ACCESS_KEY')
  ),
  region: ENV.fetch('AWS_REGION')