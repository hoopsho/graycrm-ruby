# GrayCRM Ruby Client

Official Ruby client for the [GrayCRM](https://graycrm.io) API. Zero runtime dependencies.

## Installation

```ruby
gem "graycrm"
```

Or install directly:

```
gem install graycrm
```

## Configuration

```ruby
GrayCRM.configure do |c|
  c.host = "acme.graycrm.io"     # Your tenant subdomain
  c.api_key = "gcrm_live_..."    # API key from admin panel
  c.timeout = 30                  # Read timeout (seconds)
  c.open_timeout = 10             # Connection timeout
  c.per_page = 25                 # Default pagination size
  c.logger = Logger.new(STDOUT)   # Optional request logging
end
```

### Multi-Tenant (Rails)

Thread-safe per-request configuration:

```ruby
# config/initializers/graycrm.rb
GrayCRM.configure do |c|
  c.timeout = 30
end

# In a controller or service
GrayCRM.with_config(api_key: current_tenant.api_key, host: "#{current_tenant.slug}.graycrm.io") do
  contacts = GrayCRM::Contact.all.to_a
end
```

## Quick Start

```ruby
# List contacts
contacts = GrayCRM::Contact.where(first_name_cont: "Jane").page(1).per(25).to_a

# Create a contact
contact = GrayCRM::Contact.create(first_name: "Jane", last_name: "Doe")

# Get a contact
contact = GrayCRM::Contact.find("uuid")

# Update
contact.update(company: "Acme Inc")

# Delete
contact.destroy
```

## Resources

### Contacts

```ruby
GrayCRM::Contact.all
GrayCRM::Contact.where(first_name_cont: "Jane")
GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" })
GrayCRM::Contact.where(tag: "vip,hot-lead")
GrayCRM::Contact.find("uuid")
GrayCRM::Contact.create(first_name: "Jane", last_name: "Doe")
```

**Nested resources:**

```ruby
contact = GrayCRM::Contact.find("uuid")
contact.emails.to_a
contact.phones.to_a
contact.flags.to_a
contact.notes.to_a
contact.activities.to_a
contact.custom_attributes.to_a
contact.properties.to_a
contact.audit_events.to_a

# Create nested
contact.emails.create(email: "new@example.com", label: "work")
contact.flags.create(key: "enrichment", value: "pending")
```

### Properties

```ruby
GrayCRM::Property.all
GrayCRM::Property.find("uuid")
GrayCRM::Property.create(name: "123 Main St", city: "Springfield")
```

### Tags

```ruby
GrayCRM::Tag.all
GrayCRM::Tag.create(name: "vip")
```

### Duplicate Detection & Merge

```ruby
groups = GrayCRM::Contact.duplicates
groups.each do |group|
  puts "#{group[:match_type]}: #{group[:match_detail]}"
  group[:contacts].each { |c| puts "  #{c.first_name} #{c.last_name}" }
end

# Merge contacts
winner = GrayCRM::Contact.find("winner-uuid")
winner.merge(loser_id: "loser-uuid")
```

### Webhooks

```ruby
GrayCRM::Webhook.all.to_a
webhook = GrayCRM::Webhook.create(
  url: "https://example.com/webhook",
  events: ["contact.created", "contact.updated"]
)
puts webhook.secret  # Only available on create

webhook.test!
webhook.update(active: false)
webhook.destroy
```

### Exports

```ruby
export = GrayCRM::Export.create(resource_type: "Contact")
export.reload  # Poll for status
puts export.download_url if export.completed?
```

### Batch Operations

```ruby
results = GrayCRM::Batch.execute([
  { method: "POST", resource: "contacts", body: { first_name: "John" } },
  { method: "PATCH", resource: "contacts", id: "uuid", body: { company: "Acme" } },
  { method: "DELETE", resource: "properties", id: "uuid" }
])
results.each { |r| puts "#{r.index}: #{r.status}" }
```

### Search

```ruby
results = GrayCRM::Search.query("John Doe", per_resource: 5)
results.contacts      # => Array<Contact>
results.properties    # => Array<Property>
results.total_count   # => Integer
```

### Stats

```ruby
stats = GrayCRM::Stats.fetch
stats.contacts_count
stats.properties_count
stats.activity_by_date
stats.top_tags
```

## AI Agent Patterns

### Flag-Based Enrichment

```ruby
# Set enrichment flag
contact = GrayCRM::Contact.find("uuid")
contact.flags.create(key: "enrichment", value: "pending")

# Query pending enrichment
pending = GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" }).to_a

# Claim and process
pending.each do |c|
  flag = c.flags.to_a.find { |f| f.key == "enrichment" }
  flag.claim!  # 409 ConflictError if already claimed
  # ... enrich contact ...
  flag.update(value: "completed")
rescue GrayCRM::ConflictError
  next  # Another agent got it
end
```

### Webhook-Driven Processing

```ruby
# Set up webhook for real-time reactions
webhook = GrayCRM::Webhook.create(
  url: "https://my-agent.example.com/hooks/graycrm",
  events: ["flag.created", "contact.created"]
)
```

## Pagination

### Offset (default)

```ruby
contacts = GrayCRM::Contact.page(2).per(50)
contacts.collection.total        # => 1234
contacts.collection.total_pages  # => 25
```

### Cursor (for large datasets)

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

# Block iteration
GrayCRM::Contact.page(1).per(50).collection.each_page do |page|
  page.each { |contact| process(contact) }
end

# Works with both cursor and offset pagination
```

## Error Handling

```ruby
begin
  GrayCRM::Contact.create(first_name: "")
rescue GrayCRM::ValidationError => e
  puts e.validation_errors  # => { "first_name" => ["can't be blank"] }
rescue GrayCRM::AuthenticationError
  puts "Invalid API key"
rescue GrayCRM::ForbiddenError
  puts "Insufficient scope or suspended account"
rescue GrayCRM::NotFoundError
  puts "Resource not found"
rescue GrayCRM::ConflictError
  puts "Flag already claimed"
rescue GrayCRM::RateLimitError => e
  puts "Rate limited, retry after #{e.retry_after} seconds"
rescue GrayCRM::ServerError
  puts "Server error, try again"
end
```

## Development

```
bundle install
bundle exec rake test
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
