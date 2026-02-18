# GrayCRM Ruby Client

Official Ruby client for the [GrayCRM](https://graycrm.io) API. Provides ActiveRecord-like syntax for contacts, properties, tags, flags, and more. Zero runtime dependencies — uses only Ruby stdlib.

## Installation

Add to your Gemfile:

```ruby
# From GitHub (recommended until gem is published to RubyGems)
gem "graycrm", github: "hoopsho/graycrm-ruby"

# Pin to a specific version
gem "graycrm", github: "hoopsho/graycrm-ruby", tag: "v0.1.0"

# From RubyGems (when published)
# gem "graycrm"
```

Then run `bundle install`.

## Configuration

```ruby
GrayCRM.configure do |c|
  c.host = "acme.graycrm.io"     # Your tenant subdomain
  c.api_key = "gcrm_live_..."    # API key from Settings > API Keys
  c.timeout = 30                  # Read timeout in seconds (default: 30)
  c.open_timeout = 10             # Connection timeout in seconds (default: 10)
  c.per_page = 25                 # Default pagination size (default: 25)
  c.max_retries = 3               # Auto-retry on 429 rate limit (default: 0)
  c.logger = Logger.new(STDOUT)   # Optional request/response logging
end
```

### Rails Initializer

```ruby
# config/initializers/graycrm.rb
GrayCRM.configure do |c|
  c.host = Rails.application.credentials.dig(:graycrm, :host)
  c.api_key = Rails.application.credentials.dig(:graycrm, :api_key)
  c.max_retries = 2
end
```

### Multi-Tenant (Thread-Safe)

Use `with_config` for per-request configuration in multi-tenant apps. Each block gets its own isolated config on the current thread:

```ruby
GrayCRM.with_config(api_key: current_tenant.api_key, host: "#{current_tenant.slug}.graycrm.io") do
  contacts = GrayCRM::Contact.all.to_a  # Uses tenant-specific credentials
end
```

### Reset

```ruby
GrayCRM.reset!  # Clears global config, thread-local config, and HTTP connection cache
```

## Quick Start

```ruby
# Create
contact = GrayCRM::Contact.create(first_name: "Jane", last_name: "Doe", email: "jane@example.com")

# Read
contact = GrayCRM::Contact.find("uuid")
contact.first_name  #=> "Jane"
contact.email       #=> "jane@example.com"

# Update
contact.update(company: "Acme Inc")

# Delete
contact.destroy

# List with filters
contacts = GrayCRM::Contact.where(first_name_cont: "Jane").page(1).per(25).to_a

# Find by exact match
contact = GrayCRM::Contact.find_by(email_eq: "jane@example.com")
```

## Resources

All resources support ActiveRecord-like CRUD operations. Every resource has `id`, `created_at`, and `updated_at` attributes.

### Contacts

**Attributes:** `id`, `first_name`, `last_name`, `email`, `phone`, `company`, `source`, `source_detail`, `created_at`, `updated_at`

```ruby
# Query with Ransack-style filters
GrayCRM::Contact.all
GrayCRM::Contact.where(first_name_cont: "Jane")
GrayCRM::Contact.where(company_eq: "Acme Inc")
GrayCRM::Contact.find("uuid")
GrayCRM::Contact.find_by(email_eq: "jane@example.com")

# Filter by tags (comma-separated)
GrayCRM::Contact.where(tag: "vip,hot-lead")

# Filter by flags
GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" })

# Filter by custom attributes
GrayCRM::Contact.where(attr: { key: "industry", value: "tech" })

# Create
contact = GrayCRM::Contact.create(first_name: "Jane", last_name: "Doe")
contact.id  #=> "550e8400-..."

# Build and save
contact = GrayCRM::Contact.new("first_name" => "Jane", "last_name" => "Doe")
contact.new_record?  #=> true
contact.save         #=> contact (or false on validation error)
contact.persisted?   #=> true

# Update
contact.first_name = "Janet"
contact.changed?  #=> true
contact.save

# Or update in one call
contact.update(company: "Acme Inc", phone: "555-1234")

# Delete
contact.destroy
```

**Nested resources:**

```ruby
contact = GrayCRM::Contact.find("uuid")

# Emails
contact.emails.to_a
contact.emails.create(email: "work@example.com", label: "work", primary: false)

# Phones
contact.phones.to_a
contact.phones.create(phone: "555-1234", label: "mobile", primary: true)

# Link to a property
contact.properties.to_a
contact.properties.create(property_id: "property-uuid", role: "owner")

# Tags, flags, notes, activities, custom attributes, audit events
contact.tags.to_a
contact.flags.to_a
contact.flags.create(key: "enrichment", value: "pending")
contact.notes.to_a
contact.notes.create(body: "Called and left voicemail")
contact.activities.to_a
contact.custom_attributes.to_a
contact.custom_attributes.create(key: "industry", value: "tech")
contact.audit_events.to_a
```

### Properties

**Attributes:** `id`, `name`, `street`, `city`, `state`, `zip`, `country`, `latitude`, `longitude`, `source`, `source_detail`, `created_at`, `updated_at`

```ruby
GrayCRM::Property.all
GrayCRM::Property.find("uuid")
GrayCRM::Property.where(city_eq: "Springfield")
GrayCRM::Property.create(name: "123 Main St", city: "Springfield", state: "IL", zip: "62701")

property = GrayCRM::Property.find("uuid")
property.update(name: "123 Main Street")
property.destroy
```

**Nested resources:**

```ruby
property = GrayCRM::Property.find("uuid")
property.contacts.to_a       # ContactProperty join records
property.tags.to_a
property.flags.to_a
property.notes.to_a
property.notes.create(body: "Roof needs inspection")
property.custom_attributes.to_a
property.audit_events.to_a
```

### Tags

**Attributes:** `id`, `name`, `created_at`, `updated_at`

```ruby
GrayCRM::Tag.all
GrayCRM::Tag.find("uuid")
GrayCRM::Tag.create(name: "vip")
tag = GrayCRM::Tag.find("uuid")
tag.update(name: "priority")
tag.destroy
```

### Flags

**Attributes:** `id`, `key`, `value`, `claimed_at`, `claimed_by_id`, `flaggable_type`, `flaggable_id`, `created_at`, `updated_at`

```ruby
GrayCRM::Flag.all
GrayCRM::Flag.find("uuid")
flag = GrayCRM::Flag.find("uuid")
flag.update(value: "completed")
flag.destroy

# Claim a flag (AI agent coordination — returns 409 ConflictError if already claimed)
flag.claim!
```

### Notes

**Attributes:** `id`, `body`, `notable_type`, `notable_id`, `author_id`, `created_at`, `updated_at`

```ruby
GrayCRM::Note.all
GrayCRM::Note.find("uuid")
GrayCRM::Note.create(body: "Follow-up call scheduled", notable_type: "Contact", notable_id: "contact-uuid")
note = GrayCRM::Note.find("uuid")
note.update(body: "Updated note content")
note.destroy
```

### Activities

**Attributes:** `id`, `activity_type`, `subject`, `body`, `occurred_at`, `activitable_type`, `activitable_id`, `created_at`, `updated_at`

```ruby
GrayCRM::Activity.all
GrayCRM::Activity.find("uuid")
GrayCRM::Activity.create(
  activity_type: "call",
  subject: "Discovery call",
  body: "Discussed pricing",
  occurred_at: Time.now.iso8601,
  activitable_type: "Contact",
  activitable_id: "contact-uuid"
)
```

### Custom Attributes

**Attributes:** `id`, `key`, `value`, `attributable_type`, `attributable_id`, `created_at`, `updated_at`

```ruby
GrayCRM::CustomAttribute.all
GrayCRM::CustomAttribute.find("uuid")
attr = GrayCRM::CustomAttribute.find("uuid")
attr.update(value: "updated-value")
attr.destroy
```

### Contact Emails

**Attributes:** `id`, `email`, `label`, `primary`, `contact_id`, `created_at`, `updated_at`

```ruby
# Typically accessed as nested resources on Contact
contact.emails.to_a
contact.emails.create(email: "alt@example.com", label: "personal", primary: false)

email = contact.emails.to_a.first
email.update(primary: true)
email.destroy
```

### Contact Phones

**Attributes:** `id`, `phone`, `label`, `primary`, `contact_id`, `created_at`, `updated_at`

```ruby
contact.phones.to_a
contact.phones.create(phone: "555-9876", label: "office", primary: false)
```

### Contact Properties (Join)

**Attributes:** `id`, `contact_id`, `property_id`, `role`, `created_at`, `updated_at`

Links contacts to properties with a role (e.g., "owner", "tenant", "agent"):

```ruby
# From a contact
contact.properties.to_a
contact.properties.create(property_id: "property-uuid", role: "owner")

# From a property
property.contacts.to_a
property.contacts.create(contact_id: "contact-uuid", role: "tenant")

# Update or remove
cp = contact.properties.to_a.first
cp.update(role: "former-owner")
cp.destroy
```

### Audit Events (Read-Only)

**Attributes:** `id`, `action`, `auditable_type`, `auditable_id`, `changes`, `performed_by_type`, `performed_by_id`, `created_at`

```ruby
GrayCRM::AuditEvent.all
GrayCRM::AuditEvent.where(auditable_type_eq: "Contact")
GrayCRM::AuditEvent.find("uuid")

# Or via nested resource
contact.audit_events.to_a
```

### Duplicate Detection & Merge

```ruby
# Find duplicate contact groups
groups = GrayCRM::Contact.duplicates
groups.each do |group|
  puts "#{group[:match_type]}: #{group[:match_detail]}"
  group[:contacts].each { |c| puts "  #{c.first_name} #{c.last_name} (#{c.id})" }
end

# Merge contacts (loser is merged into winner)
winner = GrayCRM::Contact.find("winner-uuid")
winner.merge(loser_id: "loser-uuid")
# winner is automatically reloaded with merged data
```

### Webhooks

**Attributes:** `id`, `url`, `events`, `active`, `secret`, `consecutive_failures`, `created_at`, `updated_at`

```ruby
GrayCRM::Webhook.all.to_a
webhook = GrayCRM::Webhook.create(
  url: "https://example.com/webhook",
  events: ["contact.created", "contact.updated"]
)
puts webhook.secret  # Only returned on create — save it!

webhook.test!  # Sends a test payload to the URL
webhook.update(active: false)
webhook.destroy
```

### Exports

**Attributes:** `id`, `resource_type`, `status`, `total_rows`, `query_params`, `download_url`, `created_at`, `updated_at`

```ruby
export = GrayCRM::Export.create(resource_type: "Contact")

# Check status
export.pending?      #=> true
export.processing?   #=> false
export.completed?    #=> false
export.failed?       #=> false

# Poll manually
export.reload
puts export.download_url if export.completed?

# Or wait automatically (polls every 2s, times out after 120s)
export.wait_until_complete!(timeout: 120, interval: 2)
puts export.download_url if export.completed?
```

### Batch Operations

Execute multiple API operations in a single request:

```ruby
results = GrayCRM::Batch.execute([
  { method: "POST", resource: "contacts", body: { first_name: "John" } },
  { method: "PATCH", resource: "contacts", id: "uuid", body: { company: "Acme" } },
  { method: "DELETE", resource: "properties", id: "uuid" }
])

results.each do |r|
  puts "#{r.index}: #{r.status}"  # r.data contains the resource, r.error on failure
end
```

### Search

Search across contacts, properties, and tags simultaneously:

```ruby
results = GrayCRM::Search.query("John Doe", per_resource: 5)
results.contacts      #=> Array<Contact>
results.properties    #=> Array<Property>
results.tags          #=> Array<Tag>
results.total_count   #=> Integer
```

### Stats

```ruby
stats = GrayCRM::Stats.fetch
stats.contacts_count    #=> Integer
stats.properties_count  #=> Integer
stats.tags_count        #=> Integer
stats.flags_count       #=> Integer
stats.activity_by_date  #=> Array
stats.top_tags          #=> Array
```

## CRUD Pattern Reference

All resources that support writes follow the same ActiveRecord-like pattern:

```ruby
# Create (returns nil on validation error)
record = GrayCRM::Contact.create(first_name: "Jane")

# Create! (raises GrayCRM::ValidationError on failure)
record = GrayCRM::Contact.create!(first_name: "Jane")

# Build + save
record = GrayCRM::Contact.new("first_name" => "Jane")
record.new_record?  #=> true
record.save         #=> record (or false on validation error)
record.save!        #=> record (or raises GrayCRM::ValidationError)

# Update
record.update(company: "Acme")    #=> record or false
record.update!(company: "Acme")   #=> record or raises

# Direct attribute assignment + save
record.company = "Acme"
record.changed?  #=> true
record.save

# Reload from server
record.reload

# Delete
record.destroy  #=> true

# Equality
a = GrayCRM::Contact.find("uuid")
b = GrayCRM::Contact.find("uuid")
a == b  #=> true (compares class + id)

# Serialization
record.to_h     #=> { "id" => "...", "first_name" => "Jane", ... }
record.to_json  #=> JSON string
record.to_param #=> "uuid" (for Rails URL helpers)
record.inspect  #=> "#<GrayCRM::Contact id: \"uuid\", first_name: \"Jane\", ...>"
```

## Pagination

### Offset Pagination (default)

```ruby
contacts = GrayCRM::Contact.page(2).per(50)
contacts.collection.total        #=> 1234
contacts.collection.total_pages  #=> 25
contacts.collection.current_page #=> 2
```

### Cursor Pagination (for large datasets)

More efficient for iterating through large collections:

```ruby
collection = GrayCRM::Contact.cursor(nil).per(100).collection
while collection.has_more?
  collection.each { |c| process(c) }
  collection = GrayCRM::Contact.cursor(collection.next_cursor).per(100).collection
end
```

### Auto-Pagination

Use `next_page` to fetch the next page, or `each_page` to iterate all pages automatically:

```ruby
# Manual page-by-page
page = GrayCRM::Contact.cursor(nil).per(100).collection
while page
  page.each { |c| process(c) }
  page = page.next_page
end

# Block iteration (works with both offset and cursor pagination)
GrayCRM::Contact.page(1).per(50).collection.each_page do |page|
  page.each { |contact| process(contact) }
end
```

## Filtering

Filters use [Ransack](https://github.com/activerecord-hackery/ransack) predicates. Common predicates:

| Predicate | Meaning | Example |
|-----------|---------|---------|
| `_eq` | Equals | `first_name_eq: "Jane"` |
| `_cont` | Contains | `first_name_cont: "Jan"` |
| `_start` | Starts with | `email_start: "jane"` |
| `_end` | Ends with | `email_end: "@acme.com"` |
| `_gt` / `_lt` | Greater/less than | `created_at_gt: "2025-01-01"` |
| `_gteq` / `_lteq` | Greater/less than or equal | `updated_at_gteq: "2025-06-01"` |
| `_null` | Is null | `company_null: true` |
| `_not_null` | Is not null | `email_not_null: true` |

**Special filters:**

```ruby
# Tags (comma-separated, matches any)
GrayCRM::Contact.where(tag: "vip,hot-lead")

# Flags (key + value)
GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" })

# Custom attributes (key + value)
GrayCRM::Contact.where(attr: { key: "industry", value: "tech" })

# App tags (for API key isolation)
GrayCRM::Contact.where(app_tag: "my-integration")

# Chainable
GrayCRM::Contact
  .where(company_cont: "Acme")
  .where(tag: "vip")
  .page(1)
  .per(25)
  .to_a
```

## Error Handling

```ruby
begin
  GrayCRM::Contact.create!(first_name: "")
rescue GrayCRM::ValidationError => e
  e.message           #=> "Validation failed"
  e.validation_errors #=> { "first_name" => ["can't be blank"] }
  e.status            #=> 422
rescue GrayCRM::AuthenticationError   # 401 — invalid or missing API key
  # ...
rescue GrayCRM::ForbiddenError        # 403 — insufficient scope or suspended account
  # ...
rescue GrayCRM::NotFoundError         # 404 — resource not found
  # ...
rescue GrayCRM::ConflictError         # 409 — flag already claimed
  # ...
rescue GrayCRM::RateLimitError => e   # 429 — rate limited
  e.retry_after  #=> seconds to wait (Integer)
rescue GrayCRM::ServerError           # 500+ — server error
  # ...
end
```

### Soft Errors on Save

`save` and `create` return `false` (or `nil`) instead of raising. Check `errors` for details:

```ruby
contact = GrayCRM::Contact.new("first_name" => "")
if contact.save == false
  puts contact.errors  #=> { "first_name" => ["can't be blank"] }
end
```

### Auto-Retry on Rate Limit

Set `max_retries` to automatically retry when rate limited (429). The client respects the `Retry-After` header:

```ruby
GrayCRM.configure do |c|
  c.max_retries = 3  # Retry up to 3 times with backoff
end
```

## AI Agent Patterns

### Flag-Based Enrichment

Use flags to coordinate work across multiple AI agents. The `claim!` method provides atomic locking — only one agent can claim a flag:

```ruby
# Set enrichment flag
contact = GrayCRM::Contact.find("uuid")
contact.flags.create(key: "enrichment", value: "pending")

# Query pending enrichment
pending = GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" }).to_a

# Claim and process
pending.each do |c|
  flag = c.flags.to_a.find { |f| f.key == "enrichment" }
  flag.claim!  # 409 ConflictError if already claimed by another agent
  # ... enrich contact ...
  flag.update(value: "completed")
rescue GrayCRM::ConflictError
  next  # Another agent claimed it first
end
```

### Webhook-Driven Processing

```ruby
webhook = GrayCRM::Webhook.create(
  url: "https://my-agent.example.com/hooks/graycrm",
  events: ["flag.created", "contact.created"]
)
```

## API Scopes

API keys are scoped to specific permissions. The available scopes are:

| Scope | Resources |
|-------|-----------|
| `contacts:read` | List, show, search, duplicates for contacts |
| `contacts:write` | Create, update, delete, merge contacts |
| `properties:read` | List, show properties |
| `properties:write` | Create, update, delete properties |
| `tags:read` | List, show tags |
| `tags:write` | Create, update, delete tags |
| `notes:read` | List, show notes |
| `notes:write` | Create, update, delete notes |
| `activities:read` | List, show activities |
| `activities:write` | Create, update, delete activities |
| `flags:read` | List, show flags |
| `flags:write` | Create, update, delete, claim flags |
| `custom_attributes:read` | List, show custom attributes |
| `custom_attributes:write` | Create, update, delete custom attributes |
| `audit_events:read` | List, show audit events |
| `batch:write` | Execute batch operations |
| `search:read` | Global search |
| `webhooks:read` | List, show webhooks |
| `webhooks:write` | Create, update, delete, test webhooks |
| `exports:read` | List, show exports |
| `exports:write` | Create exports |
| `duplicates:read` | Duplicate detection |
| `stats:read` | Dashboard stats |

A `ForbiddenError` (403) is raised when the API key lacks the required scope.

## Development

```
bundle install
bundle exec rake test
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
