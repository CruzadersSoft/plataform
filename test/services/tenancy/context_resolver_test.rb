require "test_helper"

class Tenancy::ContextResolverTest < ActiveSupport::TestCase
  test "resolves active church context for the current user" do
    result = Tenancy::ContextResolver.new(user: users(:one), church_id: churches(:grace).id).call

    assert result.success?
    assert_equal churches(:grace), result.church
    assert_equal church_memberships(:grace_admin), result.membership
  end

  test "rejects a church without active membership" do
    result = Tenancy::ContextResolver.new(user: users(:two), church_id: churches(:grace).id).call

    assert_not result.success?
    assert_nil result.church
    assert_nil result.membership
  end

  test "rejects an inactive membership" do
    church_memberships(:grace_admin).inactive!

    result = Tenancy::ContextResolver.new(user: users(:one), church_id: churches(:grace).id).call

    assert_not result.success?
    assert_nil result.church
    assert_nil result.membership
  end

  test "rejects an inactive church" do
    churches(:grace).inactive!

    result = Tenancy::ContextResolver.new(user: users(:one), church_id: churches(:grace).id).call

    assert_not result.success?
    assert_nil result.church
    assert_nil result.membership
  end
end
