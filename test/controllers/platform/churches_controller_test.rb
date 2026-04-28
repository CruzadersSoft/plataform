require "test_helper"

class Platform::ChurchesControllerTest < ActionDispatch::IntegrationTest
  test "platform admin lists churches" do
    sign_in_as users(:platform_admin)

    get platform_churches_path

    assert_response :success
    assert_select "h1", "Igrejas"
    assert_select "[data-testid='church-row']", count: Church.count
    assert_select "a[href='#{platform_church_path(churches(:grace))}']", text: churches(:grace).name
  end

  test "platform admin sees church details" do
    sign_in_as users(:platform_admin)

    get platform_church_path(churches(:grace))

    assert_response :success
    assert_select "h1", churches(:grace).name
    assert_select "[data-testid='church-slug']", churches(:grace).slug
  end

  test "platform admin creates a church" do
    sign_in_as users(:platform_admin)

    assert_difference "Church.count", 1 do
      post platform_churches_path, params: {
        church: {
          name: "City Church",
          slug: "city-church",
          legal_name: "City Church Brasil",
          email: "hello@city.example",
          phone: "+55 11 99999-0000",
          timezone: "America/Sao_Paulo",
          status: "active"
        }
      }
    end

    church = Church.order(:created_at).last
    assert_redirected_to platform_church_path(church)
    assert_equal "city-church", church.slug
    assert_equal "City Church Brasil", church.legal_name
  end

  test "platform admin sees validation errors when creating an invalid church" do
    sign_in_as users(:platform_admin)

    assert_no_difference "Church.count" do
      post platform_churches_path, params: { church: { name: "", slug: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".alert", /Nao foi possivel criar/
  end

  test "platform admin updates a church" do
    sign_in_as users(:platform_admin)

    patch platform_church_path(churches(:grace)), params: {
      church: {
        name: "Grace Updated",
        slug: "grace-updated",
        timezone: "America/Sao_Paulo",
        status: "suspended"
      }
    }

    assert_redirected_to platform_church_path(churches(:grace))
    churches(:grace).reload
    assert_equal "Grace Updated", churches(:grace).name
    assert_equal "grace-updated", churches(:grace).slug
    assert churches(:grace).suspended?
  end

  test "regular user cannot manage platform churches" do
    sign_in_as users(:two)

    get platform_churches_path

    assert_redirected_to root_path
  end
end
