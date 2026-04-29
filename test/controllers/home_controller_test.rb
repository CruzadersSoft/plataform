require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index when authentication" do
    get home_index_url
    assert_redirected_to new_session_path
  end

  test "authenticated user without current church is redirected to onboarding" do
    sign_in_as users(:two)

    get root_path

    assert_redirected_to onboarding_path
  end

  test "authenticated user with one active church is restored to church dashboard" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "h1", churches(:grace).name
    assert_select "[data-testid='current-church-slug']", churches(:grace).slug
  end

  test "platform admin without current church is redirected to platform dashboard" do
    sign_in_as users(:platform_admin)

    get root_path

    assert_redirected_to platform_root_path
  end

  test "shows active church dashboard when user has current church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get root_path

    assert_response :success
    assert_select "h1", "Grace Church"
    assert_select "[data-testid='current-church-slug']", "grace-church"
    assert_select "[data-testid='current-church-role']", "Church admin"
    assert_select "a[href='#{events_path}']", text: "Eventos", minimum: 1
    assert_select "a[href='#{assignments_path}']", text: "Minhas convocações", minimum: 1
    assert_select "a[href='#{unavailabilities_path}']", text: "Indisponibilidades", minimum: 1
  end

  test "shows active invitation code to church admin" do
    sign_in_to_church_as users(:one), churches(:grace)

    get root_path

    assert_response :success
    assert_select "[data-testid='church-invitation-code']", "GRACE-123"
  end

  test "does not show expired invitation code to church admin" do
    church_invitation_codes(:grace_volunteer).destroy!
    sign_in_to_church_as users(:one), churches(:grace)

    get root_path

    assert_response :success
    assert_select "[data-testid='church-invitation-code']", false
  end

  test "does not create invitation code while rendering dashboard" do
    church_invitation_codes(:grace_volunteer).destroy!
    church_invitation_codes(:expired).destroy!
    sign_in_to_church_as users(:one), churches(:grace)

    assert_no_difference -> { churches(:grace).church_invitation_codes.count } do
      get root_path
    end

    assert_response :success
    assert_select "[data-testid='church-invitation-code']", false
  end

  test "does not show invitation code to volunteer" do
    churches(:grace).church_memberships.create!(
      user: users(:two),
      church_role: :volunteer,
      status: :active
    )
    sign_in_to_church_as users(:two), churches(:grace)

    get root_path

    assert_redirected_to assignments_path
    follow_redirect!
    assert_response :success
    assert_select "[data-testid='church-invitation-code']", false
  end

  test "pure volunteer starts on assignments page" do
    sign_in_to_church_as users(:three), churches(:grace)

    get root_path

    assert_redirected_to assignments_path
  end

  test "volunteer who leads a department still sees church dashboard" do
    department_memberships(:worship_volunteer).leader!
    sign_in_to_church_as users(:three), churches(:grace)

    get root_path

    assert_response :success
    assert_select "h1", "Grace Church"
    assert_select "[data-testid='current-church-role']", "Lider: Worship"
  end
end
