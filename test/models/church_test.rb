require "test_helper"

class ChurchTest < ActiveSupport::TestCase
  test "requires a unique slug" do
    church = Church.new(name: "Second Church", slug: churches(:grace).slug)

    assert_not church.valid?
    assert_includes church.errors[:slug], "has already been taken"
  end

  test "normalizes slug before validation" do
    church = Church.new(name: "New Church", slug: " New Church ")

    assert church.valid?
    assert_equal "new-church", church.slug
  end

  test "active status is the default" do
    church = Church.new(name: "Default Church", slug: "default-church")

    assert church.active?
  end
end
