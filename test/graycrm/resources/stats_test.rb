# frozen_string_literal: true

require "test_helper"

class GrayCRM::StatsTest < Minitest::Test
  include FakeServer

  def test_fetch_stats
    stub_api(:get, "/stats", body: {
      data: {
        contacts_count: 100,
        properties_count: 50,
        tags_count: 10,
        flags_count: 5,
        activity_by_date: [{ date: "2026-02-10", count: 15 }],
        top_tags: [{ name: "vip", count: 42 }]
      }
    })

    stats = GrayCRM::Stats.fetch
    assert_equal 100, stats.contacts_count
    assert_equal 50, stats.properties_count
    assert_equal 10, stats.tags_count
    assert_equal 1, stats.activity_by_date.size
    assert_equal 1, stats.top_tags.size
  end
end
