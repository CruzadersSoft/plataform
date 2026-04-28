require "test_helper"

class Church::DepartmentsControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists departments for the active church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get departments_path

    assert_response :success
    assert_select "h1", "Departamentos"
    assert_select "[data-testid='department-row']", count: 2
    assert_select "a[href='#{department_path(departments(:welcome))}']", text: departments(:welcome).name
    assert_select "td", text: departments(:hope_care).name, count: 0
  end

  test "church admin creates department in current church" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "Department.count", 1 do
      post departments_path, params: {
        department: {
          name: "Kids",
          description: "Children ministry",
          color: "#9a6700",
          active: "1"
        }
      }
    end

    department = Department.order(:created_at).last
    assert_redirected_to department_path(department)
    assert_equal churches(:grace), department.church
  end

  test "church admin updates department" do
    sign_in_to_church_as users(:one), churches(:grace)

    patch department_path(departments(:welcome)), params: {
      department: {
        name: "Hospitality",
        description: "Guest care",
        color: "#1f6feb",
        active: "0"
      }
    }

    assert_redirected_to department_path(departments(:welcome))
    departments(:welcome).reload
    assert_equal "Hospitality", departments(:welcome).name
    assert_not departments(:welcome).active?
  end

  test "department leader updates only department they lead" do
    sign_in_to_church_as users(:one), churches(:grace)
    church_memberships(:grace_admin).department_leader!

    patch department_path(departments(:welcome)), params: { department: { name: "Welcome Team" } }
    assert_redirected_to department_path(departments(:welcome))

    patch department_path(departments(:worship)), params: { department: { name: "Blocked" } }
    assert_redirected_to root_path
  end

  test "does not show department from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get department_path(departments(:hope_care))

    assert_response :not_found
  end
end
