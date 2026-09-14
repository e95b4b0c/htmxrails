# frozen_string_literal: true

# A form object for the contact demo: validations without a database table, so
# the whole HTMX round trip stays visible in the logs.
class ContactMessage
  include ActiveModel::API

  attr_accessor :name, :email, :body

  validates :name, presence: true, length: { maximum: 60 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :body, presence: true, length: { minimum: 10, maximum: 500 }

  # form_with asks the record whether it is persisted to pick the HTTP verb.
  def persisted? = false
end
